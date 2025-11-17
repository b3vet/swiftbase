# Phase 5 Testing Documentation: Collection Management Module

This document provides comprehensive testing instructions for the Collection Management Module implementation (Phase 5).

## Implementation Status

**Status**: Core functionality implemented
**Date**: 2024-11-16
**Dependencies**: Phase 2 (Database), Phase 3 (Auth), Phase 4 (Query Engine)

### What's Implemented:
- ✅ Dynamic collection creation API
- ✅ Collection deletion with cascade support
- ✅ Collection metadata management
- ✅ Collection statistics endpoints
- ✅ Bulk operations (create, update, delete)
- ✅ Collection listing and retrieval
- ✅ Integration with existing query engine

### API Endpoints Added:
**Collection Management (Protected)**:
- `GET /api/admin/collections` - List all collections
- `GET /api/admin/collections/:name` - Get collection details
- `GET /api/admin/collections/:name/stats` - Get collection statistics

**Collection Management (Admin Only)**:
- `POST /api/admin/collections` - Create new collection
- `PUT /api/admin/collections/:name` - Update collection metadata
- `DELETE /api/admin/collections/:name?cascade=true` - Delete collection

**Bulk Operations (Protected)**:
- `POST /api/bulk` - Execute bulk operations

---

## Prerequisites

1. **Complete Previous Phases**:
   - Phase 1: Project setup ✅
   - Phase 2: Database layer ✅
   - Phase 3: Authentication system ✅
   - Phase 4: Query engine ✅

2. **Database Setup**:
   ```bash
   # Run migrations
   swiftbase migrate

   # Seed database (creates admin user)
   swiftbase seed
   ```

3. **Server Running**:
   ```bash
   swiftbase serve --port 8090
   ```

---

## Test 1: Create Collections (Admin Only)

**Description**: Create new collections with schema and metadata.

### Steps:

1. **Login as Admin**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/login \
     -H "Content-Type: application/json" \
     -d '{
       "username": "admin",
       "password": "admin123"
     }'
   ```

   Save the `accessToken`.

2. **Create Products Collection**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/collections \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "name": "products",
       "schema": {
         "name": "string",
         "price": "number",
         "description": "string",
         "active": "boolean",
         "tags": "array"
       },
       "indexes": ["name", "price", "active"],
       "metadata": {
         "description": "Product catalog",
         "version": "1.0"
       }
     }'
   ```

3. **Create Users Collection**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/collections \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "name": "orders",
       "schema": {
         "user_id": "string",
         "total": "number",
         "status": "string",
         "items": "array"
       },
       "indexes": ["user_id", "status"],
       "metadata": {
         "description": "Customer orders"
       }
     }'
   ```

### Expected Result:
```json
{
  "id": "<generated_id>",
  "name": "products",
  "schema": { ... },
  "indexes": ["name", "price", "active"],
  "metadata": { ... },
  "createdAt": "2024-11-16T...",
  "updatedAt": "2024-11-16T..."
}
```

### Verification:
- Collection is created with unique ID
- Schema and indexes are stored
- Metadata is preserved
- Timestamps are set

---

## Test 2: List All Collections

**Description**: Retrieve all collections with document counts.

### Steps:

1. **List Collections (as authenticated user)**:
   ```bash
   curl -X GET http://localhost:8090/api/admin/collections \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0
   ```

### Expected Result:
```json
{
  "success": true,
  "collections": [
    {
      "id": "...",
      "name": "products",
      "schema": { ... },
      "indexes": [...],
      "metadata": { ... },
      "documentCount": 0,
      "createdAt": "...",
      "updatedAt": "..."
    },
    {
      "id": "...",
      "name": "orders",
      ...
    }
  ],
  "count": 2
}
```

### Verification:
- All collections are returned
- Document counts are included
- Collections are ordered by creation date (desc)

---

## Test 3: Get Collection Details

**Description**: Retrieve specific collection with statistics.

### Steps:

1. **Get Collection Info**:
   ```bash
   curl -X GET http://localhost:8090/api/admin/collections/products \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0
   ```

2. **Get Collection Statistics**:
   ```bash
   curl -X GET http://localhost:8090/api/admin/collections/products/stats \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0
   ```

### Expected Result:

**Collection Info**:
```json
{
  "id": "...",
  "name": "products",
  "schema": { ... },
  "indexes": ["name", "price", "active"],
  "metadata": { ... },
  "documentCount": 0,
  "createdAt": "...",
  "updatedAt": "..."
}
```

**Statistics**:
```json
{
  "collection": "products",
  "documentCount": 0,
  "totalSize": 0,
  "averageDocumentSize": 0.0,
  "indexCount": 3,
  "oldestDocument": null,
  "newestDocument": null
}
```

### Verification:
- Collection details match what was created
- Statistics show zero documents for new collection
- Index count matches configured indexes

---

## Test 4: Update Collection Metadata

**Description**: Update collection schema, indexes, and metadata.

### Steps:

1. **Update Collection**:
   ```bash
   curl -X PUT http://localhost:8090/api/admin/collections/products \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "schema": {
         "name": "string",
         "price": "number",
         "description": "string",
         "active": "boolean",
         "tags": "array",
         "featured": "boolean"
       },
       "indexes": ["name", "price", "active", "featured"],
       "metadata": {
         "description": "Product catalog - Updated",
         "version": "1.1",
         "lastModified": "2024-11-16"
       }
     }'
   ```

### Expected Result:
```json
{
  "id": "...",
  "name": "products",
  "schema": {
    ...
    "featured": "boolean"
  },
  "indexes": ["name", "price", "active", "featured"],
  "metadata": {
    "description": "Product catalog - Updated",
    "version": "1.1",
    "lastModified": "2024-11-16"
  },
  "createdAt": "...",
  "updatedAt": "<new timestamp>"
}
```

### Verification:
- Schema includes new field
- Indexes are updated
- Metadata is replaced
- updatedAt timestamp changes

---

## Test 5: Bulk Create Documents

**Description**: Create multiple documents in one request.

### Steps:

1. **Bulk Create Products**:
   ```bash
   curl -X POST http://localhost:8090/api/bulk \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "operations": [
         {
           "type": "create",
           "collection": "products",
           "data": {
             "name": "Widget A",
             "price": 99.99,
             "description": "Premium widget",
             "active": true,
             "tags": ["premium", "bestseller"]
           }
         },
         {
           "type": "create",
           "collection": "products",
           "data": {
             "name": "Widget B",
             "price": 149.99,
             "description": "Deluxe widget",
             "active": true,
             "tags": ["deluxe"]
           }
         },
         {
           "type": "create",
           "collection": "products",
           "data": {
             "name": "Widget C",
             "price": 49.99,
             "description": "Basic widget",
             "active": false,
             "tags": ["basic"]
           }
         }
       ]
     }'
   ```

### Expected Result:
```json
{
  "success": true,
  "results": [
    {
      "index": 0,
      "success": true,
      "data": {
        "id": "...",
        "_id": "...",
        "name": "Widget A",
        ...
      }
    },
    {
      "index": 1,
      "success": true,
      "data": { ... }
    },
    {
      "index": 2,
      "success": true,
      "data": { ... }
    }
  ],
  "totalOperations": 3,
  "successfulOperations": 3,
  "failedOperations": 0
}
```

### Verification:
- All 3 documents created successfully
- Each has unique ID
- Success count matches total operations
- No failures

---

## Test 6: Bulk Update Documents

**Description**: Update multiple documents matching criteria.

### Steps:

1. **Bulk Update - Set Featured Flag**:
   ```bash
   curl -X POST http://localhost:8090/api/bulk \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "operations": [
         {
           "type": "update",
           "collection": "products",
           "query": {
             "name": "Widget A"
           },
           "data": {
             "featured": true,
             "discount": 10
           }
         },
         {
           "type": "update",
           "collection": "products",
           "query": {
             "price": 149.99
           },
           "data": {
             "featured": true
           }
         }
       ]
     }'
   ```

### Expected Result:
```json
{
  "success": true,
  "results": [
    {
      "index": 0,
      "success": true,
      "data": { "updated": true }
    },
    {
      "index": 1,
      "success": true,
      "data": { "updated": true }
    }
  ],
  "totalOperations": 2,
  "successfulOperations": 2,
  "failedOperations": 0
}
```

### Verification:
- Documents are updated
- Version numbers increment
- updated_at timestamps change
- Query via /api/query shows new fields

---

## Test 7: Bulk Delete Documents

**Description**: Delete multiple documents in one request.

### Steps:

1. **Bulk Delete - Remove Inactive Products**:
   ```bash
   curl -X POST http://localhost:8090/api/bulk \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "operations": [
         {
           "type": "delete",
           "collection": "products",
           "query": {
             "active": false
           }
         }
       ]
     }'
   ```

### Expected Result:
```json
{
  "success": true,
  "results": [
    {
      "index": 0,
      "success": true,
      "data": { "deleted": 1 }
    }
  ],
  "totalOperations": 1,
  "successfulOperations": 1,
  "failedOperations": 0
}
```

### Verification:
- Inactive product (Widget C) is deleted
- Document count decreases
- Query for inactive products returns empty

---

## Test 8: Mixed Bulk Operations

**Description**: Combine create, update, and delete in one request.

### Steps:

1. **Mixed Bulk Operations**:
   ```bash
   curl -X POST http://localhost:8090/api/bulk \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "operations": [
         {
           "type": "create",
           "collection": "products",
           "data": {
             "name": "Widget D",
             "price": 199.99,
             "active": true
           }
         },
         {
           "type": "update",
           "collection": "products",
           "query": { "name": "Widget A" },
           "data": { "price": 89.99 }
         },
         {
           "type": "delete",
           "collection": "products",
           "query": { "name": "Widget B" }
         }
       ]
     }'
   ```

### Expected Result:
```json
{
  "success": true,
  "results": [
    {
      "index": 0,
      "success": true,
      "data": { "id": "...", ... }
    },
    {
      "index": 1,
      "success": true,
      "data": { "updated": true }
    },
    {
      "index": 2,
      "success": true,
      "data": { "deleted": 1 }
    }
  ],
  "totalOperations": 3,
  "successfulOperations": 3,
  "failedOperations": 0
}
```

### Verification:
- Create, update, and delete all succeed
- Operations execute in order
- Final state reflects all changes

---

## Test 9: Collection Statistics After Operations

**Description**: Verify statistics update after document operations.

### Steps:

1. **Check Statistics**:
   ```bash
   curl -X GET http://localhost:8090/api/admin/collections/products/stats \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0
   ```

### Expected Result:
```json
{
  "collection": "products",
  "documentCount": 2,
  "totalSize": 450,
  "averageDocumentSize": 225.0,
  "indexCount": 4,
  "oldestDocument": "2024-11-16T10:00:00Z",
  "newestDocument": "2024-11-16T10:05:00Z"
}
```

### Verification:
- Document count reflects current state (2 after bulk ops)
- Total size and average calculated correctly
- Oldest/newest timestamps match actual documents

---

## Test 10: Delete Collection Without Cascade (Should Fail)

**Description**: Attempt to delete collection with documents.

### Steps:

1. **Try to Delete Collection**:
   ```bash
   curl -X DELETE http://localhost:8090/api/admin/collections/products \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0
   ```

### Expected Result:
```json
{
  "error": "Collection 'products' contains 2 documents. Use cascade=true to delete them."
}
```

**Status Code**: 409 Conflict

### Verification:
- Request is rejected
- Error message indicates document count
- Collection remains intact

---

## Test 11: Delete Collection With Cascade

**Description**: Delete collection and all its documents.

### Steps:

1. **Delete with Cascade**:
   ```bash
   curl -X DELETE "http://localhost:8090/api/admin/collections/products?cascade=true" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0
   ```

2. **Verify Deletion**:
   ```bash
   curl -X GET http://localhost:8090/api/admin/collections/products \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0
   ```

### Expected Result:

**Delete Response**:
```json
{
  "success": true,
  "message": "Collection 'products' deleted successfully"
}
```

**Get Response**:
```json
{
  "error": "Collection 'products' not found"
}
```

**Status Code**: 404 Not Found

### Verification:
- Collection is deleted
- All documents are deleted (cascade)
- Collection no longer appears in listings

---

## Test 12: Collection Name Validation

**Description**: Test collection name validation rules.

### Steps:

1. **Invalid Characters**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/collections \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "name": "my collection!",
       "metadata": {}
     }'
   ```

2. **SQL Keywords**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/collections \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "name": "SELECT",
       "metadata": {}
     }'
   ```

3. **Valid Names**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/collections \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "name": "my_collection-2024",
       "metadata": {}
     }'
   ```

### Expected Result:
- Invalid characters: 400 Bad Request
- SQL keywords: May be allowed (check validation)
- Valid format: 200 OK, collection created

### Verification:
- Only alphanumeric, underscore, hyphen allowed
- Validation prevents injection attacks

---

## Test 13: Duplicate Collection Names

**Description**: Attempt to create collection with existing name.

### Steps:

1. **Create Collection**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/collections \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "name": "test_collection",
       "metadata": {}
     }'
   ```

2. **Try to Create Again**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/collections \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "name": "test_collection",
       "metadata": {}
     }'
   ```

### Expected Result:
```json
{
  "error": "Collection 'test_collection' already exists"
}
```

**Status Code**: 409 Conflict

### Verification:
- Duplicate names are rejected
- Original collection remains unchanged

---

## Test 14: Authorization Checks

**Description**: Verify admin-only endpoints are protected.

### Steps:

1. **Login as Regular User**:
   ```bash
   curl -X POST http://localhost:8090/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "password123"
     }'
   ```

2. **Try to Create Collection (User)**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/collections \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3NjMzMzI3MjIuNzkxNjc0MSwiZXhwIjoxNzYzMzMzNjIyLjc5MTY3NDEsInN1YiI6IjJhYTM1ZWY1YTQ0MzQ4OTFhMzRmNTBlMTE5MzI2YzQxIiwidHlwZSI6InVzZXIifQ.8GAuVmL-i2MaYGLtnzp26vy-1FCNpZY2YTIV7J9p7Ak" \
     -d '{
       "name": "unauthorized",
       "metadata": {}
     }'
   ```

3. **Try to Delete Collection (User)**:
   ```bash
   curl -X DELETE http://localhost:8090/api/admin/collections/test_collection \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3NjMzMzI3MjIuNzkxNjc0MSwiZXhwIjoxNzYzMzMzNjIyLjc5MTY3NDEsInN1YiI6IjJhYTM1ZWY1YTQ0MzQ4OTFhMzRmNTBlMTE5MzI2YzQxIiwidHlwZSI6InVzZXIifQ.8GAuVmL-i2MaYGLtnzp26vy-1FCNpZY2YTIV7J9p7Ak"
   ```

4. **Try to List Collections (User) - Should Work**:
   ```bash
   curl -X GET http://localhost:8090/api/admin/collections \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpYXQiOjE3NjMzMzI3MjIuNzkxNjc0MSwiZXhwIjoxNzYzMzMzNjIyLjc5MTY3NDEsInN1YiI6IjJhYTM1ZWY1YTQ0MzQ4OTFhMzRmNTBlMTE5MzI2YzQxIiwidHlwZSI6InVzZXIifQ.8GAuVmL-i2MaYGLtnzp26vy-1FCNpZY2YTIV7J9p7Ak"
   ```

### Expected Result:
- Create: 403 Forbidden
- Delete: 403 Forbidden
- List: 200 OK (users can view collections)

### Verification:
- Admin-only operations require admin token
- Users can read collection info
- Proper 403 responses for unauthorized access

---

## Test 15: Integration with Query Engine

**Description**: Verify collections work with existing query engine.

### Steps:

1. **Create Collection**:
   ```bash
   curl -X POST http://localhost:8090/api/admin/collections \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "name": "integration_test",
       "metadata": {}
     }'
   ```

2. **Add Documents via Query Engine**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0 \
     -d '{
       "action": "create",
       "collection": "integration_test",
       "data": {
         "title": "Test Document",
         "value": 42
       }
     }'
   ```

3. **Query Documents**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0" \
     -d '{
       "action": "find",
       "collection": "integration_test",
       "query": {
         "where": { "value": { "$gte": 40 } }
       }
     }'
   ```

4. **Check Statistics**:
   ```bash
   curl -X GET http://localhost:8090/api/admin/collections/integration_test/stats \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0"
   ```

### Expected Result:
- Collection created successfully
- Documents created via query engine
- Query returns matching documents
- Statistics reflect document count

### Verification:
- Collection management integrates with query engine
- No conflicts between systems
- Statistics update correctly

---

## Test 16: Bulk Operation Error Handling

**Description**: Test partial failure in bulk operations.

### Steps:

1. **Mixed Valid/Invalid Operations**:
   ```bash
   curl -X POST http://localhost:8090/api/bulk \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHAiOjE3NjMzNjg5ODEuMDU1ODU4MSwiaWF0IjoxNzYzMzY4MDgxLjA1NTg1ODEsInN1YiI6ImM0MzdjZDJhMTU0MDFjMmQyY2FhOGI3YWE2YTZhNzAxIiwidHlwZSI6ImFkbWluIn0.EP8XcDCplrkrMF4-mTxjNQWZ7nZchRBQG4PDm0nOHp0" \
     -d '{
       "operations": [
         {
           "type": "create",
           "collection": "test_collection",
           "data": { "valid": true }
         },
         {
           "type": "create",
           "collection": "nonexistent_collection",
           "data": { "invalid": true }
         },
         {
           "type": "update",
           "collection": "test_collection",
           "query": { "nonexistent": "field" },
           "data": { "updated": true }
         }
       ]
     }'
   ```

### Expected Result:
```json
{
  "success": false,
  "results": [
    {
      "index": 0,
      "success": true,
      "data": { ... }
    },
    {
      "index": 1,
      "success": false,
      "error": "Collection 'nonexistent_collection' not found"
    },
    {
      "index": 2,
      "success": true,
      "data": { "updated": true }
    }
  ],
  "totalOperations": 3,
  "successfulOperations": 2,
  "failedOperations": 1
}
```

### Verification:
- Valid operations succeed
- Invalid operations fail gracefully
- Error messages are clear
- success=false when any operation fails
- Successful operations are not rolled back

---

## Performance Considerations

### Bulk Operations
- **Recommendation**: Limit bulk operations to 100 items per request
- **Reason**: Each operation is a separate database transaction
- **Alternative**: Use streaming for very large datasets

### Collection Statistics
- **Note**: Statistics queries scan all documents
- **Recommendation**: Cache statistics for large collections
- **Update**: Consider background job for stats updates

### Indexes
- **Schema field**: Stores suggested indexes, but doesn't create them automatically
- **Action Required**: Create JSON indexes manually for better performance:
  ```sql
  CREATE INDEX idx_products_name ON _documents(json_extract(data, '$.name'))
    WHERE collection_id = '<products_collection_id>';
  ```

---

## Known Limitations

1. **Schema Enforcement**: Schema is stored but not enforced. Documents can have any structure.
2. **Index Creation**: Indexes are metadata only. Actual SQLite indexes must be created separately.
3. **Transactions**: Bulk operations are not atomic. Partial failures possible.
4. **Cascade Validation**: No check for foreign key references in other collections.

---

## Security Checklist

✅ Collection creation requires admin authentication
✅ Collection deletion requires admin authentication
✅ Collection updates require admin authentication
✅ Bulk operations require user authentication
✅ Collection name validation (prevents injection)
✅ Query parameter validation in bulk operations
✅ Collection listing available to all authenticated users

---

## Next Steps

After testing Phase 5:
1. Verify all 16 test scenarios pass
2. Test bulk operations with various data sizes
3. Create custom indexes for your collections
4. Monitor collection statistics
5. Proceed to Phase 6: Cache Layer

---

## Support

For issues or questions:
- Check server logs for detailed error messages
- Verify collections exist before operations
- Ensure authentication tokens are not expired
- Review bulk operation results for specific failures

**Phase 5 Implementation**: COMPLETE ✅
**Ready for Testing**: YES ✅
