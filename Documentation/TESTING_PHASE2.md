# Phase 2 Testing Guide

This guide will help you verify that Phase 2 (Database Layer) is complete and working correctly.

## Prerequisites

- Phase 1 completed successfully
- Swift 6.0+ installed
- macOS 14.0+ (for development)

## Overview

Phase 2 implements the complete database layer including:
- GRDB.swift integration with connection pooling
- Migration system with version tracking
- Database seeding functionality
- Backup/dump capabilities
- Database health monitoring

## 1. Clean Build

```bash
# Clean any existing data and build artifacts
rm -rf .build
rm -rf ./data
swift build

# Expected output:
# Build complete! (XX.XXs)
```

**Expected Output:** Build completes successfully with no errors.

## 2. Test Database Initialization

The database should be automatically initialized when any command is run.

```bash
# Check that data directory doesn't exist yet
ls -la ./data 2>/dev/null || echo "Data directory does not exist yet (expected)"
```

**Expected:** Data directory should not exist before first run.

## 3. Test Database Migrations

### 3.1 Run All Migrations

```bash
# Run all pending migrations
.build/debug/swiftbase migrate
```

**Expected Output:**
```json
{"message":"Running database migrations...","level":"INFO",...}
{"message":"Database initialized at: ./data/swiftbase.db","level":"INFO",...}
{"message":"Running all pending migrations...","level":"INFO",...}
{"message":"Starting database migrations...","level":"INFO",...}
{"message":"Running migration 1: CreateInitialTables","level":"INFO",...}
{"message":"Migration 1 completed","level":"INFO",...}
{"message":"Running migration 2: CreateIndexes","level":"INFO",...}
{"message":"Migration 2 completed","level":"INFO",...}
{"message":"Running migration 3: CreateTriggers","level":"INFO",...}
{"message":"Migration 3 completed","level":"INFO",...}
{"message":"Applied 3 migration(s)","level":"INFO",...}
{"message":"Migrations completed successfully!","level":"INFO",...}
```

### 3.2 Verify Database File Created

```bash
# Check that database file was created
ls -lh ./data/swiftbase.db

# Check for WAL files (Write-Ahead Logging)
ls -lh ./data/*.db*
```

**Expected:** You should see:
- `swiftbase.db` - Main database file
- `swiftbase.db-wal` - Write-Ahead Log file
- `swiftbase.db-shm` - Shared memory file

### 3.3 Verify Tables Created

```bash
# Use sqlite3 to inspect the database
sqlite3 ./data/swiftbase.db ".tables"
```

**Expected Output:**
```
_admins         _custom_queries  _files
_audit_log      _documents       _migrations
_collections    _users
```

### 3.4 Check Migration Tracking

```bash
# Check which migrations have been applied
sqlite3 ./data/swiftbase.db "SELECT * FROM _migrations ORDER BY version;"
```

**Expected Output:**
```
1|CreateInitialTables|2024-11-16 ...
2|CreateIndexes|2024-11-16 ...
3|CreateTriggers|2024-11-16 ...
```

### 3.5 Test Re-running Migrations

```bash
# Run migrations again - should report no pending migrations
.build/debug/swiftbase migrate
```

**Expected Output:**
```json
{"message":"No pending migrations","level":"INFO",...}
```

### 3.6 Test Migration Rollback

```bash
# Rollback the last migration
.build/debug/swiftbase migrate --rollback
```

**Expected Output:**
```json
{"message":"Rolling back last migration...","level":"INFO",...}
{"message":"Rolling back migration 3: CreateTriggers","level":"INFO",...}
{"message":"Migration 3 rolled back successfully","level":"INFO",...}
```

Verify rollback:
```bash
sqlite3 ./data/swiftbase.db "SELECT * FROM _migrations;"
```

**Expected:** Only migrations 1 and 2 should be listed.

### 3.7 Re-apply Rolled Back Migration

```bash
# Run migrations again to re-apply migration 3
.build/debug/swiftbase migrate
```

**Expected Output:**
```json
{"message":"Running migration 3: CreateTriggers","level":"INFO",...}
{"message":"Applied 1 migration(s)","level":"INFO",...}
```

### 3.8 Test Migrate to Specific Version

```bash
# Migrate down to version 1
.build/debug/swiftbase migrate --to 1
```

**Expected Output:**
```json
{"message":"Migrating to version 1...","level":"INFO",...}
{"message":"Rolling back migration 3: CreateTriggers","level":"INFO",...}
{"message":"Rolling back migration 2: CreateIndexes","level":"INFO",...}
{"message":"Database is now at version 1","level":"INFO",...}
```

Migrate back up:
```bash
# Migrate back to version 3
.build/debug/swiftbase migrate --to 3
```

**Expected:** Migrations 2 and 3 should be re-applied.

## 4. Test Database Seeding

### 4.1 Run All Seeders

```bash
# Ensure we're at latest migration version
.build/debug/swiftbase migrate

# Run all seeders
.build/debug/swiftbase seed
```

**Expected Output:**
```json
{"message":"Seeding database...","level":"INFO",...}
{"message":"Running all seeders...","level":"INFO",...}
{"message":"Running seeder: DefaultSeeder","level":"INFO",...}
Default admin created:
  Username: admin
  Password: admin123
  IMPORTANT: Change this password immediately!
{"message":"All seeders completed successfully","level":"INFO",...}
{"message":"Database seeding completed!","level":"INFO",...}
```

### 4.2 Verify Admin User Created

```bash
# Check that admin user was created
sqlite3 ./data/swiftbase.db "SELECT username, created_at FROM _admins;"
```

**Expected Output:**
```
admin|2024-11-16 ...
```

### 4.3 Test Running Specific Seeder

```bash
# Run only the DefaultSeeder
.build/debug/swiftbase seed --seeder DefaultSeeder
```

**Expected:** Should run successfully (may show admin already exists if run twice).

### 4.4 Test Verbose Seeding

```bash
# Run with verbose logging
.build/debug/swiftbase seed --verbose
```

**Expected:** Should show DEBUG level logs in addition to INFO logs.

## 5. Test Database Backup/Dump

### 5.1 Create a Backup

```bash
# Create a backup with custom filename
.build/debug/swiftbase dump --output backup_test.db
```

**Expected Output:**
```json
{"message":"Backing up database...","level":"INFO",...}
{"message":"Backing up database to backup_test.db...","level":"INFO",...}
{"message":"Database backup completed","level":"INFO",...}
{"message":"Database backup saved to: backup_test.db","level":"INFO",...}
```

### 5.2 Verify Backup File

```bash
# Check that backup file was created
ls -lh backup_test.db

# Verify backup is a valid SQLite database
sqlite3 backup_test.db ".tables"
```

**Expected:** Backup file should exist and contain the same tables as the original.

### 5.3 Compare Backup with Original

```bash
# Check that backup has same admin user
sqlite3 backup_test.db "SELECT username FROM _admins;"

# Check migration version in backup
sqlite3 backup_test.db "SELECT version FROM _migrations ORDER BY version;"
```

**Expected:** Backup should contain identical data to the original database.

### 5.4 Test Default Backup Name

```bash
# Create backup without specifying filename
.build/debug/swiftbase dump
```

**Expected:** Should create a file named `swiftbase_backup_<timestamp>.db`.

## 6. Test Database Health Check Endpoint

### 6.1 Start the Server

```bash
# Start server on default port
.build/debug/swiftbase serve &
SERVER_PID=$!

# Wait for server to start
sleep 2
```

**Expected Output:**
```json
{"message":"Starting SwiftBase server on 127.0.0.1:8090","level":"INFO",...}
{"message":"Database initialized at: ./data/swiftbase.db","level":"INFO",...}
{"message":"SwiftBase application configured on 127.0.0.1:8090","level":"INFO",...}
```

### 6.2 Test Database Health Endpoint

```bash
# Query the database health endpoint
curl -s http://localhost:8090/health/db | python3 -m json.tool
```

**Expected Output:**
```json
{
    "status": "healthy",
    "database": {
        "isAccessible": true,
        "sizeInBytes": 45056,
        "version": 3,
        "tableCount": 8,
        "path": "./data/swiftbase.db"
    }
}
```

**Verify:**
- `status` should be "healthy"
- `isAccessible` should be `true`
- `version` should be `3` (number of migrations applied)
- `tableCount` should be `8` (7 app tables + 1 migration table)
- `sizeInBytes` should be > 0

### 6.3 Test Regular Health Endpoint

```bash
# Test the regular health endpoint still works
curl -s http://localhost:8090/health | python3 -m json.tool
```

**Expected Output:**
```json
{
    "status": "healthy",
    "timestamp": "2024-11-16T...",
    "version": "0.1.0"
}
```

### 6.4 Stop the Server

```bash
# Stop the server
kill $SERVER_PID
```

## 7. Test Database Persistence

### 7.1 Verify Data Persists Across Runs

```bash
# Check admin user exists
sqlite3 ./data/swiftbase.db "SELECT username FROM _admins;"

# Run seed again - should handle existing data
.build/debug/swiftbase seed

# Verify still only one admin (seeder should be idempotent)
sqlite3 ./data/swiftbase.db "SELECT COUNT(*) FROM _admins;"
```

**Expected:** Should show `1` admin user.

## 8. Test Configuration Options

### 8.1 Test Custom Database Path

```bash
# Create a test config file
cat > /tmp/test-db-config.json << 'EOF'
{
  "server": {
    "host": "127.0.0.1",
    "port": 8090,
    "environment": "test"
  },
  "database": {
    "path": "./data/test-custom.db",
    "maxConnections": 5,
    "enableWAL": true
  },
  "auth": {
    "jwtSecret": "test-secret",
    "accessTokenExpiry": 15,
    "refreshTokenExpiry": 7,
    "bcryptCost": 10
  },
  "storage": {
    "path": "./data/test-storage",
    "maxFileSize": 104857600
  },
  "cache": {
    "enabled": true,
    "ttl": 300,
    "maxSize": 500
  },
  "logging": {
    "level": "info",
    "format": "json"
  }
}
EOF

# Run migrations with custom config
.build/debug/swiftbase migrate --config /tmp/test-db-config.json
```

**Expected:** Should create database at `./data/test-custom.db`.

Verify:
```bash
ls -lh ./data/test-custom.db
```

### 8.2 Test Environment Variable Override

```bash
# Override database path via environment variable
SWIFTBASE_DB_PATH=./data/env-override.db .build/debug/swiftbase migrate
```

**Expected:** Should create database at `./data/env-override.db`.

## 9. Test Error Handling

### 9.1 Test Invalid Migration Version

```bash
# Try to migrate to invalid version
.build/debug/swiftbase migrate --to 99
```

**Expected:** Should complete (migrates to highest available version).

### 9.2 Test Non-existent Seeder

```bash
# Try to run non-existent seeder
.build/debug/swiftbase seed --seeder NonExistentSeeder
```

**Expected:** Should show error message about seeder not found.

## 10. Inspect Database Schema

### 10.1 View Table Structures

```bash
# View _collections table schema
sqlite3 ./data/swiftbase.db ".schema _collections"

# View _users table schema
sqlite3 ./data/swiftbase.db ".schema _users"

# View _documents table schema
sqlite3 ./data/swiftbase.db ".schema _documents"
```

**Expected:** Should show proper table definitions with all columns and constraints.

### 10.2 View Indexes

```bash
# List all indexes
sqlite3 ./data/swiftbase.db "SELECT name, tbl_name FROM sqlite_master WHERE type='index' ORDER BY tbl_name, name;"
```

**Expected Output:** Should show indexes including:
- `idx_documents_collection`
- `idx_documents_created`
- `idx_documents_updated`
- `idx_documents_data_id`
- `idx_files_uploaded_by`
- `idx_files_created`
- `idx_audit_log_created`
- `idx_audit_log_user`
- `idx_audit_log_entity`

### 10.3 View Triggers

```bash
# List all triggers
sqlite3 ./data/swiftbase.db "SELECT name, tbl_name FROM sqlite_master WHERE type='trigger' ORDER BY tbl_name, name;"
```

**Expected Output:** Should show triggers including:
- `update_collections_timestamp`
- `update_users_timestamp`
- `update_admins_timestamp`
- `update_documents_timestamp`
- `update_documents_version`
- `update_custom_queries_timestamp`

### 10.4 Test Triggers Functionality

```bash
# Insert a test collection and verify trigger works
sqlite3 ./data/swiftbase.db << 'EOF'
INSERT INTO _collections (name) VALUES ('test_collection');
SELECT name, created_at, updated_at FROM _collections WHERE name='test_collection';
EOF
```

**Expected:** `created_at` and `updated_at` should have timestamps.

Update and verify trigger:
```bash
sqlite3 ./data/swiftbase.db << 'EOF'
UPDATE _collections SET name='test_collection_updated' WHERE name='test_collection';
SELECT name, created_at, updated_at FROM _collections WHERE name='test_collection_updated';
EOF
```

**Expected:** `updated_at` should be newer than `created_at`.

## 11. Cleanup Test Data

```bash
# Remove test databases and backups
rm -f backup_test.db
rm -f swiftbase_backup_*.db
rm -rf ./data/test-custom.db*
rm -rf ./data/env-override.db*
rm -f /tmp/test-db-config.json
```

## Success Criteria

✅ **Phase 2 is complete if:**

1. Project builds without errors
2. Database is automatically initialized on first run
3. All 3 migrations run successfully
4. Migrations can be rolled back and re-applied
5. Migration to specific version works
6. Database seeding creates default admin user
7. Database backup/dump command works and creates valid backup
8. Database health check endpoint returns correct information
9. All database tables are created with proper schema
10. All indexes are created
11. All triggers are created and functional
12. Custom database paths work via config and environment variables
13. Data persists across multiple runs
14. WAL mode is enabled for better concurrency

## Troubleshooting

### Database locked error
```bash
# Close any open sqlite3 connections
pkill -9 sqlite3

# Remove WAL files and try again
rm -f ./data/*.db-wal ./data/*.db-shm
```

### Migration already applied error
```bash
# Check migration status
sqlite3 ./data/swiftbase.db "SELECT * FROM _migrations;"

# If needed, start fresh
rm -rf ./data
.build/debug/swiftbase migrate
```

### Permission denied
```bash
# Ensure data directory has correct permissions
chmod -R 755 ./data
```

## Next Steps

Once Phase 2 is verified, proceed to Phase 3: Authentication System, which will implement:
- JWT token generation and validation
- User registration and login
- Admin authentication
- Session management
- Password hashing with bcrypt
