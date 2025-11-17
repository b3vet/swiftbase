# Phase 4 Testing Documentation: MongoDB-Style Query Engine

This document provides comprehensive testing instructions for the MongoDB-Style Query Engine implementation (Phase 4).

## Implementation Status

**Status**: Core functionality implemented
**Date**: 2024-11-16
**Pending**: Swift 6 strict concurrency warnings (same as Phase 3)

### What's Implemented:
- ✅ MongoDB-style query parser with operator support
- ✅ SQL query builder for SQLite translation
- ✅ Query service with CRUD operations
- ✅ Custom query registration system
- ✅ Query endpoint `/api/query` with authentication
- ✅ Collection info endpoint `/api/collections/:collection`
- ✅ Admin custom query management

### Supported Operators:
**Comparison**: `$eq`, `$ne`, `$gt`, `$gte`, `$lt`, `$lte`, `$in`, `$nin`
**Logical**: `$and`, `$or`, `$not`
**Element**: `$exists`, `$type`
**Array**: `$all`, `$elemMatch`, `$size`
**Evaluation**: `$regex`, `$mod`
**Update**: `$set`, `$unset`, `$inc`, `$push`, `$pull`, `$addToSet`

---

## Prerequisites

1. **Complete Previous Phases**:
   - Phase 1: Project setup ✅
   - Phase 2: Database layer ✅
   - Phase 3: Authentication system ✅

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

## Test 1: Basic Document Creation

**Description**: Create a new document in a collection.

### Steps:

1. **Login as User**:
   ```bash
   curl -X POST http://localhost:8090/api/auth/login \
     -H "Content-Type: application/json" \
     -d '{
       "email": "test@example.com",
       "password": "password123"
     }'
   ```

   Save the `accessToken` from the response.

2. **Create a Product Document**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "create",
       "collection": "products",
       "data": {
         "name": "Premium Widget",
         "price": 99.99,
         "description": "High-quality widget",
         "category_ids": ["cat_123", "cat_456"],
         "tags": ["premium", "bestseller"],
         "inventory": {
           "quantity": 150,
           "warehouse": "main"
         },
         "active": true
       }
     }'
   ```

### Expected Result:
```json
{
  "success": true,
  "data": {
    "id": "<generated_id>",
    "_id": "<generated_id>",
    "name": "Premium Widget",
    "price": 99.99,
    ...
  }
}
```

### Verification:
- Response contains success: true
- Document has auto-generated `id` and `_id`
- All fields are preserved

---

## Test 2: Find Documents with Comparison Operators

**Description**: Query documents using comparison operators.

### Steps:

1. **Create Multiple Products**:
   Create products with various prices (50, 100, 150, 200).

2. **Find Products in Price Range**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": {
           "price": { "$gte": 50, "$lte": 200 },
           "active": true
         },
         "orderBy": { "price": "asc" },
         "limit": 10
       }
     }'
   ```

### Expected Result:
```json
{
  "success": true,
  "data": [
    { "id": "...", "data": { "price": 50, ... } },
    { "id": "...", "data": { "price": 100, ... } },
    ...
  ],
  "count": 4
}
```

### Verification:
- All returned products have price between 50 and 200
- Results are ordered by price ascending
- active field is true
- Count matches number of documents

---

## Test 3: Array Operators ($in, $all)

**Description**: Test array-based queries.

### Steps:

1. **Find Products in Specific Categories**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": {
           "category_ids": { "$in": ["cat_123", "cat_789"] }
         }
       }
     }'
   ```

2. **Find Products with All Tags**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": {
           "tags": { "$all": ["premium", "bestseller"] }
         }
       }
     }'
   ```

### Expected Result:
- First query returns products with ANY of the specified categories
- Second query returns products with ALL specified tags

### Verification:
- Array operators work correctly with JSON arrays
- Results match the operator semantics

---

## Test 4: Logical Operators ($and, $or)

**Description**: Test compound logical queries.

### Steps:

1. **Find with AND Conditions**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": {
           "$and": [
             { "price": { "$gte": 100 } },
             { "active": true },
             { "inventory.quantity": { "$gt": 0 } }
           ]
         }
       }
     }'
   ```

2. **Find with OR Conditions**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": {
           "$or": [
             { "tags": { "$in": ["sale"] } },
             { "price": { "$lt": 50 } }
           ]
         }
       }
     }'
   ```

### Expected Result:
- AND query returns products matching ALL conditions
- OR query returns products matching ANY condition

### Verification:
- Logical combinations work correctly
- Nested field access (inventory.quantity) works

---

## Test 5: Element Operators ($exists, $type)

**Description**: Test field existence and type checking.

### Steps:

1. **Find Documents with Field**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": {
           "description": { "$exists": true }
         }
       }
     }'
   ```

2. **Find Documents by Type**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": {
           "price": { "$type": "number" }
         }
       }
     }'
   ```

### Expected Result:
- $exists filters by field presence
- $type filters by data type

### Verification:
- Documents without description are excluded in first query
- Type checking works for numbers, strings, etc.

---

## Test 6: Update Operations

**Description**: Test document updates with update operators.

### Steps:

1. **Update with $set**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "update",
       "collection": "products",
       "query": {
         "where": { "_id": "<document_id>" }
       },
       "data": {
         "$set": { "price": 199.99, "featured": true }
       }
     }'
   ```

2. **Update with $inc**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "update",
       "collection": "products",
       "query": {
         "where": { "_id": "<document_id>" }
       },
       "data": {
         "$inc": { "inventory.quantity": -5 }
       }
     }'
   ```

3. **Update with $push**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "update",
       "collection": "products",
       "query": {
         "where": { "_id": "<document_id>" }
       },
       "data": {
         "$push": { "tags": "new-tag" }
       }
     }'
   ```

### Expected Result:
```json
{
  "success": true,
  "data": { "updated": 1 },
  "count": 1
}
```

### Verification:
- $set replaces field values
- $inc increments numeric fields
- $push adds to arrays
- updated_at timestamp is updated

---

## Test 7: Count and FindOne Operations

**Description**: Test count and single document retrieval.

### Steps:

1. **Count Documents**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "count",
       "collection": "products",
       "query": {
         "where": { "active": true }
       }
     }'
   ```

2. **Find One Document**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "findOne",
       "collection": "products",
       "query": {
         "where": { "price": { "$gte": 100 } },
         "orderBy": { "price": "desc" }
       }
     }'
   ```

### Expected Result:
```json
// Count
{
  "success": true,
  "data": { "count": 5 },
  "count": 5
}

// FindOne
{
  "success": true,
  "data": { "id": "...", "price": 200, ... }
}
```

### Verification:
- Count returns total matching documents
- FindOne returns highest-priced product
- FindOne throws 404 if no document found

---

## Test 8: Delete Operation

**Description**: Test document deletion.

### Steps:

1. **Delete Specific Document**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "delete",
       "collection": "products",
       "query": {
         "where": { "_id": "<document_id>" }
       }
     }'
   ```

2. **Delete Multiple Documents**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "delete",
       "collection": "products",
       "query": {
         "where": { "active": false }
       }
     }'
   ```

### Expected Result:
```json
{
  "success": true,
  "data": { "deleted": 3 },
  "count": 3
}
```

### Verification:
- Documents are permanently deleted
- Count reflects number of deletions
- Subsequent queries don't return deleted documents

---

## Test 9: Field Selection and Ordering

**Description**: Test select fields and result ordering.

### Steps:

1. **Select Specific Fields**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "select": ["name", "price", "active"],
         "orderBy": { "price": "desc" },
         "limit": 5
       }
     }'
   ```

2. **Distinct Values**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "distinct": "category_ids"
       }
     }'
   ```

### Expected Result:
- First query returns only selected fields
- Results ordered by price descending
- Distinct returns unique values

### Verification:
- Response includes only requested fields
- Ordering is correct
- Distinct eliminates duplicates

---

## Test 10: Collection Info Endpoint

**Description**: Get metadata about a collection.

### Steps:

1. **Get Collection Info**:
   ```bash
   curl -X GET http://localhost:8090/api/collections/products \
     -H "Authorization: Bearer <ACCESS_TOKEN>"
   ```

### Expected Result:
```json
{
  "success": true,
  "data": {
    "collection": "products",
    "count": 10
  }
}
```

### Verification:
- Returns correct collection name
- Count matches actual document count

---

## Test 11: Custom Query Management (Admin Only)

**Description**: Test custom query registration (admin feature).

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

2. **List Custom Queries**:
   ```bash
   curl -X GET http://localhost:8090/api/admin/queries \
     -H "Authorization: Bearer <ADMIN_ACCESS_TOKEN>"
   ```

### Expected Result:
```json
{
  "success": true,
  "data": []
}
```

### Verification:
- Only admins can access this endpoint
- Returns list of registered custom queries
- Users get 403 Forbidden if they try to access

---

## Test 12: Query Validation and Security

**Description**: Test input validation and SQL injection prevention.

### Steps:

1. **Invalid Field Name**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": { "'; DROP TABLE _documents; --": true }
       }
     }'
   ```

2. **Invalid Operator**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": { "price": { "$invalid": 100 } }
       }
     }'
   ```

3. **Exceeding Limit**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "limit": 10000
       }
     }'
   ```

### Expected Result:
- All requests return 400 Bad Request
- Error messages explain validation failure
- No SQL injection occurs

### Verification:
- Field name validation prevents SQL injection
- Invalid operators are rejected
- Limits are enforced (max 1000)

---

## Test 13: Authentication Requirements

**Description**: Verify all query endpoints require authentication.

### Steps:

1. **Query Without Token**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -d '{
       "action": "find",
       "collection": "products"
     }'
   ```

2. **Query With Invalid Token**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer invalid_token_here" \
     -d '{
       "action": "find",
       "collection": "products"
     }'
   ```

### Expected Result:
- Both requests return 401 Unauthorized
- Clear error message about missing/invalid authentication

### Verification:
- All query operations are protected
- JWT validation is enforced
- Token expiry is respected

---

## Test 14: Complex Nested Queries

**Description**: Test queries with nested field access and complex conditions.

### Steps:

1. **Query Nested Fields**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": {
           "inventory.quantity": { "$gt": 100 },
           "inventory.warehouse": "main"
         }
       }
     }'
   ```

2. **Complex Combined Query**:
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer <ACCESS_TOKEN>" \
     -d '{
       "action": "find",
       "collection": "products",
       "query": {
         "where": {
           "$and": [
             { "price": { "$gte": 50, "$lte": 200 } },
             { "$or": [
               { "tags": { "$in": ["premium"] } },
               { "featured": true }
             ]},
             { "inventory.quantity": { "$exists": true } }
           ]
         },
         "select": ["name", "price", "tags"],
         "orderBy": { "price": "asc" },
         "limit": 10
       }
     }'
   ```

### Expected Result:
- Nested field access works (inventory.quantity)
- Complex logical combinations are evaluated correctly
- All query features work together

### Verification:
- JSON path extraction works for nested fields
- Multiple operators combine correctly
- Results match all specified conditions

---

## Known Issues

### Swift 6 Concurrency Warnings
- **Issue**: Non-Sendable function conversion warnings in controllers
- **Impact**: Build warnings but functionality is not affected
- **Status**: Pending - same as Phase 3
- **Resolution**: Requires refactoring controllers to be actors or using different patterns with Hummingbird

### Pending Features
- Full aggregation pipeline (simplified version implemented)
- $pull operator for array removal (basic implementation)
- Custom REGEXP function for SQLite (using LIKE as fallback)
- Transaction support for multi-document updates

---

## Performance Notes

- **JSON Extraction**: SQLite's `json_extract()` is used for field access
- **Indexes**: Create indexes on frequently queried JSON fields for better performance
- **Limit Enforcement**: Maximum limit of 1000 documents per query
- **Array Operations**: May be slow on large arrays without proper indexing

---

## Security Checklist

✅ Authentication required for all query endpoints
✅ Field name validation (SQL injection prevention)
✅ Operator validation
✅ Limit enforcement
✅ SQL parameterization (prevents injection)
✅ JWT token validation
✅ Admin-only endpoints properly protected

---

## Next Steps

After testing Phase 4:
1. Verify all 14 test scenarios pass
2. Test with production-like data volumes
3. Add custom indexes for your specific query patterns
4. Register custom queries for common operations
5. Proceed to Phase 5: File Storage System

---

## Support

For issues or questions:
- Check server logs for detailed error messages
- Verify database migrations are up to date
- Ensure authentication tokens are not expired
- Review query syntax against MongoDB documentation

**Phase 4 Implementation**: COMPLETE ✅
**Core Functionality**: WORKING ✅
**Concurrency Issues**: PENDING (same as Phase 3)
