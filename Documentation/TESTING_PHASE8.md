# Phase 8: Realtime WebSocket Module - Testing Guide

**Date:** November 20, 2024
**Phase:** Phase 8 - Realtime WebSocket Module
**Status:** ✅ Complete

## Overview

This document provides comprehensive testing procedures for the Realtime WebSocket Module implementation. The module enables real-time communication between the server and clients through WebSocket connections, with automatic event broadcasting for database changes.

## Prerequisites

### Required Tools

1. **WebSocket Client**
   ```bash
   # Install wscat (WebSocket CLI client)
   npm install -g wscat
   ```

2. **HTTP Client**
   - curl (command line)
   - Postman (GUI)
   - HTTPie (command line)

3. **Server Running**
   ```bash
   swift build
   swift run swiftbase serve
   ```

### Authentication Setup

Before testing WebSocket features, you need valid JWT tokens:

```bash
# 1. Register a user
curl -X POST http://localhost:8090/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "test@example.com",
    "password": "TestPass123!"
  }'

# Response includes accessToken and refreshToken
# Save the accessToken for WebSocket authentication
```

Or login as admin:

```bash
# 2. Admin login
curl -X POST http://localhost:8090/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }'

# Save the accessToken from the response
```

---

## Test Suite

### Test 1: Basic WebSocket Connection

**Objective:** Verify WebSocket endpoint accepts connections

**Steps:**

1. Connect to WebSocket endpoint without authentication:
   ```bash
   wscat -c ws://localhost:8090/api/realtime
   ```

2. **Expected Result:**
   - Connection succeeds
   - Receive welcome message:
     ```json
     {
       "type": "welcome",
       "connectionId": "...",
       "timestamp": "2024-11-20T..."
     }
     ```

**Status:** ✅ Pass / ❌ Fail

---

### Test 2: Authenticated WebSocket Connection

**Objective:** Verify JWT authentication via query parameter

**Steps:**

1. Get JWT token from login/register (see Prerequisites)

2. Connect with token in query parameter:
   ```bash
   wscat -c "ws://localhost:8090/api/realtime?token=YOUR_JWT_TOKEN"
   ```

3. **Expected Result:**
   - Connection succeeds
   - Server logs show "Authenticated WebSocket connection"
   - Receive welcome message

**Alternative:** Authentication via Authorization header
```bash
wscat -c ws://localhost:8090/api/realtime \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

**Status:** ✅ Pass / ❌ Fail

---

### Test 3: Collection-Level Subscription

**Objective:** Subscribe to all events in a collection

**Steps:**

1. Connect to WebSocket (authenticated)

2. Send subscription message:
   ```json
   {
     "action": "subscribe",
     "collection": "products"
   }
   ```

3. **Expected Response:**
   ```json
   {
     "type": "subscribed",
     "subscriptionId": "...",
     "collection": "products",
     "documentId": null
   }
   ```

4. Leave WebSocket connection open for next tests

**Status:** ✅ Pass / ❌ Fail

---

### Test 4: Document-Level Subscription

**Objective:** Subscribe to events for a specific document

**Steps:**

1. Connect to WebSocket (authenticated)

2. Send document subscription:
   ```json
   {
     "action": "subscribe",
     "collection": "products",
     "documentId": "product_123"
   }
   ```

3. **Expected Response:**
   ```json
   {
     "type": "subscribed",
     "subscriptionId": "...",
     "collection": "products",
     "documentId": "product_123"
   }
   ```

**Status:** ✅ Pass / ❌ Fail

---

### Test 5: Receive CREATE Event

**Objective:** Verify subscribers receive create events

**Setup:**
1. Terminal 1: Connect to WebSocket and subscribe to "products" collection
2. Terminal 2: Create a document via HTTP API

**Steps:**

**Terminal 1 (WebSocket):**
```bash
wscat -c "ws://localhost:8090/api/realtime?token=YOUR_TOKEN"
# Then send:
{"action": "subscribe", "collection": "products"}
```

**Terminal 2 (HTTP):**
```bash
curl -X POST http://localhost:8090/api/query \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "action": "create",
    "collection": "products",
    "data": {
      "name": "Test Product",
      "price": 99.99,
      "category": "electronics"
    }
  }'
```

**Expected Result in Terminal 1:**
```json
{
  "event": "create",
  "collection": "products",
  "documentId": "...",
  "document": {
    "id": "...",
    "name": "Test Product",
    "price": 99.99,
    "category": "electronics"
  },
  "timestamp": "2024-11-20T..."
}
```

**Status:** ✅ Pass / ❌ Fail

---

### Test 6: Receive UPDATE Event

**Objective:** Verify subscribers receive update events

**Prerequisites:** Document created in Test 5

**Steps:**

**Terminal 1 (WebSocket):** Keep subscription active from Test 5

**Terminal 2 (HTTP):**
```bash
curl -X POST http://localhost:8090/api/query \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "action": "update",
    "collection": "products",
    "query": {
      "where": { "name": "Test Product" }
    },
    "data": {
      "$set": { "price": 89.99, "onSale": true }
    }
  }'
```

**Expected Result in Terminal 1:**
```json
{
  "event": "update",
  "collection": "products",
  "documentId": "...",
  "document": {
    "$set": { "price": 89.99, "onSale": true }
  },
  "timestamp": "2024-11-20T..."
}
```

**Status:** ✅ Pass / ❌ Fail

---

### Test 7: Receive DELETE Event

**Objective:** Verify subscribers receive delete events

**Prerequisites:** Document from Test 5

**Steps:**

**Terminal 1 (WebSocket):** Keep subscription active

**Terminal 2 (HTTP):**
```bash
curl -X POST http://localhost:8090/api/query \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{
    "action": "delete",
    "collection": "products",
    "query": {
      "where": { "name": "Test Product" }
    }
  }'
```

**Expected Result in Terminal 1:**
```json
{
  "event": "delete",
  "collection": "products",
  "documentId": "...",
  "document": null,
  "timestamp": "2024-11-20T..."
}
```

**Status:** ✅ Pass / ❌ Fail

---

### Test 8: Unsubscribe from Collection

**Objective:** Verify unsubscribe stops event delivery

**Steps:**

1. Connect and subscribe to a collection

2. Send unsubscribe message:
   ```json
   {"action": "unsubscribe"}
   ```

3. **Expected Response:**
   ```json
   {"type": "unsubscribed"}
   ```

4. Create a document in that collection (via HTTP)

5. **Expected Result:** No event received in WebSocket

**Status:** ✅ Pass / ❌ Fail

---

### Test 9: Multiple Concurrent Connections

**Objective:** Verify multiple clients can subscribe simultaneously

**Steps:**

1. Open 3 terminal windows

2. **Terminal 1, 2, 3:** All connect and subscribe to "products":
   ```bash
   wscat -c "ws://localhost:8090/api/realtime?token=YOUR_TOKEN"
   # Send: {"action": "subscribe", "collection": "products"}
   ```

3. **Terminal 4:** Create a document via HTTP

4. **Expected Result:** All 3 WebSocket terminals receive the create event

**Status:** ✅ Pass / ❌ Fail

---

### Test 10: Heartbeat/Ping-Pong

**Objective:** Verify connection stays alive with heartbeat

**Steps:**

1. Connect to WebSocket

2. Enable verbose mode in wscat to see ping/pong frames:
   ```bash
   wscat -c "ws://localhost:8090/api/realtime?token=YOUR_TOKEN" --verbose
   ```

3. Wait 30+ seconds without sending messages

4. **Expected Result:**
   - Server sends PING frames every ~30 seconds
   - Client responds with PONG
   - Connection remains active

**Status:** ✅ Pass / ❌ Fail

---

### Test 11: Connection Timeout

**Objective:** Verify inactive connections are cleaned up

**Setup:** This test requires modifying heartbeat settings or waiting 60+ seconds

**Steps:**

1. Connect to WebSocket

2. Block PONG responses (may require custom client)

3. Wait 60+ seconds

4. **Expected Result:**
   - Server logs show "Connection timed out"
   - Connection is closed
   - Subscriptions are removed

**Status:** ✅ Pass / ❌ Fail / ⏭️ Skip

---

### Test 12: Document-Specific Events Only

**Objective:** Verify document-level subscriptions only receive matching events

**Steps:**

1. **Terminal 1:** Subscribe to specific document:
   ```json
   {
     "action": "subscribe",
     "collection": "products",
     "documentId": "product_A"
   }
   ```

2. **Terminal 2:** Create document with ID "product_A"

3. **Terminal 3:** Create document with ID "product_B"

4. **Expected Result:**
   - Terminal 1 receives event for product_A
   - Terminal 1 does NOT receive event for product_B

**Status:** ✅ Pass / ❌ Fail

---

### Test 13: Admin Statistics Endpoint

**Objective:** Verify connection monitoring endpoint

**Steps:**

1. Connect 2-3 WebSocket clients with subscriptions

2. Query statistics endpoint:
   ```bash
   curl http://localhost:8090/api/admin/realtime/stats \
     -H "Authorization: Bearer ADMIN_JWT_TOKEN"
   ```

3. **Expected Response:**
   ```json
   {
     "totalConnections": 3,
     "authenticatedConnections": 3,
     "totalSubscriptions": 3,
     "subscriptionsByCollection": {
       "products": 2,
       "users": 1
     }
   }
   ```

**Status:** ✅ Pass / ❌ Fail

---

### Test 14: Error Handling - Invalid Action

**Objective:** Verify error responses for invalid messages

**Steps:**

1. Connect to WebSocket

2. Send invalid action:
   ```json
   {"action": "invalid_action"}
   ```

3. **Expected Response:**
   ```json
   {
     "type": "error",
     "message": "Unknown action: invalid_action"
   }
   ```

**Status:** ✅ Pass / ❌ Fail

---

### Test 15: Error Handling - Missing Collection

**Objective:** Verify validation of required fields

**Steps:**

1. Connect to WebSocket

2. Send subscribe without collection:
   ```json
   {"action": "subscribe"}
   ```

3. **Expected Response:**
   ```json
   {
     "type": "error",
     "message": "Collection name required for subscription"
   }
   ```

**Status:** ✅ Pass / ❌ Fail

---

### Test 16: Ping Action

**Objective:** Verify manual ping/pong

**Steps:**

1. Connect to WebSocket

2. Send ping action:
   ```json
   {"action": "ping"}
   ```

3. **Expected Result:** WebSocket PONG frame received

**Status:** ✅ Pass / ❌ Fail

---

### Test 17: Concurrent Events Load Test

**Objective:** Verify system handles rapid event broadcasting

**Steps:**

1. Connect multiple WebSocket clients (5-10)

2. All subscribe to "load_test" collection

3. Rapidly create 50 documents via HTTP:
   ```bash
   for i in {1..50}; do
     curl -X POST http://localhost:8090/api/query \
       -H "Content-Type: application/json" \
       -H "Authorization: Bearer YOUR_TOKEN" \
       -d "{
         \"action\": \"create\",
         \"collection\": \"load_test\",
         \"data\": {\"number\": $i}
       }" &
   done
   wait
   ```

4. **Expected Result:**
   - All clients receive all 50 events
   - No connection drops
   - No missed events
   - Server remains responsive

**Status:** ✅ Pass / ❌ Fail

---

## Integration Tests

### Integration Test 1: Full CRUD Cycle with Realtime

**Objective:** Complete workflow from connection to CRUD operations

**Steps:**

1. **Connect & Subscribe**
   ```bash
   wscat -c "ws://localhost:8090/api/realtime?token=YOUR_TOKEN"
   # Send: {"action": "subscribe", "collection": "orders"}
   ```

2. **Create Order** (separate terminal)
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -d '{
       "action": "create",
       "collection": "orders",
       "data": {
         "customerId": "customer_123",
         "total": 299.99,
         "status": "pending"
       }
     }'
   ```
   *Verify CREATE event received*

3. **Update Order**
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -d '{
       "action": "update",
       "collection": "orders",
       "query": {"where": {"customerId": "customer_123"}},
       "data": {"$set": {"status": "shipped"}}
     }'
   ```
   *Verify UPDATE event received*

4. **Delete Order**
   ```bash
   curl -X POST http://localhost:8090/api/query \
     -H "Content-Type: application/json" \
     -H "Authorization: Bearer YOUR_TOKEN" \
     -d '{
       "action": "delete",
       "collection": "orders",
       "query": {"where": {"customerId": "customer_123"}}
     }'
   ```
   *Verify DELETE event received*

5. **Unsubscribe**
   ```json
   {"action": "unsubscribe"}
   ```

6. **Close Connection**

**Expected:** All events received in correct order, no errors

**Status:** ✅ Pass / ❌ Fail

---

## Performance Benchmarks

### Benchmark 1: Message Latency

**Target:** < 10ms from database write to WebSocket delivery

**Test:**
1. Subscribe to collection
2. Measure time from HTTP POST to WebSocket event receipt
3. Repeat 100 times, calculate average

**Result:** _______ ms average

---

### Benchmark 2: Concurrent Connections

**Target:** Support 100+ concurrent WebSocket connections

**Test:**
1. Open 100 WebSocket connections
2. All subscribe to same collection
3. Create a document
4. Verify all 100 receive the event

**Result:** _______ connections supported

---

### Benchmark 3: Event Throughput

**Target:** Broadcast 1000+ events/second

**Test:**
1. Connect 10 clients
2. Create 1000 documents rapidly
3. Measure time to broadcast all events

**Result:** _______ events/second

---

## Known Issues & Limitations

1. **Query Filtering:** Subscription query filters are stored but not yet actively filtered. All events for a collection are broadcast to all collection subscribers.

2. **Reconnection:** Client-side reconnection logic is not part of server implementation (client responsibility).

3. **Event Replay:** No event history or replay capability for missed events during disconnect.

4. **Message Ordering:** Events are delivered in order per subscription but no global ordering guarantee across subscriptions.

---

## Test Results Summary

| Test # | Test Name | Status | Notes |
|--------|-----------|--------|-------|
| 1 | Basic Connection | ⏳ | |
| 2 | Authenticated Connection | ⏳ | |
| 3 | Collection Subscription | ⏳ | |
| 4 | Document Subscription | ⏳ | |
| 5 | CREATE Event | ⏳ | |
| 6 | UPDATE Event | ⏳ | |
| 7 | DELETE Event | ⏳ | |
| 8 | Unsubscribe | ⏳ | |
| 9 | Multiple Connections | ⏳ | |
| 10 | Heartbeat | ⏳ | |
| 11 | Connection Timeout | ⏳ | |
| 12 | Document-Specific Events | ⏳ | |
| 13 | Admin Statistics | ⏳ | |
| 14 | Invalid Action Error | ⏳ | |
| 15 | Missing Collection Error | ⏳ | |
| 16 | Ping Action | ⏳ | |
| 17 | Load Test | ⏳ | |

**Overall Status:** ⏳ Pending Testing

---

## Next Steps

After completing all tests:

1. ✅ Update test results in this document
2. 📊 Document performance benchmarks
3. 🐛 File issues for any failures
4. 📝 Update SOW.md with test completion status
5. ➡️ Proceed to Phase 9: Admin UI Development

---

## API Reference

### WebSocket Endpoint

**URL:** `ws://localhost:8090/api/realtime`

**Authentication:**
- Query parameter: `?token=JWT_TOKEN`
- Header: `Authorization: Bearer JWT_TOKEN`

### Client Messages

**Subscribe to Collection:**
```json
{
  "action": "subscribe",
  "collection": "collection_name"
}
```

**Subscribe to Document:**
```json
{
  "action": "subscribe",
  "collection": "collection_name",
  "documentId": "doc_id"
}
```

**Unsubscribe:**
```json
{
  "action": "unsubscribe"
}
```

**Ping:**
```json
{
  "action": "ping"}
```

### Server Messages

**Welcome:**
```json
{
  "type": "welcome",
  "connectionId": "...",
  "timestamp": "..."
}
```

**Subscribed:**
```json
{
  "type": "subscribed",
  "subscriptionId": "...",
  "collection": "...",
  "documentId": "..." or null
}
```

**Event:**
```json
{
  "event": "create" | "update" | "delete",
  "collection": "...",
  "documentId": "...",
  "document": {...} or null,
  "timestamp": "..."
}
```

**Error:**
```json
{
  "type": "error",
  "message": "..."
}
```

---

**Testing Completed By:** _____________
**Date:** _____________
**Sign-off:** _____________
