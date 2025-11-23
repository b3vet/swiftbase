import Foundation
import GRDB

/// Migration to create the saved_queries table
public struct Migration004_CreateSavedQueriesTable: MigrationProtocol {
    public let version = 4
    public let name = "CreateSavedQueriesTable"

    public func up(_ db: Database) throws {
        // Saved Queries Table
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _saved_queries (
                id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                name TEXT UNIQUE NOT NULL,
                description TEXT,
                collection_id TEXT NOT NULL,
                action TEXT NOT NULL,
                query_json TEXT NOT NULL,
                data_json TEXT,
                created_by TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                updated_at TEXT DEFAULT (datetime('now'))
            )
            """)

        // Create index on name for fast lookups
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_saved_queries_name
            ON _saved_queries(name)
            """)

        // Create index on collection_id
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_saved_queries_collection
            ON _saved_queries(collection_id)
            """)
    }

    public func down(_ db: Database) throws {
        try db.execute(sql: "DROP TABLE IF EXISTS _saved_queries")
    }
}
