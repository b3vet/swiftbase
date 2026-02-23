# @swiftbase/sdk

A lightweight, type-safe TypeScript SDK for interacting with [SwiftBase](https://github.com/your-org/swiftbase) backends.

## Features

- **Type-safe** - Full TypeScript support with strict types
- **Fluent Query API** - MongoDB-style query builder
- **Authentication** - User and admin authentication with auto token refresh
- **Realtime** - WebSocket subscriptions with auto-reconnect
- **File Storage** - Upload/download with progress tracking
- **Cross-platform** - Works in browsers, Node.js, and edge runtimes

## Installation

```bash
npm install @swiftbase/sdk
# or
pnpm add @swiftbase/sdk
# or
yarn add @swiftbase/sdk
```

## Quick Start

```typescript
import { createClient } from '@swiftbase/sdk'

// Create client
const sb = createClient({
  url: 'http://localhost:8090'
})

// Authenticate
await sb.auth.login({
  email: 'user@example.com',
  password: 'password'
})

// Query data
const products = await sb.collection('products')
  .where({ active: true, price: { $gte: 50 } })
  .orderBy('created_at', 'desc')
  .limit(10)
  .find()

// Subscribe to changes
sb.realtime.subscribe('products', (event) => {
  console.log('Product changed:', event.type, event.document)
})
```

## Configuration

```typescript
const sb = createClient({
  url: 'http://localhost:8090',

  // Auth configuration
  auth: {
    storage: 'localStorage',    // 'localStorage' | 'sessionStorage' | 'memory'
    autoRefresh: true,          // Auto-refresh tokens before expiry
    persistSession: true        // Persist session across page reloads
  },

  // Request configuration
  request: {
    timeout: 30000,             // Request timeout in ms
    retry: {
      attempts: 3,              // Number of retry attempts
      backoff: 'exponential'    // 'exponential' | 'linear' | 'none'
    },
    headers: {                  // Custom headers for all requests
      'X-Custom-Header': 'value'
    }
  },

  // Realtime configuration
  realtime: {
    autoConnect: false,         // Auto-connect on first subscription
    reconnect: true,            // Auto-reconnect on disconnect
    reconnectDelay: 1000,       // Initial reconnect delay in ms
    maxReconnectDelay: 30000    // Maximum reconnect delay in ms
  }
})
```

## Authentication

### User Registration & Login

```typescript
// Register a new user
const { user, session } = await sb.auth.register({
  email: 'user@example.com',
  password: 'securepassword',
  metadata: { name: 'John Doe' }
})

// Login
const { user, session } = await sb.auth.login({
  email: 'user@example.com',
  password: 'securepassword'
})

// Get current user
const user = await sb.auth.getUser()

// Get current session (synchronous)
const session = sb.auth.getSession()

// Check if authenticated
if (sb.auth.isAuthenticated()) {
  console.log('User is logged in')
}

// Logout
await sb.auth.logout()
```

### Admin Authentication

```typescript
// Login as admin
const { admin, session } = await sb.auth.admin.login({
  username: 'admin',
  password: 'adminpassword'
})

// Get current admin
const admin = await sb.auth.admin.getAdmin()
```

### Auth State Changes

```typescript
// Listen to auth state changes
const unsubscribe = sb.auth.onAuthStateChange((event, session) => {
  switch (event) {
    case 'SIGNED_IN':
      console.log('User signed in')
      break
    case 'SIGNED_OUT':
      console.log('User signed out')
      break
    case 'TOKEN_REFRESHED':
      console.log('Token was refreshed')
      break
    case 'SESSION_EXPIRED':
      console.log('Session expired, please log in again')
      break
  }
})

// Stop listening
unsubscribe()
```

## Queries

### Fluent Query Builder

```typescript
// Find multiple documents
const products = await sb.collection('products')
  .where({ price: { $gte: 50 }, active: true })
  .orderBy('created_at', 'desc')
  .limit(20)
  .offset(0)
  .select(['id', 'name', 'price'])
  .find()

// Find one document
const product = await sb.collection('products')
  .where({ _id: 'product_123' })
  .findOne()

// Create document
const newProduct = await sb.collection('products')
  .create({
    name: 'New Product',
    price: 99.99,
    active: true
  })

// Update documents
const { modified } = await sb.collection('products')
  .where({ _id: 'product_123' })
  .update({
    $set: { price: 149.99 },
    $push: { tags: 'sale' }
  })

// Delete documents
const { deleted } = await sb.collection('products')
  .where({ active: false })
  .delete()

// Count documents
const count = await sb.collection('products')
  .where({ active: true })
  .count()
```

### Query Operators

```typescript
// Comparison operators
.where({ price: { $eq: 100 } })     // Equal
.where({ price: { $ne: 100 } })     // Not equal
.where({ price: { $gt: 50 } })      // Greater than
.where({ price: { $gte: 50 } })     // Greater than or equal
.where({ price: { $lt: 100 } })     // Less than
.where({ price: { $lte: 100 } })    // Less than or equal
.where({ status: { $in: ['active', 'pending'] } })   // In array
.where({ status: { $nin: ['deleted'] } })            // Not in array
.where({ tags: { $exists: true } }) // Field exists
.where({ name: { $regex: '^Pro' } }) // Regex match

// Logical operators
.where({ $and: [{ price: { $gte: 50 } }, { active: true }] })
.where({ $or: [{ status: 'active' }, { featured: true }] })
.where({ $not: { status: 'deleted' } })
```

### Bulk Operations

```typescript
const results = await sb.collection('products')
  .bulk([
    { action: 'create', data: { name: 'Product 1', price: 50 } },
    { action: 'create', data: { name: 'Product 2', price: 75 } },
    { action: 'update', where: { _id: 'x' }, data: { $set: { active: false } } },
    { action: 'delete', where: { status: 'deleted' } }
  ])
```

### Raw Queries

```typescript
// Execute raw query (matches server API directly)
const result = await sb.query({
  action: 'find',
  collection: 'products',
  query: {
    where: { price: { $gte: 50 } },
    orderBy: { created_at: 'desc' },
    limit: 20
  }
})

// Custom registered query
const topSellers = await sb.customQuery('getTopSellingProducts', {
  limit: 10,
  category: 'electronics'
})
```

### Type-Safe Queries

```typescript
// Define your types
interface Product {
  id: string
  name: string
  price: number
  active: boolean
  createdAt: string
}

// Use generics for type-safe results
const products = await sb.collection<Product>('products').find()
// products is typed as Product[]

const product = await sb.collection<Product>('products')
  .where({ _id: 'product_123' })
  .findOne()
// product is typed as Product | null
```

## Realtime Subscriptions

### Callback Style

```typescript
// Subscribe to collection events
const unsubscribe = sb.realtime.subscribe('products', (event) => {
  console.log(event.type)       // 'create' | 'update' | 'delete'
  console.log(event.document)   // The affected document
  console.log(event.documentId) // Document ID
  console.log(event.timestamp)  // Event timestamp
})

// Subscribe to specific document
const unsubscribe = sb.realtime.subscribe('products', 'product_123', (event) => {
  console.log('Document changed:', event)
})

// Unsubscribe
unsubscribe()
```

### Event Emitter Style

```typescript
const channel = sb.realtime.channel('products')
  .on('create', (doc) => console.log('Created:', doc))
  .on('update', (doc) => console.log('Updated:', doc))
  .on('delete', (doc) => console.log('Deleted:', doc))
  .on('error', (err) => console.error('Error:', err))
  .subscribe()

// Unsubscribe
channel.unsubscribe()
```

### Connection Management

```typescript
// Manual connection control
sb.realtime.connect()
sb.realtime.disconnect()

// Get current status
const status = sb.realtime.getStatus()
// 'connecting' | 'connected' | 'disconnected' | 'reconnecting' | 'error'

// Listen to status changes
sb.realtime.onStatusChange((status) => {
  console.log('Connection status:', status)
})
```

## File Storage

### Upload Files

```typescript
// Basic upload
const file = await sb.storage.upload(fileInput.files[0])

// Upload with progress tracking
const file = await sb.storage.upload(fileInput.files[0], {
  onProgress: (progress) => {
    console.log(`${progress.loaded}/${progress.total} bytes`)
    console.log(`${progress.percentage}%`)
  }
})

// Upload with abort support
const controller = new AbortController()
const file = await sb.storage.upload(fileInput.files[0], {
  signal: controller.signal
})
// To abort: controller.abort()

// Upload with metadata
const file = await sb.storage.upload(fileInput.files[0], {
  metadata: { description: 'Product image', category: 'images' }
})
```

### Download & Access Files

```typescript
// Get file info
const fileInfo = await sb.storage.getFile('file_id')
console.log(fileInfo.filename, fileInfo.size, fileInfo.contentType)

// Get file URL (for direct access in img src, etc.)
const url = sb.storage.getFileUrl('file_id')

// Download file content
const data = await sb.storage.download('file_id')
// Browser: data is Blob
// Node.js: data is ArrayBuffer
```

### List & Delete Files

```typescript
// List files
const { files, total } = await sb.storage.list()

// Search files
const { files } = await sb.storage.list({ search: 'product' })

// Paginate
const { files } = await sb.storage.list({ limit: 20, offset: 40 })

// Delete file
await sb.storage.delete('file_id')
```

## Collections Management (Admin)

Collections management requires admin authentication.

```typescript
// Login as admin first
await sb.auth.admin.login({ username: 'admin', password: 'password' })

// List all collections
const collections = await sb.collections.list()

// Get collection info
const collection = await sb.collections.get('products')

// Create collection
const orders = await sb.collections.create({
  name: 'orders',
  schema: {
    customerId: { type: 'string', required: true },
    total: { type: 'number', required: true },
    status: { type: 'string', default: 'pending' }
  },
  indexes: {
    customer_idx: { fields: ['customerId'] }
  }
})

// Update collection
await sb.collections.update('orders', {
  schema: { /* updated schema */ }
})

// Get collection statistics
const stats = await sb.collections.stats('products')
console.log(`Documents: ${stats.documentCount}`)
console.log(`Storage: ${stats.storageSize} bytes`)

// Delete collection (careful!)
await sb.collections.delete('old_orders')
```

## Error Handling

```typescript
import {
  SwiftBaseError,
  AuthError,
  QueryError,
  NetworkError,
  NotFoundError,
  ValidationError
} from '@swiftbase/sdk'

try {
  await sb.collection('products').find()
} catch (error) {
  if (error instanceof AuthError) {
    // 401/403 - Authentication failed
    switch (error.code) {
      case 'INVALID_CREDENTIALS':
        console.log('Wrong email or password')
        break
      case 'TOKEN_EXPIRED':
        console.log('Session expired')
        break
      case 'UNAUTHORIZED':
        console.log('Please log in')
        break
      case 'FORBIDDEN':
        console.log('Access denied')
        break
    }
  } else if (error instanceof QueryError) {
    // 400 - Query failed
    console.log('Query error:', error.code, error.message)
  } else if (error instanceof NetworkError) {
    // Network issue
    switch (error.code) {
      case 'TIMEOUT':
        console.log('Request timed out')
        break
      case 'NETWORK_ERROR':
        console.log('Check your connection')
        break
      case 'ABORTED':
        console.log('Request was cancelled')
        break
    }
  } else if (error instanceof NotFoundError) {
    // 404 - Resource not found
    console.log('Not found:', error.message)
  } else if (error instanceof ValidationError) {
    // 400 - Validation failed
    for (const fieldError of error.errors) {
      console.log(`${fieldError.field}: ${fieldError.message}`)
    }
  } else if (error instanceof SwiftBaseError) {
    // Any other SwiftBase error
    console.log('Error:', error.status, error.code, error.message)
  }
}
```

## Request Interceptors

```typescript
// Add request interceptor
sb.interceptors.request.use((config) => {
  console.log('Request:', config.method, config.url)
  // Modify config if needed
  return config
})

// Add response interceptor
sb.interceptors.response.use(
  (response) => {
    console.log('Response:', response.status)
    return response
  },
  (error) => {
    console.error('Error:', error)
    throw error
  }
)
```

## TypeScript Support

All types are exported for use in your code:

```typescript
import type {
  // Client config
  SwiftBaseConfig,
  AuthConfig,
  RequestConfig,
  RealtimeConfig,

  // Auth types
  User,
  Admin,
  Session,
  AuthResponse,
  AuthEvent,

  // Query types
  WhereClause,
  QueryOptions,
  UpdateOperators,
  QueryResponse,

  // Realtime types
  RealtimeStatus,
  RealtimeEvent,
  EventType,

  // Storage types
  FileMetadata,
  UploadProgress,
  UploadOptions,

  // Collection types
  Collection,
  CollectionSchema,
  CollectionStats
} from '@swiftbase/sdk'
```

## Browser & Node.js Support

The SDK works in all modern environments:

- **Browsers**: Chrome, Firefox, Safari, Edge (last 2 versions)
- **Node.js**: 18+
- **Edge Runtimes**: Cloudflare Workers, Vercel Edge, Deno

### Storage Adapters

Choose the appropriate storage for your environment:

```typescript
// Browser - localStorage (persists across sessions)
const sb = createClient({
  url: 'http://localhost:8090',
  auth: { storage: 'localStorage' }
})

// Browser - sessionStorage (cleared on tab close)
const sb = createClient({
  url: 'http://localhost:8090',
  auth: { storage: 'sessionStorage' }
})

// Node.js / Edge - memory storage (no persistence)
const sb = createClient({
  url: 'http://localhost:8090',
  auth: { storage: 'memory' }
})

// Custom storage adapter
const sb = createClient({
  url: 'http://localhost:8090',
  auth: {
    storage: {
      get: (key) => redis.get(key),
      set: (key, value) => redis.set(key, value),
      remove: (key) => redis.del(key)
    }
  }
})
```

## API Reference

For detailed API documentation, see the [TypeDoc generated docs](./docs/api/index.html).

## License

MIT
