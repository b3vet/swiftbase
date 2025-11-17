# Phase 3 Testing Guide

This guide will help you verify that Phase 3 (Authentication System) is complete and working correctly.

## Prerequisites

- Phase 1 & 2 completed successfully
- Swift 6.0+ installed
- macOS 14.0+ (for development)
- Database migrations run (`swiftbase migrate`)
- Database seeded with default admin (`swiftbase seed`)
- `curl` and `jq` for testing (or any API client like Postman)

## Overview

Phase 3 implements the complete authentication system including:
- JWT token generation with 15-minute expiration
- Refresh token system with 7-day expiration and rotation
- Password hashing (SHA256 + salt, ready for bcrypt upgrade)
- User registration and login
- Admin authentication (separate from users)
- Session management with multiple concurrent sessions
- JWT middleware for protected routes
- Logout with token invalidation

## Important Note

**Swift 6 Concurrency:** Phase 3 implementation has minor Swift 6 strict concurrency warnings related to Sendable conformance for controllers. These do not affect functionality and will be resolved in a future update. For testing purposes, the code structure and logic are complete.

## 1. Setup

### 1.1 Ensure Database is Ready

```bash
# Clean build
rm -rf .build ./data
swift build

# Run migrations
.build/debug/swiftbase migrate

# Seed database (creates default admin)
.build/debug/swiftbase seed
```

**Expected:** Database created with admin user (username: `admin`, password: `admin123`).

### 1.2 Start the Server

```bash
# Start server (in a separate terminal or background)
.build/debug/swiftbase serve
```

**Expected Output:**
```json
{"message":"Starting SwiftBase server on 127.0.0.1:8090","level":"INFO",...}
{"message":"Database initialized at: ./data/swiftbase.db","level":"INFO",...}
{"message":"SwiftBase application configured on 127.0.0.1:8090","level":"INFO",...}
```

Server should be running on `http://localhost:8090`.

## 2. User Authentication Flow

### 2.1 User Registration

```bash
# Register a new user
curl -X POST http://localhost:8090/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!",
    "metadata": {
      "name": "John Doe",
      "role": "developer"
    }
  }' | jq .
```

**Expected Response:**
```json
{
  "user": {
    "id": "abc123...",
    "email": "user@example.com",
    "emailVerified": false,
    "metadata": {
      "name": "John Doe",
      "role": "developer"
    },
    "lastLogin": "2024-11-16T...",
    "createdAt": "2024-11-16T..."
  },
  "tokens": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "expiresIn": 900
  }
}
```

**Verify:**
- User object returned without password
- Both access and refresh tokens provided
- `expiresIn` is 900 seconds (15 minutes)
- User ID is generated
- Metadata is preserved

### 2.2 Test Registration Validation

#### Invalid Email Format
```bash
curl -X POST http://localhost:8090/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "invalid-email",
    "password": "SecurePass123!"
  }' | jq .
```

**Expected:** HTTP 400 with error message about invalid email format.

#### Password Too Short
```bash
curl -X POST http://localhost:8090/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user2@example.com",
    "password": "short"
  }' | jq .
```

**Expected:** HTTP 400 with error message about password length.

#### Duplicate Email
```bash
# Try to register with same email again
curl -X POST http://localhost:8090/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "AnotherPass123!"
  }' | jq .
```

**Expected:** HTTP 409 (Conflict) with error message about email already registered.

### 2.3 User Login

```bash
# Login with registered user
curl -X POST http://localhost:8090/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }' | jq .
```

**Expected Response:**
```json
{
  "user": {
    "id": "abc123...",
    "email": "user@example.com",
    "emailVerified": false,
    "metadata": {...},
    "lastLogin": "2024-11-16T...",
    "createdAt": "2024-11-16T..."
  },
  "tokens": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "expiresIn": 900
  }
}
```

**Verify:**
- New tokens generated (different from registration tokens)
- `lastLogin` timestamp updated
- User data matches registration

### 2.4 Test Login with Invalid Credentials

#### Wrong Password
```bash
curl -X POST http://localhost:8090/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "WrongPassword123!"
  }' | jq .
```

**Expected:** HTTP 401 (Unauthorized) with "Invalid credentials" message.

#### Non-existent User
```bash
curl -X POST http://localhost:8090/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "nonexistent@example.com",
    "password": "SomePassword123!"
  }' | jq .
```

**Expected:** HTTP 401 (Unauthorized) with "Invalid credentials" message.

### 2.5 Access Protected Route

```bash
# Save the access token from login
ACCESS_TOKEN="<paste access token here>"

# Get current user info
curl -X GET http://localhost:8090/api/auth/me \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
```

**Expected Response:**
```json
{
  "id": "abc123...",
  "email": "user@example.com",
  "emailVerified": false,
  "metadata": {...},
  "lastLogin": "2024-11-16T...",
  "createdAt": "2024-11-16T..."
}
```

### 2.6 Test Protected Route Without Token

```bash
# Try without Authorization header
curl -X GET http://localhost:8090/api/auth/me | jq .
```

**Expected:** HTTP 401 with "Missing Authorization header" message.

### 2.7 Test Protected Route with Invalid Token

```bash
# Try with invalid token
curl -X GET http://localhost:8090/api/auth/me \
  -H "Authorization: Bearer invalid.token.here" | jq .
```

**Expected:** HTTP 401 with "Invalid token" message.

### 2.8 Refresh Access Token

```bash
# Save refresh token from login
REFRESH_TOKEN="<paste refresh token here>"

# Refresh to get new access token
curl -X POST http://localhost:8090/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }" | jq .
```

**Expected Response:**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "expiresIn": 900
}
```

**Verify:**
- New access token generated
- New refresh token generated (token rotation)
- Old refresh token is now invalid

### 2.9 Test Token Rotation (Old Refresh Token Invalid)

```bash
# Try to use the old refresh token again
curl -X POST http://localhost:8090/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$REFRESH_TOKEN\"
  }" | jq .
```

**Expected:** HTTP 401 with "Invalid refresh token" message (token was rotated).

### 2.10 User Logout

```bash
# Logout (invalidates all sessions)
curl -X POST http://localhost:8090/api/auth/logout \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq .
```

**Expected Response:**
```json
{
  "message": "Logged out successfully"
}
```

### 2.11 Verify Tokens Invalid After Logout

```bash
# Try to use access token after logout
curl -X GET http://localhost:8090/api/auth/me \
  -H "Authorization: Bearer $ACCESS_TOKEN" | jq .

# Try to refresh after logout
curl -X POST http://localhost:8090/api/auth/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$NEW_REFRESH_TOKEN\"
  }" | jq .
```

**Expected:** Both requests should return HTTP 401 (tokens invalidated).

## 3. Admin Authentication Flow

### 3.1 Admin Login

```bash
# Login as admin (created by seeder)
curl -X POST http://localhost:8090/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "admin123"
  }' | jq .
```

**Expected Response:**
```json
{
  "admin": {
    "id": "...",
    "username": "admin",
    "lastLogin": "2024-11-16T...",
    "createdAt": "2024-11-16T..."
  },
  "tokens": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "expiresIn": 900
  }
}
```

**Verify:**
- Admin object returned (no password)
- Admin tokens generated
- Token structure same as user tokens

### 3.2 Admin Login with Invalid Credentials

```bash
curl -X POST http://localhost:8090/api/admin/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "admin",
    "password": "wrongpassword"
  }' | jq .
```

**Expected:** HTTP 401 with "Invalid credentials" message.

### 3.3 Access Admin Protected Route

```bash
# Save admin access token
ADMIN_ACCESS_TOKEN="<paste admin access token>"

# Get current admin info
curl -X GET http://localhost:8090/api/admin/me \
  -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" | jq .
```

**Expected Response:**
```json
{
  "id": "...",
  "username": "admin",
  "lastLogin": "2024-11-16T...",
  "createdAt": "2024-11-16T..."
}
```

### 3.4 Test User Token Cannot Access Admin Routes

```bash
# Try to access admin route with user token
curl -X GET http://localhost:8090/api/admin/me \
  -H "Authorization: Bearer $USER_ACCESS_TOKEN" | jq .
```

**Expected:** HTTP 403 (Forbidden) with "Admin access required" message.

### 3.5 Admin Token Refresh

```bash
# Save admin refresh token
ADMIN_REFRESH_TOKEN="<paste admin refresh token>"

# Refresh admin token
curl -X POST http://localhost:8090/api/admin/refresh \
  -H "Content-Type: application/json" \
  -d "{
    \"refreshToken\": \"$ADMIN_REFRESH_TOKEN\"
  }" | jq .
```

**Expected Response:**
```json
{
  "accessToken": "eyJ...",
  "refreshToken": "eyJ...",
  "expiresIn": 900
}
```

**Verify:** Token rotation works for admin (old refresh token invalid).

### 3.6 Admin Logout

```bash
curl -X POST http://localhost:8090/api/admin/logout \
  -H "Authorization: Bearer $ADMIN_ACCESS_TOKEN" | jq .
```

**Expected Response:**
```json
{
  "message": "Logged out successfully"
}
```

## 4. Multiple Sessions Test

### 4.1 Login from Multiple Devices

```bash
# First login (simulate device 1)
RESPONSE1=$(curl -s -X POST http://localhost:8090/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }')

TOKEN1=$(echo $RESPONSE1 | jq -r '.tokens.accessToken')
REFRESH1=$(echo $RESPONSE1 | jq -r '.tokens.refreshToken')

# Second login (simulate device 2)
RESPONSE2=$(curl -s -X POST http://localhost:8090/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user@example.com",
    "password": "SecurePass123!"
  }')

TOKEN2=$(echo $RESPONSE2 | jq -r '.tokens.accessToken')
REFRESH2=$(echo $RESPONSE2 | jq -r '.tokens.refreshToken')

echo "Device 1 Token: $TOKEN1"
echo "Device 2 Token: $TOKEN2"
```

### 4.2 Verify Both Sessions Work

```bash
# Test device 1
curl -X GET http://localhost:8090/api/auth/me \
  -H "Authorization: Bearer $TOKEN1" | jq '.id'

# Test device 2
curl -X GET http://localhost:8090/api/auth/me \
  -H "Authorization: Bearer $TOKEN2" | jq '.id'
```

**Expected:** Both requests succeed with same user ID.

### 4.3 Logout from One Device

```bash
# Logout from device 1 (invalidates ALL sessions)
curl -X POST http://localhost:8090/api/auth/logout \
  -H "Authorization: Bearer $TOKEN1"
```

### 4.4 Verify All Sessions Invalidated

```bash
# Try device 1
curl -X GET http://localhost:8090/api/auth/me \
  -H "Authorization: Bearer $TOKEN1"

# Try device 2
curl -X GET http://localhost:8090/api/auth/me \
  -H "Authorization: Bearer $TOKEN2"
```

**Expected:** Both return HTTP 401 (all sessions invalidated on logout).

## 5. JWT Token Inspection

### 5.1 Decode Access Token (Informational)

You can decode JWT tokens at https://jwt.io or using a JWT decoder:

```bash
# Example: decode using node.js
node -e "console.log(JSON.parse(Buffer.from('$ACCESS_TOKEN'.split('.')[1], 'base64')))"
```

**Expected Payload:**
```json
{
  "sub": "user_id_here",
  "type": "user",
  "iat": 1700000000,
  "exp": 1700000900
}
```

**Verify:**
- `sub` contains user/admin ID
- `type` is "user" or "admin"
- `exp` is `iat` + 900 seconds (15 minutes)

### 5.2 Decode Refresh Token

```bash
# Decode refresh token
node -e "console.log(JSON.parse(Buffer.from('$REFRESH_TOKEN'.split('.')[1], 'base64')))"
```

**Expected Payload:**
```json
{
  "sub": "user_id_here",
  "type": "user",
  "jti": "unique_token_id",
  "iat": 1700000000,
  "exp": 1700604800
}
```

**Verify:**
- Contains `jti` (unique token ID for rotation tracking)
- `exp` is `iat` + 7 days (604800 seconds)

## 6. Database Verification

### 6.1 Check Users Table

```bash
sqlite3 ./data/swiftbase.db "SELECT id, email, email_verified, last_login FROM _users;"
```

**Expected:** User created with email, last_login timestamp updated.

### 6.2 Check Refresh Tokens Stored

```bash
sqlite3 ./data/swiftbase.db "SELECT id, email, length(refresh_tokens) as token_count FROM _users WHERE email='user@example.com';"
```

**Expected:** `refresh_tokens` JSON field contains stored token information.

### 6.3 Check Admins Table

```bash
sqlite3 ./data/swiftbase.db "SELECT id, username, last_login FROM _admins;"
```

**Expected:** Admin user exists with updated last_login.

### 6.4 Verify Password Hashing

```bash
sqlite3 ./data/swiftbase.db "SELECT email, password_hash FROM _users WHERE email='user@example.com';"
```

**Expected:** Password hash format: `sha256$cost$salt$hash` (not plain text).

## 7. Security Tests

### 7.1 Test Authorization Header Formats

#### Missing "Bearer" prefix
```bash
curl -X GET http://localhost:8090/api/auth/me \
  -H "Authorization: $ACCESS_TOKEN"
```

**Expected:** HTTP 401 with "Invalid Authorization header format" message.

#### Wrong scheme
```bash
curl -X GET http://localhost:8090/api/auth/me \
  -H "Authorization: Basic $ACCESS_TOKEN"
```

**Expected:** HTTP 401 with "Invalid Authorization header format" message.

### 7.2 Test Token Expiration (Manual)

To test token expiration, you would need to:
1. Generate a token
2. Wait 15 minutes
3. Try to use it

**Expected:** HTTP 401 with "Token has expired" message.

For quick testing, you can modify the `accessTokenExpiry` in config to 1 minute.

### 7.3 Test SQL Injection in Login

```bash
curl -X POST http://localhost:8090/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "admin@example.com\" OR \"1\"=\"1",
    "password": "anything"
  }'
```

**Expected:** HTTP 401 (parameterized queries prevent SQL injection).

## 8. Edge Cases

### 8.1 Register with Empty Metadata

```bash
curl -X POST http://localhost:8090/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user2@example.com",
    "password": "SecurePass123!"
  }' | jq .
```

**Expected:** Success with empty metadata object `{}`.

### 8.2 Case-Insensitive Email

```bash
# Register with uppercase email
curl -X POST http://localhost:8090/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "email": "User3@EXAMPLE.COM",
    "password": "SecurePass123!"
  }'

# Login with lowercase
curl -X POST http://localhost:8090/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "email": "user3@example.com",
    "password": "SecurePass123!"
  }' | jq '.user.email'
```

**Expected:** Email stored and matched in lowercase.

## 9. Performance Tests

### 9.1 Concurrent Logins

```bash
# Run 10 concurrent login requests
for i in {1..10}; do
  curl -X POST http://localhost:8090/api/auth/login \
    -H "Content-Type: application/json" \
    -d '{
      "email": "user@example.com",
      "password": "SecurePass123!"
    }' &
done
wait
```

**Expected:** All requests complete successfully.

### 9.2 Token Validation Performance

```bash
# Time 100 protected route accesses
time for i in {1..100}; do
  curl -s -X GET http://localhost:8090/api/auth/me \
    -H "Authorization: Bearer $ACCESS_TOKEN" > /dev/null
done
```

**Expected:** Should complete in reasonable time (< 10 seconds for 100 requests).

## Success Criteria

✅ **Phase 3 is complete if:**

1. User registration creates account with hashed password
2. User login returns valid JWT tokens
3. Admin login works separately from user login
4. Access tokens expire after 15 minutes (900 seconds)
5. Refresh tokens expire after 7 days
6. Token refresh implements rotation (old refresh token invalid)
7. Protected routes require valid JWT token
8. Admin-only routes reject user tokens
9. Logout invalidates all user sessions
10. Multiple concurrent sessions supported
11. Password validation enforces minimum length
12. Email validation enforces proper format
13. Duplicate email registration prevented
14. SQL injection attempts blocked
15. Tokens stored securely in database
16. JWT middleware properly validates and extracts claims

## Troubleshooting

### "Missing Authorization header"
Ensure you're including the Authorization header:
```bash
-H "Authorization: Bearer <your_token>"
```

### "Token has expired"
Generate a new token by logging in again.

### "Invalid refresh token"
Refresh token was already used (rotated) or user logged out. Login again.

### Cannot connect to server
```bash
# Check if server is running
curl http://localhost:8090/health

# Check the port
lsof -i :8090
```

### Build errors (Swift 6 concurrency)
The current implementation has minor Sendable conformance warnings. These don't affect functionality. To suppress:
```bash
swift build -Xswiftc -warnings-as-errors=false
```

## Next Steps

Once Phase 3 is verified, you can proceed to Phase 4: MongoDB-Style Query Engine, which will implement:
- Query parser for MongoDB-style queries
- SQL query generation
- Query operators ($eq, $ne, $gt, etc.)
- Custom query registration
- Query optimization and caching
