import Foundation
import GRDB

/// Migration to create all initial database tables
public struct Migration001_CreateInitialTables: MigrationProtocol {
    public let version = 1
    public let name = "CreateInitialTables"

    public func up(_ db: Database) throws {
        // Collections Table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _collections (
                id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                name TEXT UNIQUE NOT NULL,
                schema TEXT,
                indexes TEXT,
                metadata TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now'))
            )
            """)

        // Users Table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _users (
                id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                email TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                email_verified INTEGER DEFAULT 0,
                refresh_tokens TEXT DEFAULT '[]',
                metadata TEXT DEFAULT '{}',
                last_login TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now'))
            )
            """)

        // Admins Table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _admins (
                id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                username TEXT UNIQUE NOT NULL,
                password_hash TEXT NOT NULL,
                refresh_tokens TEXT DEFAULT '[]',
                last_login TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now'))
            )
            """)

        // Documents Table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _documents (
                id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                collection_id TEXT NOT NULL,
                data TEXT NOT NULL,
                version INTEGER DEFAULT 1,
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now')),
                created_by TEXT,
                updated_by TEXT,
                FOREIGN KEY (collection_id) REFERENCES _collections(id) ON DELETE CASCADE,
                FOREIGN KEY (created_by) REFERENCES _users(id) ON DELETE SET NULL,
                FOREIGN KEY (updated_by) REFERENCES _users(id) ON DELETE SET NULL
            )
            """)

        // Files Table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _files (
                id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                filename TEXT NOT NULL,
                original_name TEXT NOT NULL,
                content_type TEXT,
                size INTEGER NOT NULL,
                path TEXT NOT NULL UNIQUE,
                metadata TEXT DEFAULT '{}',
                uploaded_by TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                FOREIGN KEY (uploaded_by) REFERENCES _users(id) ON DELETE SET NULL,
                CHECK (size <= 104857600)
            )
            """)

        // Custom Queries Table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _custom_queries (
                id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                name TEXT UNIQUE NOT NULL,
                sql TEXT NOT NULL,
                params TEXT,
                description TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now'))
            )
            """)

        // Audit Log Table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _audit_log (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                event_type TEXT NOT NULL,
                entity_type TEXT,
                entity_id TEXT,
                user_id TEXT,
                admin_id TEXT,
                data TEXT,
                ip_address TEXT,
                user_agent TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                FOREIGN KEY (user_id) REFERENCES _users(id) ON DELETE SET NULL,
                FOREIGN KEY (admin_id) REFERENCES _admins(id) ON DELETE SET NULL
            )
            """)
    }

    public func down(_ db: Database) throws {
        // Drop tables in reverse order
        try db.execute(sql: "DROP TABLE IF EXISTS _audit_log")
        try db.execute(sql: "DROP TABLE IF EXISTS _custom_queries")
        try db.execute(sql: "DROP TABLE IF EXISTS _files")
        try db.execute(sql: "DROP TABLE IF EXISTS _documents")
        try db.execute(sql: "DROP TABLE IF EXISTS _admins")
        try db.execute(sql: "DROP TABLE IF EXISTS _users")
        try db.execute(sql: "DROP TABLE IF EXISTS _collections")
    }
}
