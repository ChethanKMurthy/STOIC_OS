import Foundation

/// V0 persistence — JSON files under Application Support.
///
/// V0 deliberately uses flat JSON files to keep the dependency surface small.
/// A future version will move to a SQLite-backed store with vector search;
/// the schema is already prepared in `StoicKit.SchemaSQL`.
final class FileStore: @unchecked Sendable {

    private let directory: URL
    private let defaults = UserDefaults.standard

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        directory = base.appendingPathComponent("STOIC OS", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory,
                                                 withIntermediateDirectories: true)
    }

    /// Location of the data directory (shown in Settings).
    var path: String { directory.path }

    func load<T: Decodable>(_ type: T.Type, _ name: String) -> T? {
        let url = directory.appendingPathComponent("\(name).json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder.stoic.decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, _ name: String) {
        let url = directory.appendingPathComponent("\(name).json")
        guard let data = try? JSONEncoder.stoic.encode(value) else { return }
        try? data.write(to: url, options: .atomic)
    }

    func delete(_ name: String) {
        let url = directory.appendingPathComponent("\(name).json")
        try? FileManager.default.removeItem(at: url)
    }

    func flag(_ key: String) -> Bool { defaults.bool(forKey: "stoic.\(key)") }
    func setFlag(_ key: String, _ value: Bool) { defaults.set(value, forKey: "stoic.\(key)") }
    func string(_ key: String) -> String? { defaults.string(forKey: "stoic.\(key)") }
    func setString(_ key: String, _ value: String) { defaults.set(value, forKey: "stoic.\(key)") }
}

extension JSONEncoder {
    static var stoic: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }
}

extension JSONDecoder {
    static var stoic: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
