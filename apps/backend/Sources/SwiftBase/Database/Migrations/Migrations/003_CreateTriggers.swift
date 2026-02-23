import Foundation
import GRDB

/// Migration to create triggers for automatic timestamp updates
public struct Migration003_CreateTriggers: MigrationProtocol {
    public let version = 3
    public let name = "CreateTriggers"

    public func up(_ db: Database) throws {
        // Trigger for _collections updated_at
        try db.execute(sql: """
            CREATE TRIGGER IF NOT EXISTS update_collections_timestamp
            AFTER UPDATE ON _collections
            BEGIN
                UPDATE _collections SET updated_at = datetime('now') WHERE id = NEW.id;
            END
            """)

        // Trigger for _users updated_at
        try db.execute(sql: """
            CREATE TRIGGER IF NOT EXISTS update_users_timestamp
            AFTER UPDATE ON _users
            BEGIN
                UPDATE _users SET updated_at = datetime('now') WHERE id = NEW.id;
            END
            """)

        // Trigger for _admins updated_at
        try db.execute(sql: """
            CREATE TRIGGER IF NOT EXISTS update_admins_timestamp
            AFTER UPDATE ON _admins
            BEGIN
                UPDATE _admins SET updated_at = datetime('now') WHERE id = NEW.id;
            END
            """)

        // Trigger for _documents updated_at
        try db.execute(sql: """
            CREATE TRIGGER IF NOT EXISTS update_documents_timestamp
            AFTER UPDATE ON _documents
            BEGIN
                UPDATE _documents SET updated_at = datetime('now') WHERE id = NEW.id;
            END
            """)

        // Trigger for _documents version increment
        try db.execute(sql: """
            CREATE TRIGGER IF NOT EXISTS update_documents_version
            AFTER UPDATE ON _documents
            WHEN OLD.data != NEW.data
            BEGIN
                UPDATE _documents SET version = version + 1 WHERE id = NEW.id;
            END
            """)

        // Trigger for _custom_queries updated_at
        try db.execute(sql: """
            CREATE TRIGGER IF NOT EXISTS update_custom_queries_timestamp
            AFTER UPDATE ON _custom_queries
            BEGIN
                UPDATE _custom_queries SET updated_at = datetime('now') WHERE id = NEW.id;
            END
            """)
    }

    public func down(_ db: Database) throws {
        // Drop triggers
        try db.execute(sql: "DROP TRIGGER IF EXISTS update_collections_timestamp")
        try db.execute(sql: "DROP TRIGGER IF EXISTS update_users_timestamp")
        try db.execute(sql: "DROP TRIGGER IF EXISTS update_admins_timestamp")
        try db.execute(sql: "DROP TRIGGER IF EXISTS update_documents_timestamp")
        try db.execute(sql: "DROP TRIGGER IF EXISTS update_documents_version")
        try db.execute(sql: "DROP TRIGGER IF EXISTS update_custom_queries_timestamp")
    }
}
