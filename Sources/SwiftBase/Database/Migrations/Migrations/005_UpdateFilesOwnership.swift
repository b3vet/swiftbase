import Foundation
import GRDB

/// Migration to update file ownership model
/// Replaces uploaded_by with separate user_id and admin_id columns
public struct Migration005_UpdateFilesOwnership: MigrationProtocol {
    public let version = 5
    public let name = "UpdateFilesOwnership"

    public func up(_ db: Database) throws {
        // Create new table with user_id and admin_id columns
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _files_new (
                id TEXT PRIMARY KEY DEFAULT (lower(hex(randomblob(16)))),
                filename TEXT NOT NULL,
                original_name TEXT NOT NULL,
                content_type TEXT,
                size INTEGER NOT NULL,
                path TEXT NOT NULL UNIQUE,
                metadata TEXT DEFAULT '{}',
                user_id TEXT,
                admin_id TEXT,
                created_at TEXT DEFAULT (datetime('now')),
                FOREIGN KEY (user_id) REFERENCES _users(id) ON DELETE SET NULL,
                FOREIGN KEY (admin_id) REFERENCES _admins(id) ON DELETE SET NULL,
                CHECK ((user_id IS NULL) != (admin_id IS NULL)),
                CHECK (size <= 104857600)
            )
            """)

        // Migrate data - need to check if uploaded_by exists in _users or _admins
        // First, insert files where uploaded_by exists in _users table
        try db.execute(sql: """
            INSERT INTO _files_new (id, filename, original_name, content_type, size, path, metadata, user_id, admin_id, created_at)
            SELECT
                f.id,
                f.filename,
                f.original_name,
                f.content_type,
                f.size,
                f.path,
                f.metadata,
                f.uploaded_by,
                NULL,
                f.created_at
            FROM _files f
            WHERE f.uploaded_by IS NOT NULL
            AND EXISTS (SELECT 1 FROM _users u WHERE u.id = f.uploaded_by)
            """)

        // Insert files where uploaded_by exists in _admins table
        try db.execute(sql: """
            INSERT INTO _files_new (id, filename, original_name, content_type, size, path, metadata, user_id, admin_id, created_at)
            SELECT
                f.id,
                f.filename,
                f.original_name,
                f.content_type,
                f.size,
                f.path,
                f.metadata,
                NULL,
                f.uploaded_by,
                f.created_at
            FROM _files f
            WHERE f.uploaded_by IS NOT NULL
            AND EXISTS (SELECT 1 FROM _admins a WHERE a.id = f.uploaded_by)
            AND NOT EXISTS (SELECT 1 FROM _users u WHERE u.id = f.uploaded_by)
            """)

        // Insert files where uploaded_by is NULL (anonymous uploads, shouldn't happen but handle it)
        // For these, we'll set admin_id to a placeholder to satisfy CHECK constraint
        // Actually, the CHECK constraint requires exactly one to be set, so we can't have both NULL
        // We'll skip files with NULL uploaded_by that don't match any user or admin
        // Or we could assign them to the first admin if one exists

        // Get first admin ID if exists
        let firstAdminId = try? String.fetchOne(db, sql: "SELECT id FROM _admins LIMIT 1")

        if let firstAdminId = firstAdminId {
            // Assign orphaned/null files to first admin
            try db.execute(sql: """
                INSERT INTO _files_new (id, filename, original_name, content_type, size, path, metadata, user_id, admin_id, created_at)
                SELECT
                    f.id,
                    f.filename,
                    f.original_name,
                    f.content_type,
                    f.size,
                    f.path,
                    f.metadata,
                    NULL,
                    ?,
                    f.created_at
                FROM _files f
                WHERE f.uploaded_by IS NULL
                OR (
                    f.uploaded_by NOT IN (SELECT id FROM _users)
                    AND f.uploaded_by NOT IN (SELECT id FROM _admins)
                )
                """, arguments: [firstAdminId])
        }
        // If no admin exists, orphaned files will be skipped (shouldn't happen in practice)

        // Drop old table
        try db.execute(sql: "DROP TABLE _files")

        // Rename new table
        try db.execute(sql: "ALTER TABLE _files_new RENAME TO _files")
    }

    public func down(_ db: Database) throws {
        // Recreate table with old uploaded_by column
        try db.execute(sql: """
            CREATE TABLE IF NOT EXISTS _files_new (
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

        // Migrate data back - prefer user_id over admin_id
        try db.execute(sql: """
            INSERT INTO _files_new (id, filename, original_name, content_type, size, path, metadata, uploaded_by, created_at)
            SELECT
                id,
                filename,
                original_name,
                content_type,
                size,
                path,
                metadata,
                COALESCE(user_id, admin_id),
                created_at
            FROM _files
            """)

        // Drop current table
        try db.execute(sql: "DROP TABLE _files")

        // Rename new table
        try db.execute(sql: "ALTER TABLE _files_new RENAME TO _files")
    }
}
