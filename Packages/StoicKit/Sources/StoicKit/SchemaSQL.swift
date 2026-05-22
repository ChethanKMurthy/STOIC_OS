import Foundation

/// SQLite schema for STOIC OS. Applied by the app's persistence layer.
public enum SchemaSQL {

    /// Ordered DDL statements. Run inside one migration.
    public static let v1: [String] = [
        """
        CREATE TABLE IF NOT EXISTS constitution (
            id          TEXT PRIMARY KEY,
            version     INTEGER NOT NULL,
            narrative   TEXT NOT NULL,
            created_at  DATETIME NOT NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS constitution_trait (
            id              TEXT PRIMARY KEY,
            constitution_id TEXT NOT NULL,
            name            TEXT NOT NULL,
            weight          DOUBLE NOT NULL,
            current_level   INTEGER NOT NULL,
            target_level    INTEGER NOT NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS goal (
            id          TEXT PRIMARY KEY,
            title       TEXT NOT NULL,
            timeline    TEXT NOT NULL,
            baseline    TEXT NOT NULL,
            progress    DOUBLE NOT NULL,
            created_at  DATETIME NOT NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS micro_task (
            id            TEXT PRIMARY KEY,
            goal_id       TEXT,
            title         TEXT NOT NULL,
            scheduled_day DATETIME,
            status        TEXT NOT NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS hourly_checkin (
            id              TEXT PRIMARY KEY,
            hour_start      DATETIME NOT NULL,
            activity        TEXT NOT NULL,
            quality         TEXT NOT NULL,
            note            TEXT NOT NULL,
            user_confirmed  BOOLEAN NOT NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS brag_entry (
            id           TEXT PRIMARY KEY,
            date         DATETIME NOT NULL,
            win          TEXT NOT NULL,
            metric       TEXT NOT NULL,
            stakeholders TEXT NOT NULL,
            outcome      TEXT NOT NULL
        );
        """,
        """
        CREATE TABLE IF NOT EXISTS decision_record (
            id          TEXT PRIMARY KEY,
            created_at  DATETIME NOT NULL,
            situation   TEXT NOT NULL,
            is_past     BOOLEAN NOT NULL,
            output_json TEXT NOT NULL,
            outcome     TEXT
        );
        """
    ]
}
