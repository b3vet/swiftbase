# SwiftBase SDK - React Example

A minimal React app demonstrating all capabilities of the `@swiftbase/sdk`.

## Features Demonstrated

- **Authentication** - User registration, login, logout, admin login, session management
- **Query Builder** - CRUD operations with MongoDB-style queries
- **Realtime** - WebSocket subscriptions with live event updates
- **Storage** - File upload with progress, download, list, delete
- **Collections** - Admin collection management (list, create, stats, delete)

## Setup

```bash
# From the monorepo root
pnpm install

# Start the SwiftBase backend
cd apps/backend
swift run swiftbase serve --port 8090

# In another terminal, start the example app
cd apps/example-react
pnpm dev
```

Open http://localhost:5173

## Usage

1. **Start SwiftBase backend** on port 8090
2. **Auth tab**: Register a new user or use admin login (admin/admin123)
3. **Query tab**: Create, read, update, delete documents in any collection
4. **Realtime tab**: Subscribe to collection changes, then make changes in Query tab to see events
5. **Storage tab**: Upload files, view list, download, delete
6. **Collections tab**: (Admin only) Manage database collections

## Project Structure

```
example-react/
├── src/
│   ├── main.tsx      # React entry point
│   ├── App.tsx       # Main app with all SDK demos
│   ├── index.css     # Styling
│   └── vite-env.d.ts # Vite types
├── index.html        # HTML entry
├── package.json      # Dependencies
├── tsconfig.json     # TypeScript config
└── vite.config.ts    # Vite config with API proxy
```

## SDK Usage Patterns

### Initialize Client

```tsx
import { createClient } from '@swiftbase/sdk'

const sb = createClient({
  url: 'http://localhost:8090',
  auth: { storage: 'localStorage', autoRefresh: true },
  realtime: { autoConnect: true, reconnect: true },
})
```

### Authentication

```tsx
await sb.auth.login({ email, password })
await sb.auth.register({ email, password })
await sb.auth.admin.login({ username, password })
await sb.auth.logout()
```

### Queries

```tsx
const docs = await sb.collection('products')
  .where({ active: true })
  .orderBy('createdAt', 'desc')
  .limit(10)
  .find()
```

### Realtime

```tsx
const unsubscribe = sb.realtime.subscribe('products', (event) => {
  console.log(event.type, event.document)
})
```

### Storage

```tsx
const file = await sb.storage.upload(fileBlob, {
  onProgress: (p) => console.log(p.percentage),
})
```
