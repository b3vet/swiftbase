# Component Documentation

Complete reference for all reusable components in SwiftBase Admin UI.

## Common Components (`src/components/common/`)

### Button

**File**: `Button.svelte`

Reusable button component with multiple variants and sizes.

**Props:**
```typescript
{
  variant?: 'primary' | 'outline' | 'danger' = 'primary'
  size?: 'sm' | 'md' | 'lg' = 'md'
  disabled?: boolean = false
  type?: 'button' | 'submit' | 'reset' = 'button'
  onclick?: () => void
}
```

**Usage:**
```svelte
<Button variant="primary" onclick={handleClick}>
  Click Me
</Button>
```

**Variants:**
- `primary` - Blue background, white text
- `outline` - White background, border, colored text
- `danger` - Red background, white text

---

### Modal

**File**: `Modal.svelte`

Configurable modal dialog with backdrop.

**Props:**
```typescript
{
  open: boolean = $bindable(false)
  title?: string
  size?: 'sm' | 'md' | 'lg' | 'xl' = 'md'
  showCloseButton?: boolean = true
  onclose?: () => void
}
```

**Snippets:**
- `footer()` - Modal footer content

**Usage:**
```svelte
<Modal bind:open={showModal} title="Edit User" size="md">
  <!-- Modal content -->

  {#snippet footer()}
    <Button onclick={() => showModal = false}>Cancel</Button>
    <Button variant="primary" onclick={handleSave}>Save</Button>
  {/snippet}
</Modal>
```

---

### Alert

**File**: `Alert.svelte`

Notification alert with different types and dismissible option.

**Props:**
```typescript
{
  type?: 'success' | 'error' | 'warning' | 'info' = 'info'
  dismissible?: boolean = false
  ondismiss?: () => void
}
```

**Usage:**
```svelte
<Alert type="success" dismissible ondismiss={handleDismiss}>
  Operation completed successfully!
</Alert>
```

---

### Spinner

**File**: `Spinner.svelte`

Loading spinner with multiple sizes.

**Props:**
```typescript
{
  size?: 'sm' | 'md' | 'lg' | 'xl' = 'md'
}
```

**Usage:**
```svelte
<Spinner size="lg" />
```

---

### Badge

**File**: `Badge.svelte`

Status badge with color variants.

**Props:**
```typescript
{
  variant?: 'success' | 'warning' | 'danger' | 'info' | 'secondary' = 'secondary'
}
```

**Usage:**
```svelte
<Badge variant="success">Active</Badge>
```

---

### Card

**File**: `Card.svelte`

Content container with optional header and footer.

**Props:**
```typescript
{
  title?: string
  subtitle?: string
}
```

**Snippets:**
- `header()` - Custom header content
- `footer()` - Card footer content

**Usage:**
```svelte
<Card title="Statistics">
  <p>Content goes here</p>
</Card>
```

---

### Table

**File**: `Table.svelte`

Data table with sorting support.

**Props:**
```typescript
{
  headers: Array<{ key: string; label: string; sortable?: boolean }>
  data: Array<any>
  onSort?: (key: string) => void
}
```

**Usage:**
```svelte
<Table headers={tableHeaders} data={tableData} onSort={handleSort} />
```

---

## Layout Components (`src/components/layout/`)

### Layout

**File**: `Layout.svelte`

Main layout wrapper with navbar and sidebar.

**Props:** None

**Usage:**
```svelte
<Layout>
  <!-- Page content -->
</Layout>
```

---

### Navbar

**File**: `Navbar.svelte`

Top navigation bar with logo and user menu.

**Features:**
- Logo and brand name
- Mobile menu toggle
- User profile dropdown
- Logout functionality

---

### Sidebar

**File**: `Sidebar.svelte`

Side navigation menu with collapsible sections.

**Features:**
- Navigation links with icons
- Active route highlighting
- Collapsible on mobile
- Backdrop overlay on mobile

**Nav Items:**
- Dashboard
- Collections
- Query Explorer
- Users
- Files
- Realtime Monitor
- API Tester
- Settings

---

## Collection Components (`src/components/collections/`)

### CollectionList

**File**: `CollectionList.svelte`

Display collections in grid or list view.

**Props:**
```typescript
{
  collections: Collection[]
  viewMode?: 'grid' | 'list' = 'grid'
  onSelect?: (collection: Collection) => void
}
```

---

### CollectionForm

**File**: `CollectionForm.svelte`

Form for creating/editing collections.

**Props:**
```typescript
{
  collection?: Collection
  onSave?: (data: CollectionData) => void
  onCancel?: () => void
}
```

**Features:**
- Name input
- Schema editor (JSON)
- Indexes configuration
- Options editor (JSON)
- JSON validation
- Format JSON button

---

### CollectionDetail

**File**: `CollectionDetail.svelte`

Display detailed collection information.

**Props:**
```typescript
{
  collection: Collection
  onEdit?: () => void
  onDelete?: () => void
}
```

---

## Document Components (`src/components/documents/`)

### DocumentList

**File**: `DocumentList.svelte`

List documents in table format.

**Props:**
```typescript
{
  documents: Document[]
  onSelect?: (document: Document) => void
  onEdit?: (document: Document) => void
  onDelete?: (documentId: string) => void
}
```

---

### DocumentEditor

**File**: `DocumentEditor.svelte`

JSON editor for documents.

**Props:**
```typescript
{
  document?: Document
  onSave?: (data: any) => void
  onCancel?: () => void
}
```

**Features:**
- JSON syntax editor
- Validation
- Format button
- Auto-generate ID toggle

---

## Query Components (`src/components/query/`)

### QueryEditor

**File**: `QueryEditor.svelte`

MongoDB query builder.

**Props:**
```typescript
{
  collections: string[]
  onExecute?: (query: QueryData) => void
  onSave?: (query: SavedQuery) => void
}
```

**Features:**
- Collection selector
- Action selector (find, findOne, count, aggregate)
- Query editor (JSON)
- Projection, sort, limit, skip fields
- Data editor for insert/update

---

### QueryResults

**File**: `QueryResults.svelte`

Display query execution results.

**Props:**
```typescript
{
  results: any[]
  format?: 'table' | 'json' = 'table'
  executionTime?: number
}
```

---

### SavedQueries

**File**: `SavedQueries.svelte`

Manage saved queries.

**Props:**
```typescript
{
  queries: SavedQuery[]
  onLoad?: (query: SavedQuery) => void
  onDelete?: (queryId: string) => void
}
```

---

## User Components (`src/components/users/`)

### UserList

**File**: `UserList.svelte`

Display users in table format.

**Props:**
```typescript
{
  users: User[]
  onSelect?: (user: User) => void
}
```

**Features:**
- Search by email/ID
- Filter by verification status
- Email verified badges

---

### UserForm

**File**: `UserForm.svelte`

Form for creating/editing users.

**Props:**
```typescript
{
  user?: User
  onSave?: (data: UserData) => void
  onCancel?: () => void
}
```

---

### UserDetail

**File**: `UserDetail.svelte`

Display user profile details.

**Props:**
```typescript
{
  user: User
  onEdit?: () => void
  onDelete?: () => void
  onVerify?: () => void
}
```

---

## File Components (`src/components/files/`)

### FileUploader

**File**: `FileUploader.svelte`

Drag-and-drop file upload.

**Props:**
```typescript
{
  onUpload?: (files: File[]) => void
  maxSize?: number = 100 * 1024 * 1024  // 100MB
  multiple?: boolean = true
}
```

**Features:**
- Drag-and-drop zone
- File picker button
- Size validation
- Multiple file support

---

### FileList

**File**: `FileList.svelte`

Display files in grid view.

**Props:**
```typescript
{
  files: FileInfo[]
  onPreview?: (file: FileInfo) => void
  onDownload?: (file: FileInfo) => void
  onDelete?: (fileId: string) => void
}
```

**Features:**
- Responsive grid (1-4 columns)
- Image thumbnails
- File type icons
- Search files

---

### FilePreview

**File**: `FilePreview.svelte`

Preview files in modal.

**Props:**
```typescript
{
  file: FileInfo
  onClose?: () => void
}
```

**Supported Types:**
- Images (img tag)
- Videos (video player)
- Audio (audio player)
- Fallback download link

---

## Realtime Components (`src/components/realtime/`)

### ConnectionStatus

**File**: `ConnectionStatus.svelte`

WebSocket connection status indicator.

**Props:**
```typescript
{
  status: ConnectionStatus
  lastPing?: Date
}
```

**Status Types:**
- Disconnected
- Connecting
- Connected
- Reconnecting

---

### SubscriptionManager

**File**: `SubscriptionManager.svelte`

Manage realtime subscriptions.

**Props:**
```typescript
{
  subscriptions: Subscription[]
  collections: string[]
  onSubscribe?: (data: SubscriptionData) => void
  onUnsubscribe?: (subscriptionId: string) => void
}
```

---

### EventFeed

**File**: `EventFeed.svelte`

Live event stream display.

**Props:**
```typescript
{
  events: RealtimeEvent[]
  onEventClick?: (event: RealtimeEvent) => void
}
```

**Features:**
- Event type badges
- Search events
- Filter by type
- Newest first ordering

---

### EventDetail

**File**: `EventDetail.svelte`

Detailed event inspector.

**Props:**
```typescript
{
  event: RealtimeEvent
  onClose?: () => void
}
```

---

## API Tester Components (`src/components/api-tester/`)

### RequestBuilder

**File**: `RequestBuilder.svelte`

Build HTTP requests.

**Props:**
```typescript
{
  method: string = $bindable('GET')
  endpoint: string = $bindable('')
  headers: KeyValue[] = $bindable([])
  queryParams: KeyValue[] = $bindable([])
  body: string = $bindable('')
  useAuth: boolean = $bindable(true)
  onSend?: (request: RequestData) => void
}
```

**Features:**
- Method selector
- Endpoint input
- Tabbed interface (params, headers, body)
- JSON editor for body
- Format JSON button

---

### ResponseViewer

**File**: `ResponseViewer.svelte`

Display API responses.

**Props:**
```typescript
{
  status?: number
  statusText?: string
  headers?: Record<string, string>
  body?: string
  responseTime?: number
  responseSize?: number
  onCopy?: () => void
}
```

---

### RequestHistory

**File**: `RequestHistory.svelte`

Saved requests management.

**Props:**
```typescript
{
  requests: SavedRequest[]
  onLoad?: (request: SavedRequest) => void
  onDelete?: (requestId: string) => void
}
```

---

## Settings Components (`src/components/settings/`)

### ThemeSettings

**File**: `ThemeSettings.svelte`

Appearance customization.

**Features:**
- Theme mode selector
- Sidebar position selector
- Density selector
- Font size slider
- Reset button

---

### UserPreferences

**File**: `UserPreferences.svelte`

User preferences configuration.

**Features:**
- Default page selector
- Items per page selector
- Query format selector
- Notifications toggle
- Notification duration slider

---

### SystemInfo

**File**: `SystemInfo.svelte`

System information display.

**Features:**
- Version information
- Server status
- Database statistics
- Browser information
- Refresh button

---

## Usage Guidelines

### Importing Components

```typescript
// Common components
import { Button, Modal, Alert, Spinner } from '@components/common'

// Specific domain components
import { CollectionList, CollectionForm } from '@components/collections'
import { DocumentEditor } from '@components/documents'
```

### Component Patterns

**1. Bindable Props**

Use `$bindable()` for two-way data binding:
```svelte
let value = $state('')
<Input bind:value />
```

**2. Event Handlers**

Use callbacks for events:
```svelte
<Button onclick={handleClick}>Save</Button>
```

**3. Snippets**

Use snippets for customizable content:
```svelte
<Modal title="Confirm">
  Are you sure?

  {#snippet footer()}
    <Button>Cancel</Button>
    <Button variant="danger">Delete</Button>
  {/snippet}
</Modal>
```

**4. Conditional Rendering**

```svelte
{#if isLoading}
  <Spinner />
{:else}
  <Content />
{/if}
```

**5. Lists**

```svelte
{#each items as item (item.id)}
  <ItemCard {item} />
{/each}
```

---

## Styling Guidelines

### TailwindCSS Classes

All components use TailwindCSS utility classes:
```svelte
<div class="flex items-center space-x-4">
  <span class="text-sm text-secondary-600">Label</span>
  <Button variant="primary">Action</Button>
</div>
```

### Color Classes

- `primary-*` - Primary actions
- `secondary-*` - Secondary content
- `success-*` - Success states
- `danger-*` - Destructive actions
- `warning-*` - Warnings
- `info-*` - Informational

### Spacing

Use consistent spacing scale:
- `gap-2`, `gap-4`, `gap-6` for flex/grid gaps
- `space-x-2`, `space-y-4` for stack spacing
- `p-4`, `p-6` for padding
- `m-4`, `m-6` for margins

### Responsive Classes

Use breakpoint prefixes:
- `sm:` - 640px+
- `md:` - 768px+
- `lg:` - 1024px+
- `xl:` - 1280px+

```svelte
<div class="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
  <!-- Responsive grid -->
</div>
```

---

## Best Practices

1. **Keep components small and focused**
2. **Use TypeScript for all props**
3. **Provide default values**
4. **Include prop documentation**
5. **Use semantic HTML**
6. **Add ARIA labels for accessibility**
7. **Test with different data**
8. **Handle loading and error states**
9. **Make components reusable**
10. **Follow naming conventions**
