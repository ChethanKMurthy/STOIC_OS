import Foundation
import SQLite3

private let sqliteTransient = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

/// Persistence — a SQLite-backed key/value store under Application Support.
///
/// Values are JSON text kept in a single `kv` table. Existing V0 JSON files and
/// `stoic.*` user defaults are imported once, on the first launch after this
/// migration, so no data is lost. The public API is unchanged from the former
/// file-based store, so callers are unaffected.
final class FileStore: @unchecked Sendable {

    private let directory: URL
    private let dbURL: URL
    private var db: OpaquePointer?
    private let lock = NSLock()

    init() {
        let base = FileManager.default.urls(for: .applicationSupportDirectory,
                                            in: .userDomainMask)[0]
        directory = base.appendingPathComponent("STOIC OS", isDirectory: true)
        try? FileManager.default.createDirectory(at: directory,
                                                 withIntermediateDirectories: true)
        dbURL = directory.appendingPathComponent("store.sqlite")

        sqlite3_open_v2(dbURL.path, &db,
                        SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE | SQLITE_OPEN_FULLMUTEX,
                        nil)
        exec("CREATE TABLE IF NOT EXISTS kv (key TEXT PRIMARY KEY, value TEXT NOT NULL);")

        migrateFromFilesIfNeeded()
    }

    /// Location of the data directory (shown in Settings).
    var path: String { directory.path }

    // MARK: - Codable values

    func load<T: Decodable>(_ type: T.Type, _ name: String) -> T? {
        guard let text = rawValue(forKey: name),
              let data = text.data(using: .utf8) else { return nil }
        return try? JSONDecoder.stoic.decode(T.self, from: data)
    }

    func save<T: Encodable>(_ value: T, _ name: String) {
        guard let data = try? JSONEncoder.stoic.encode(value),
              let text = String(data: data, encoding: .utf8) else { return }
        setRawValue(text, forKey: name)
    }

    func delete(_ name: String) {
        lock.lock()
        defer { lock.unlock() }
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        if sqlite3_prepare_v2(db, "DELETE FROM kv WHERE key = ?;", -1, &statement, nil) == SQLITE_OK {
            sqlite3_bind_text(statement, 1, name, -1, sqliteTransient)
            sqlite3_step(statement)
        }
    }

    // MARK: - Flags & strings

    func flag(_ key: String) -> Bool { rawValue(forKey: "flag.\(key)") == "1" }
    func setFlag(_ key: String, _ value: Bool) { setRawValue(value ? "1" : "0", forKey: "flag.\(key)") }
    func string(_ key: String) -> String? { rawValue(forKey: "str.\(key)") }
    func setString(_ key: String, _ value: String) { setRawValue(value, forKey: "str.\(key)") }

    // MARK: - SQLite primitives

    private func rawValue(forKey key: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        guard sqlite3_prepare_v2(db, "SELECT value FROM kv WHERE key = ?;",
                                 -1, &statement, nil) == SQLITE_OK else { return nil }
        sqlite3_bind_text(statement, 1, key, -1, sqliteTransient)
        guard sqlite3_step(statement) == SQLITE_ROW,
              let raw = sqlite3_column_text(statement, 0) else { return nil }
        return String(cString: raw)
    }

    private func setRawValue(_ value: String, forKey key: String) {
        lock.lock()
        defer { lock.unlock() }
        var statement: OpaquePointer?
        defer { sqlite3_finalize(statement) }
        let sql = "INSERT INTO kv(key, value) VALUES(?, ?) " +
                  "ON CONFLICT(key) DO UPDATE SET value = excluded.value;"
        guard sqlite3_prepare_v2(db, sql, -1, &statement, nil) == SQLITE_OK else { return }
        sqlite3_bind_text(statement, 1, key, -1, sqliteTransient)
        sqlite3_bind_text(statement, 2, value, -1, sqliteTransient)
        sqlite3_step(statement)
    }

    private func exec(_ sql: String) {
        lock.lock()
        defer { lock.unlock() }
        sqlite3_exec(db, sql, nil, nil, nil)
    }

    // MARK: - One-time migration from the V0 JSON files

    private func migrateFromFilesIfNeeded() {
        guard rawValue(forKey: "flag.sqliteMigrated") != "1" else { return }

        // JSON files -> kv rows.
        if let files = try? FileManager.default.contentsOfDirectory(
            at: directory, includingPropertiesForKeys: nil) {
            for file in files where file.pathExtension == "json" {
                let name = file.deletingPathExtension().lastPathComponent
                if let data = try? Data(contentsOf: file),
                   let text = String(data: data, encoding: .utf8) {
                    setRawValue(text, forKey: name)
                }
            }
        }

        // stoic.* user defaults -> flag./str. rows.
        for (key, value) in UserDefaults.standard.dictionaryRepresentation()
        where key.hasPrefix("stoic.") {
            let bareKey = String(key.dropFirst("stoic.".count))
            if let boolValue = value as? Bool {
                setRawValue(boolValue ? "1" : "0", forKey: "flag.\(bareKey)")
            } else if let stringValue = value as? String {
                setRawValue(stringValue, forKey: "str.\(bareKey)")
            }
        }

        setRawValue("1", forKey: "flag.sqliteMigrated")
    }
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
