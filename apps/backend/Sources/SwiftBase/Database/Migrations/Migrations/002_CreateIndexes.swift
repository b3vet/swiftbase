import Foundation
import GRDB

/// Migration to create performance indexes
public struct Migration002_CreateIndexes: MigrationProtocol {
    public let version = 2
    public let name = "CreateIndexes"

    public func up(_ db: Database) throws {
        // Documents indexes
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_documents_collection
            ON _documents(collection_id)
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_documents_created
            ON _documents(created_at)
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_documents_updated
            ON _documents(updated_at)
            """)

        // Files indexes
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_files_uploaded_by
            ON _files(uploaded_by)
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_files_created
            ON _files(created_at)
            """)

        // Audit log indexes
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_audit_log_created
            ON _audit_log(created_at)
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_audit_log_user
            ON _audit_log(user_id)
            """)

        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_audit_log_entity
            ON _audit_log(entity_type, entity_id)
            """)

        // JSON indexes for common queries on documents
        try db.execute(sql: """
            CREATE INDEX IF NOT EXISTS idx_documents_data_id
            ON _documents(json_extract(data, '$._id'))
            """)
    }

    public func down(_ db: Database) throws {
        // Drop indexes
        try db.execute(sql: "DROP INDEX IF EXISTS idx_documents_collection")
        try db.execute(sql: "DROP INDEX IF EXISTS idx_documents_created")
        try db.execute(sql: "DROP INDEX IF EXISTS idx_documents_updated")
        try db.execute(sql: "DROP INDEX IF EXISTS idx_files_uploaded_by")
        try db.execute(sql: "DROP INDEX IF EXISTS idx_files_created")
        try db.execute(sql: "DROP INDEX IF EXISTS idx_audit_log_created")
        try db.execute(sql: "DROP INDEX IF EXISTS idx_audit_log_user")
        try db.execute(sql: "DROP INDEX IF EXISTS idx_audit_log_entity")
        try db.execute(sql: "DROP INDEX IF EXISTS idx_documents_data_id")
    }
}
