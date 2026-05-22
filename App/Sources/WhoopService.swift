import Foundation
import Network
import Observation
import AppKit

// MARK: - Models

/// The latest WHOOP snapshot, stored locally.
struct WhoopVitals: Codable, Sendable, Equatable {
    var recoveryPercent: Int?
    var hrvMs: Double?
    var restingHeartRate: Int?
    var sleepPerformance: Int?
    var dayStrain: Double?
    var lastSync: Date?

    var isEmpty: Bool {
        recoveryPercent == nil && sleepPerformance == nil && dayStrain == nil
    }
}

enum WhoopConnectionState: Equatable, Sendable {
    case disconnected
    case connecting
    case connected
    case failed(String)
}

enum WhoopError: LocalizedError {
    case badURL
    case noCode(String)
    case http(String)

    var errorDescription: String? {
        switch self {
        case .badURL:           return "Could not build the WHOOP authorization URL."
        case .noCode(let why):  return "WHOOP did not return an authorization code: \(why)"
        case .http(let detail): return detail
        }
    }
}

private struct WhoopTokens: Codable {
    var accessToken: String
    var refreshToken: String
    var expiry: Date
}

private enum WhoopKey {
    static let clientID = "whoop.clientID"
    static let clientSecret = "whoop.clientSecret"
    static let tokens = "whoop.tokens"
}

// MARK: - Service

/// Owns the WHOOP connection: credentials, OAuth, token refresh, and sync.
@MainActor
@Observable
final class WhoopService {

    var state: WhoopConnectionState = .disconnected
    var vitals: WhoopVitals

    private let store: FileStore

    init(store: FileStore) {
        self.store = store
        self.vitals = store.load(WhoopVitals.self, "whoop_vitals") ?? WhoopVitals()
        if Keychain.get(WhoopKey.tokens) != nil {
            state = .connected
        }
    }

    var hasCredentials: Bool {
        !(Keychain.get(WhoopKey.clientID) ?? "").isEmpty
            && !(Keychain.get(WhoopKey.clientSecret) ?? "").isEmpty
    }

    var clientID: String { Keychain.get(WhoopKey.clientID) ?? "" }

    func saveCredentials(clientID: String, clientSecret: String) {
        Keychain.set(clientID, for: WhoopKey.clientID)
        Keychain.set(clientSecret, for: WhoopKey.clientSecret)
    }

    func connect() async {
        guard hasCredentials,
              let id = Keychain.get(WhoopKey.clientID),
              let secret = Keychain.get(WhoopKey.clientSecret) else {
            state = .failed("Enter your WHOOP Client ID and Secret first.")
            return
        }
        state = .connecting
        do {
            let tokens = try await WhoopAuth.authorize(clientID: id, clientSecret: secret)
            saveTokens(tokens)
            state = .connected
            await sync()
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    func disconnect() {
        Keychain.delete(WhoopKey.tokens)
        vitals = WhoopVitals()
        store.save(vitals, "whoop_vitals")
        state = .disconnected
    }

    func sync() async {
        guard case .connected = state else { return }
        do {
            let token = try await validAccessToken()
            var fresh = try await WhoopClient.fetchVitals(accessToken: token)
            fresh.lastSync = Date()
            vitals = fresh
            store.save(vitals, "whoop_vitals")
        } catch {
            state = .failed(error.localizedDescription)
        }
    }

    // MARK: Tokens

    private func validAccessToken() async throws -> String {
        guard let tokens = loadTokens() else {
            throw WhoopError.http("Not connected to WHOOP.")
        }
        if tokens.expiry > Date().addingTimeInterval(60) {
            return tokens.accessToken
        }
        guard let id = Keychain.get(WhoopKey.clientID),
              let secret = Keychain.get(WhoopKey.clientSecret) else {
            throw WhoopError.http("Missing WHOOP credentials.")
        }
        let refreshed = try await WhoopAuth.refresh(refreshToken: tokens.refreshToken,
                                                    clientID: id, clientSecret: secret)
        saveTokens(refreshed)
        return refreshed.accessToken
    }

    private func saveTokens(_ tokens: WhoopTokens) {
        if let data = try? JSONEncoder().encode(tokens),
           let string = String(data: data, encoding: .utf8) {
            Keychain.set(string, for: WhoopKey.tokens)
        }
    }

    private func loadTokens() -> WhoopTokens? {
        guard let string = Keychain.get(WhoopKey.tokens),
              let data = string.data(using: .utf8) else { return nil }
        return try? JSONDecoder().decode(WhoopTokens.self, from: data)
    }
}

// MARK: - OAuth

private enum WhoopAuth {
    static let authEndpoint = "https://api.prod.whoop.com/oauth/oauth2/auth"
    static let tokenEndpoint = "https://api.prod.whoop.com/oauth/oauth2/token"
    static let redirectURI = "http://localhost:8970/whoop/callback"
    static let scopes = "offline read:recovery read:sleep read:workout read:cycles read:profile"
    static let callbackPort: UInt16 = 8970

    static func authorize(clientID: String, clientSecret: String) async throws -> WhoopTokens {
        guard var components = URLComponents(string: authEndpoint) else { throw WhoopError.badURL }
        components.queryItems = [
            URLQueryItem(name: "response_type", value: "code"),
            URLQueryItem(name: "client_id", value: clientID),
            URLQueryItem(name: "redirect_uri", value: redirectURI),
            URLQueryItem(name: "scope", value: scopes),
            URLQueryItem(name: "state", value: UUID().uuidString)
        ]
        guard let authURL = components.url else { throw WhoopError.badURL }

        let catcher = LoopbackCatcher(port: callbackPort)
        let pending = Task { try await catcher.waitForCallback() }
        // NSWorkspace must be touched on the main thread or it silently no-ops.
        await MainActor.run { _ = NSWorkspace.shared.open(authURL) }
        let params = try await pending.value

        guard let code = params["code"] else {
            throw WhoopError.noCode(params["error"] ?? "authorization was not completed")
        }
        return try await exchangeCode(code, clientID: clientID, clientSecret: clientSecret)
    }

    static func refresh(refreshToken: String,
                        clientID: String,
                        clientSecret: String) async throws -> WhoopTokens {
        try await postToken([
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": clientID,
            "client_secret": clientSecret,
            "scope": "offline"
        ])
    }

    private static func exchangeCode(_ code: String,
                                     clientID: String,
                                     clientSecret: String) async throws -> WhoopTokens {
        try await postToken([
            "grant_type": "authorization_code",
            "code": code,
            "client_id": clientID,
            "client_secret": clientSecret,
            "redirect_uri": redirectURI
        ])
    }

    private static func postToken(_ form: [String: String]) async throws -> WhoopTokens {
        guard let url = URL(string: tokenEndpoint) else { throw WhoopError.badURL }
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")
        request.httpBody = form
            .map { "\(formEncode($0.key))=\(formEncode($0.value))" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? "unknown error"
            throw WhoopError.http("WHOOP token request failed: \(body)")
        }
        let decoded = try JSONDecoder().decode(TokenResponse.self, from: data)
        return WhoopTokens(
            accessToken: decoded.access_token,
            refreshToken: decoded.refresh_token ?? "",
            expiry: Date().addingTimeInterval(TimeInterval(decoded.expires_in))
        )
    }

    private static func formEncode(_ value: String) -> String {
        value.addingPercentEncoding(withAllowedCharacters: .alphanumerics) ?? value
    }

    private struct TokenResponse: Decodable {
        let access_token: String
        let refresh_token: String?
        let expires_in: Int
    }
}

// MARK: - Loopback callback catcher

/// A one-shot local HTTP listener that catches the OAuth redirect on
/// `http://localhost:<port>/whoop/callback` and returns its query parameters.
private final class LoopbackCatcher: @unchecked Sendable {
    private let port: UInt16
    private var listener: NWListener?

    init(port: UInt16) { self.port = port }

    func waitForCallback() async throws -> [String: String] {
        try await withCheckedThrowingContinuation { continuation in
            guard let nwPort = NWEndpoint.Port(rawValue: port),
                  let listener = try? NWListener(using: .tcp, on: nwPort) else {
                continuation.resume(throwing: WhoopError.http("Could not open the callback listener on port \(port)."))
                return
            }
            self.listener = listener
            var finished = false

            listener.newConnectionHandler = { connection in
                connection.start(queue: .global())
                connection.receive(minimumIncompleteLength: 1, maximumLength: 65536) { data, _, _, _ in
                    let request = data.flatMap { String(data: $0, encoding: .utf8) } ?? ""
                    let params = LoopbackCatcher.parseQuery(request)
                    let html = """
                    <html><body style="font-family:-apple-system;background:#05070c;\
                    color:#d8eef8;text-align:center;padding-top:90px">\
                    <h2>WHOOP connected.</h2><p>Return to STOIC OS.</p></body></html>
                    """
                    let response = "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\n"
                        + "Content-Length: \(html.utf8.count)\r\nConnection: close\r\n\r\n\(html)"
                    connection.send(content: Data(response.utf8), completion: .contentProcessed { _ in
                        connection.cancel()
                    })
                    if !finished {
                        finished = true
                        listener.cancel()
                        continuation.resume(returning: params)
                    }
                }
            }

            listener.stateUpdateHandler = { state in
                if case .failed(let error) = state, !finished {
                    finished = true
                    continuation.resume(throwing: error)
                }
            }
            listener.start(queue: .global())

            // Fail clearly instead of hanging if the callback never arrives.
            DispatchQueue.global().asyncAfter(deadline: .now() + 180) {
                if !finished {
                    finished = true
                    listener.cancel()
                    continuation.resume(throwing: WhoopError.http(
                        "WHOOP login timed out — the browser callback was not received. "
                        + "Check that the redirect URL registered with WHOOP is exactly "
                        + "http://localhost:8970/whoop/callback"))
                }
            }
        }
    }

    static func parseQuery(_ request: String) -> [String: String] {
        guard let firstLine = request.split(separator: "\r\n").first else { return [:] }
        let tokens = firstLine.split(separator: " ")
        guard tokens.count >= 2 else { return [:] }
        let path = tokens[1]
        guard let mark = path.firstIndex(of: "?") else { return [:] }
        let query = path[path.index(after: mark)...]
        var result: [String: String] = [:]
        for pair in query.split(separator: "&") {
            let kv = pair.split(separator: "=", maxSplits: 1)
            guard kv.count == 2 else { continue }
            let key = String(kv[0])
            let value = String(kv[1]).removingPercentEncoding ?? String(kv[1])
            result[key] = value
        }
        return result
    }
}

// MARK: - API client

/// WHOOP REST client. Targets the documented v1 surface; if the resolved
/// account is on a different API version, adjust `base` and the model shapes —
/// they are isolated here.
private enum WhoopClient {
    static let base = "https://api.prod.whoop.com/developer/v1"

    static func fetchVitals(accessToken: String) async throws -> WhoopVitals {
        var vitals = WhoopVitals()

        if let recovery = try? await getFirst(RecoveryRecord.self,
                                              path: "/recovery", token: accessToken) {
            vitals.recoveryPercent = recovery.score?.recovery_score.map { Int($0.rounded()) }
            vitals.hrvMs = recovery.score?.hrv_rmssd_milli
            vitals.restingHeartRate = recovery.score?.resting_heart_rate.map { Int($0.rounded()) }
        }
        if let sleep = try? await getFirst(SleepRecord.self,
                                           path: "/activity/sleep", token: accessToken) {
            vitals.sleepPerformance = sleep.score?.sleep_performance_percentage.map { Int($0.rounded()) }
        }
        if let cycle = try? await getFirst(CycleRecord.self,
                                           path: "/cycle", token: accessToken) {
            vitals.dayStrain = cycle.score?.strain
        }
        return vitals
    }

    private static func getFirst<T: Decodable>(_ type: T.Type,
                                               path: String,
                                               token: String) async throws -> T? {
        guard var components = URLComponents(string: base + path) else { throw WhoopError.badURL }
        components.queryItems = [URLQueryItem(name: "limit", value: "1")]
        guard let url = components.url else { throw WhoopError.badURL }

        var request = URLRequest(url: url)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        guard let http = response as? HTTPURLResponse,
              (200..<300).contains(http.statusCode) else {
            throw WhoopError.http("WHOOP API \(path) request failed.")
        }
        return try JSONDecoder().decode(Paginated<T>.self, from: data).records.first
    }

    private struct Paginated<T: Decodable>: Decodable { let records: [T] }

    private struct RecoveryRecord: Decodable {
        let score: Score?
        struct Score: Decodable {
            let recovery_score: Double?
            let resting_heart_rate: Double?
            let hrv_rmssd_milli: Double?
        }
    }
    private struct SleepRecord: Decodable {
        let score: Score?
        struct Score: Decodable {
            let sleep_performance_percentage: Double?
        }
    }
    private struct CycleRecord: Decodable {
        let score: Score?
        struct Score: Decodable {
            let strain: Double?
        }
    }
}
