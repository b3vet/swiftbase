# SwiftBase Admin UI

A modern, feature-rich admin interface for SwiftBase built with Svelte 5, TypeScript, and TailwindCSS.

## ✨ Features

### Core Features
- 🔐 **Authentication** - Secure login with JWT tokens and automatic refresh
- 📊 **Dashboard** - Overview of collections, documents, and system stats
- 📁 **Collection Management** - Full CRUD operations with schema and indexes
- 📄 **Document Management** - Create, read, update, and delete documents
- 🔍 **Query Explorer** - Execute MongoDB-style queries with saved queries
- 👥 **User Management** - Manage users, verify emails, and view profiles
- 📎 **File Browser** - Upload, download, preview, and manage files
- 🔴 **Realtime Monitor** - WebSocket connection with live event streaming
- 🧪 **API Tester** - Test endpoints with custom headers and body
- ⚙️ **Settings** - Customize appearance, preferences, and system info

### UI Features
- 🎨 **Theming** - Light/dark mode with customizable colors
- 📱 **Responsive Design** - Works on desktop, tablet, and mobile
- ♿ **Accessibility** - ARIA labels and keyboard navigation
- 💾 **Persistence** - Settings and preferences saved to localStorage
- 🔔 **Notifications** - Toast notifications for user feedback
- 🎯 **Type Safety** - Full TypeScript coverage

## 🚀 Getting Started

### Prerequisites

- Node.js 18+ and pnpm
- SwiftBase backend server running

### Installation

```bash
cd AdminUI
pnpm install
```

### Development

Run the development server:

```bash
pnpm dev
```

The admin UI will be available at `http://localhost:5173`

### Production Build

Build for production:

```bash
pnpm build
```

Build output: `../Sources/SwiftBase/Resources/Public/`

The built assets are automatically bundled with the Swift binary.

### Type Checking

Run TypeScript type checking:

```bash
pnpm check
```

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the `AdminUI` directory:

```env
VITE_API_URL=http://localhost:8090
```

### Vite Configuration

- **Base Path**: `/` (hash-based routing)
- **Output**: `../Sources/SwiftBase/Resources/Public/`
- **Path Aliases**:
  - `@/*` → `src/*`
  - `@components/*` → `src/components/*`
  - `@lib/*` → `src/lib/*`
  - `@routes/*` → `src/routes/*`

### TailwindCSS

Custom color scheme configured for SwiftBase:
- **Primary**: Blue (#3B82F6)
- **Secondary**: Slate (#64748B)
- **Success**: Green (#10B981)
- **Warning**: Amber (#F59E0B)
- **Danger**: Red (#EF4444)
- **Info**: Cyan (#06B6D4)

## 📁 Project Structure

```
AdminUI/
├── src/
│   ├── components/          # Reusable UI components
│   │   ├── common/         # Common components (Button, Modal, etc.)
│   │   ├── layout/         # Layout components (Navbar, Sidebar)
│   │   ├── collections/    # Collection-related components
│   │   ├── documents/      # Document-related components
│   │   ├── query/          # Query explorer components
│   │   ├── users/          # User management components
│   │   ├── files/          # File browser components
│   │   ├── realtime/       # Realtime monitor components
│   │   ├── api-tester/     # API tester components
│   │   └── settings/       # Settings components
│   ├── routes/             # Route components (pages)
│   │   ├── Login.svelte
│   │   ├── Dashboard.svelte
│   │   ├── Collections.svelte
│   │   ├── Documents.svelte
│   │   ├── QueryExplorer.svelte
│   │   ├── Users.svelte
│   │   ├── Files.svelte
│   │   ├── Realtime.svelte
│   │   ├── APITester.svelte
│   │   └── Settings.svelte
│   ├── lib/                # Core functionality
│   │   ├── api/           # API client and endpoints
│   │   ├── stores/        # Svelte stores
│   │   ├── types/         # TypeScript types
│   │   ├── utils/         # Utility functions
│   │   └── router.svelte.ts # Hash-based router
│   ├── App.svelte         # Root component
│   └── main.ts            # Entry point
├── public/                # Static assets
├── index.html            # HTML template
├── vite.config.ts        # Vite configuration
├── tailwind.config.js    # TailwindCSS configuration
├── tsconfig.json         # TypeScript configuration
└── package.json          # Dependencies and scripts
```

## 🔑 Key Components

### Authentication

- JWT-based authentication with access and refresh tokens
- Automatic token refresh on expiry (401 handling)
- Protected routes with auth guards
- Persistent login state in localStorage

### Collection Management

- List all collections with search and view modes (grid/list)
- Create collections with optional schema, indexes, and options
- Update collection metadata
- Delete collections with confirmation
- View collection statistics and document counts

### Document Management

- Full CRUD operations on documents
- JSON editor with syntax validation and formatting
- Bulk operations support
- Pagination and search
- Field filtering and sorting

### Query Explorer

- Execute MongoDB-style queries (find, findOne, count, aggregate)
- Save and load queries with names
- Query history with localStorage persistence
- Result formatting (table/JSON)
- Support for all MongoDB operators

### User Management

- List users with search and filtering
- Create and update users with email and metadata
- Delete users with confirmation
- Verify email addresses manually
- View user profiles and metadata

### File Management

- Drag-and-drop file upload with progress
- File preview for images, videos, and audio
- Download files
- Delete files with confirmation
- Copy file URLs to clipboard
- Display file metadata (size, type, upload date)

### Realtime Monitor

- WebSocket connection status indicator
- Live event streaming (create, update, delete)
- Subscribe to collections or specific documents
- Event filtering and search
- Event detail inspection with JSON viewer
- Auto-reconnect with exponential backoff

### API Tester

- Test any API endpoint with custom configuration
- HTTP method selection (GET, POST, PUT, PATCH, DELETE)
- Query parameters editor with enable/disable toggles
- Headers editor with custom headers
- JSON request body editor with formatting
- Response viewer with status, headers, and body
- Save and load requests
- Request history with search

### Settings

- **Appearance**: Theme mode (light/dark), sidebar position (left/right), display density (comfortable/compact), font size (12-20px)
- **Preferences**: Default page on login, items per page, query result format, notifications toggle, notification duration
- **System Info**: Version information, server status, database statistics, browser information

## 🎨 Design System

### Colors

All components use the custom TailwindCSS color palette with semantic naming:
- `primary-*` - Primary brand colors
- `secondary-*` - Secondary colors for text and backgrounds
- `success-*` - Success states
- `warning-*` - Warning states
- `danger-*` - Error and destructive actions
- `info-*` - Informational states

### Components

Reusable component library:
- **Button** - Primary, outline, and danger variants
- **Modal** - Configurable modals with header, body, and footer
- **Alert** - Dismissible alerts with type variants
- **Spinner** - Loading indicators in multiple sizes
- **Badge** - Status and label badges
- **Card** - Content containers
- **Table** - Data tables with sorting support

### Typography

- Base font: System UI fonts
- Headings: Bold with size variants
- Body text: Regular weight
- Code: Monospace font family

## 🔌 API Integration

The admin UI integrates with SwiftBase API via a centralized API client:

```typescript
// Example usage
import { apiClient } from '@lib/api'

// GET request
const response = await apiClient.get('/api/collections')

// POST request
const response = await apiClient.post('/api/collections', {
  name: 'users',
  schema: {}
})
```

### Features

- Automatic authentication header injection
- Token refresh on 401 responses
- Request/response interceptors
- Type-safe responses
- Error handling
- Timeout support

## 📦 State Management

Uses Svelte 5 stores with runes:

- **authStore** - Authentication state and user info
- **collectionsStore** - Collections data and cache
- **themeStore** - Theme preferences and UI state
- **notificationsStore** - Toast notifications queue
- **settingsStore** - User preferences

All stores persist to localStorage for state restoration.

## 🌐 Browser Support

- Chrome/Edge 90+
- Firefox 88+
- Safari 14+

## 📊 Build Size

Production build metrics:
- **JavaScript**: ~212 KB (51 KB gzipped)
- **CSS**: ~28 KB (5.4 KB gzipped)
- **HTML**: ~0.6 KB (0.3 KB gzipped)

Total: ~240 KB (57 KB gzipped)

## 🧪 Tech Stack

- **Svelte**: 5.43.5 (with runes)
- **TypeScript**: 5.9.3
- **Vite**: 7.2.2
- **TailwindCSS**: 3.x
- **PostCSS**: 8.5.6

## 🔗 Integration with SwiftBase

The built UI is automatically embedded in the SwiftBase binary via Swift Package Manager resources:

```swift
.resources([
    .copy("Resources/Public")
])
```

Access the admin UI at: `http://localhost:8090/` (or configured base URL)

## 🤝 Contributing

This is part of the SwiftBase project. See the main repository for contribution guidelines.

## 📝 License

Part of the SwiftBase project. See the main repository for license information.

## 🙏 Credits

Built with ❤️ using:
- [Svelte 5](https://svelte.dev/) - Reactive UI framework
- [TailwindCSS](https://tailwindcss.com/) - Utility-first CSS
- [Vite](https://vitejs.dev/) - Build tool
- [TypeScript](https://www.typescriptlang.org/) - Type safety
