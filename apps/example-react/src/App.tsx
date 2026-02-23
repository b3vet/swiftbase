import { useState, useEffect, useRef } from 'react'
import {
  createClient,
  type SwiftBaseClient,
  type User,
  type RealtimeEvent,
  type FileMetadata,
  type Collection,
} from '@swiftbase/sdk'

// Initialize SDK client
const sb = createClient({
  url: 'http://localhost:8090',
  auth: {
    storage: 'localStorage',
    autoRefresh: true,
  },
  realtime: {
    autoConnect: true,
    reconnect: true,
  },
})

type Tab = 'auth' | 'query' | 'realtime' | 'storage' | 'collections'

// Helper to serialize errors properly
function formatData(data: unknown): string {
  if (data instanceof Error) {
    const err = data as Error & { status?: number; code?: string; details?: unknown }
    return JSON.stringify(
      {
        name: err.name,
        message: err.message,
        status: err.status,
        code: err.code,
        details: err.details,
      },
      null,
      2
    )
  }
  return JSON.stringify(data, null, 2)
}

interface Document {
  id: string
  name: string
  price?: number
  active?: boolean
  createdAt: string
  updatedAt: string
}

export default function App() {
  const [activeTab, setActiveTab] = useState<Tab>('auth')
  const [user, setUser] = useState<User | null>(null)
  const [isAdmin, setIsAdmin] = useState(false)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    // Initialize and restore session
    sb.ready().then(async () => {
      const session = sb.auth.getSession()
      if (session?.user) {
        setUser(session.user)
      } else if (session?.admin) {
        setIsAdmin(true)
      }
      setLoading(false)
    })

    // Listen to auth changes
    const unsubscribe = sb.auth.onAuthStateChange((event, session) => {
      if (event === 'SIGNED_IN') {
        if (session?.user) setUser(session.user)
        if (session?.admin) setIsAdmin(true)
      } else if (event === 'SIGNED_OUT') {
        setUser(null)
        setIsAdmin(false)
      }
    })

    return () => unsubscribe()
  }, [])

  if (loading) {
    return <div className="loading">Loading...</div>
  }

  const tabs: { id: Tab; label: string }[] = [
    { id: 'auth', label: 'Auth' },
    { id: 'query', label: 'Query' },
    { id: 'realtime', label: 'Realtime' },
    { id: 'storage', label: 'Storage' },
    { id: 'collections', label: 'Collections' },
  ]

  return (
    <div className="app">
      <header>
        <h1>SwiftBase SDK Demo</h1>
        <div className="user-status">
          {user ? (
            <span>Logged in as: {user.email}</span>
          ) : isAdmin ? (
            <span>Logged in as Admin</span>
          ) : (
            <span>Not logged in</span>
          )}
        </div>
      </header>

      <nav>
        {tabs.map((tab) => (
          <button
            key={tab.id}
            className={activeTab === tab.id ? 'active' : ''}
            onClick={() => setActiveTab(tab.id)}
          >
            {tab.label}
          </button>
        ))}
      </nav>

      <main>
        {activeTab === 'auth' && <AuthDemo sb={sb} user={user} isAdmin={isAdmin} />}
        {activeTab === 'query' && <QueryDemo sb={sb} />}
        {activeTab === 'realtime' && <RealtimeDemo sb={sb} />}
        {activeTab === 'storage' && <StorageDemo sb={sb} />}
        {activeTab === 'collections' && <CollectionsDemo sb={sb} isAdmin={isAdmin} />}
      </main>
    </div>
  )
}

// ============ AUTH DEMO ============
function AuthDemo({ sb, user, isAdmin }: { sb: SwiftBaseClient; user: User | null; isAdmin: boolean }) {
  const [email, setEmail] = useState('test@example.com')
  const [password, setPassword] = useState('password123')
  const [adminUser, setAdminUser] = useState('admin')
  const [adminPass, setAdminPass] = useState('admin123')
  const [output, setOutput] = useState('')

  const log = (msg: string, data?: unknown) => {
    const text = data !== undefined ? `${msg}\n${formatData(data)}` : msg
    setOutput((prev) => `${text}\n\n${prev}`)
  }

  const handleRegister = async () => {
    try {
      const result = await sb.auth.register({ email, password })
      log('Registered successfully:', result)
    } catch (err) {
      log('Register error:', err)
    }
  }

  const handleLogin = async () => {
    try {
      const result = await sb.auth.login({ email, password })
      log('Login successful:', result)
    } catch (err) {
      log('Login error:', err)
    }
  }

  const handleAdminLogin = async () => {
    try {
      const result = await sb.auth.admin.login({ username: adminUser, password: adminPass })
      log('Admin login successful:', result)
    } catch (err) {
      log('Admin login error:', err)
    }
  }

  const handleLogout = async () => {
    await sb.auth.logout()
    log('Logged out')
  }

  const handleGetUser = async () => {
    const currentUser = await sb.auth.getUser()
    log('Current user:', currentUser)
  }

  const handleGetSession = () => {
    const session = sb.auth.getSession()
    log('Current session:', session)
  }

  return (
    <section>
      <h2>Authentication</h2>

      <div className="form-group">
        <h3>User Auth</h3>
        <input placeholder="Email" value={email} onChange={(e) => setEmail(e.target.value)} />
        <input placeholder="Password" type="password" value={password} onChange={(e) => setPassword(e.target.value)} />
        <div className="buttons">
          <button onClick={handleRegister}>Register</button>
          <button onClick={handleLogin}>Login</button>
        </div>
      </div>

      <div className="form-group">
        <h3>Admin Auth</h3>
        <input placeholder="Username" value={adminUser} onChange={(e) => setAdminUser(e.target.value)} />
        <input placeholder="Password" type="password" value={adminPass} onChange={(e) => setAdminPass(e.target.value)} />
        <button onClick={handleAdminLogin}>Admin Login</button>
      </div>

      <div className="buttons">
        <button onClick={handleGetUser}>Get User</button>
        <button onClick={handleGetSession}>Get Session</button>
        <button onClick={handleLogout} disabled={!user && !isAdmin}>
          Logout
        </button>
      </div>

      <pre className="output">{output || 'Output will appear here...'}</pre>
    </section>
  )
}

// ============ QUERY DEMO ============
function QueryDemo({ sb }: { sb: SwiftBaseClient }) {
  const [collection, setCollection] = useState('products')
  const [output, setOutput] = useState('')

  const log = (msg: string, data?: unknown) => {
    const text = data !== undefined ? `${msg}\n${formatData(data)}` : msg
    setOutput((prev) => `${text}\n\n${prev}`)
  }

  const handleFind = async () => {
    try {
      const docs = await sb.collection<Document>(collection).limit(10).find()
      log('Find result:', docs)
    } catch (err) {
      log('Find error:', err)
    }
  }

  const handleFindWithFilter = async () => {
    try {
      const docs = await sb
        .collection<Document>(collection)
        .where({ active: true })
        .orderBy('createdAt', 'desc')
        .limit(5)
        .find()
      log('Find with filter:', docs)
    } catch (err) {
      log('Find error:', err)
    }
  }

  const handleCreate = async () => {
    try {
      const doc = await sb.collection<Document>(collection).create({
        name: `Item ${Date.now()}`,
        price: Math.floor(Math.random() * 100),
        active: true,
      })
      log('Created:', doc)
    } catch (err) {
      log('Create error:', err)
    }
  }

  const handleUpdate = async () => {
    try {
      const result = await sb
        .collection<Document>(collection)
        .where({ active: true })
        .update({ $set: { active: false } })
      log('Updated:', result)
    } catch (err) {
      log('Update error:', err)
    }
  }

  const handleCount = async () => {
    try {
      const count = await sb.collection(collection).count()
      log('Count:', { count })
    } catch (err) {
      log('Count error:', err)
    }
  }

  const handleDelete = async () => {
    try {
      const result = await sb.collection(collection).where({ active: false }).delete()
      log('Deleted:', result)
    } catch (err) {
      log('Delete error:', err)
    }
  }

  return (
    <section>
      <h2>Query Builder</h2>

      <div className="form-group">
        <input placeholder="Collection name" value={collection} onChange={(e) => setCollection(e.target.value)} />
      </div>

      <div className="buttons">
        <button onClick={handleFind}>Find All</button>
        <button onClick={handleFindWithFilter}>Find Active</button>
        <button onClick={handleCreate}>Create</button>
        <button onClick={handleUpdate}>Update Active → Inactive</button>
        <button onClick={handleCount}>Count</button>
        <button onClick={handleDelete}>Delete Inactive</button>
      </div>

      <pre className="output">{output || 'Output will appear here...'}</pre>
    </section>
  )
}

// ============ REALTIME DEMO ============
function RealtimeDemo({ sb }: { sb: SwiftBaseClient }) {
  const [collection, setCollection] = useState('products')
  const [events, setEvents] = useState<RealtimeEvent[]>([])
  const [status, setStatus] = useState(sb.realtime.getStatus())
  const [isSubscribed, setIsSubscribed] = useState(false)
  const [output, setOutput] = useState('')
  const [lastCreatedId, setLastCreatedId] = useState<string | null>(null)
  const unsubRef = useRef<(() => void) | null>(null)

  const log = (msg: string, data?: unknown) => {
    const text = data !== undefined ? `${msg}\n${formatData(data)}` : msg
    setOutput((prev) => `${text}\n\n${prev}`)
  }

  useEffect(() => {
    const unsub = sb.realtime.onStatusChange(setStatus)
    return () => unsub()
  }, [sb])

  const handleSubscribe = () => {
    if (unsubRef.current) return
    unsubRef.current = sb.realtime.subscribe(collection, (event) => {
      setEvents((prev) => [event, ...prev].slice(0, 20))
    })
    setIsSubscribed(true)
    log(`Subscribed to "${collection}" collection`)
  }

  const handleUnsubscribe = () => {
    if (unsubRef.current) {
      unsubRef.current()
      unsubRef.current = null
      setIsSubscribed(false)
      log(`Unsubscribed from "${collection}" collection`)
    }
  }

  const handleConnect = () => {
    sb.realtime.connect()
    log('Connecting to WebSocket...')
  }

  const handleDisconnect = () => {
    sb.realtime.disconnect()
    setIsSubscribed(false)
    unsubRef.current = null
    log('Disconnected from WebSocket')
  }

  const clearEvents = () => setEvents([])

  // CRUD operations to test realtime events
  const handleCreate = async () => {
    try {
      const doc = await sb.collection(collection).create({
        name: `Test Item ${Date.now()}`,
        value: Math.floor(Math.random() * 100),
        active: true,
      })
      setLastCreatedId(doc.id)
      log('Created document:', doc)
    } catch (err) {
      log('Create error:', err)
    }
  }

  const handleUpdate = async () => {
    if (!lastCreatedId) {
      log('No document to update. Create one first.')
      return
    }
    try {
      const result = await sb
        .collection(collection)
        .where({ _id: lastCreatedId })
        .update({ $set: { value: Math.floor(Math.random() * 100), updated: true } })
      log('Updated document:', result)
    } catch (err) {
      log('Update error:', err)
    }
  }

  const handleDelete = async () => {
    if (!lastCreatedId) {
      log('No document to delete. Create one first.')
      return
    }
    try {
      const result = await sb.collection(collection).where({ _id: lastCreatedId }).delete()
      log('Deleted document:', result)
      setLastCreatedId(null)
    } catch (err) {
      log('Delete error:', err)
    }
  }

  return (
    <section>
      <h2>Realtime Subscriptions</h2>

      <div className="status-bar">
        <span>
          Connection: <span className={`status ${status}`}>{status}</span>
        </span>
        <span style={{ marginLeft: '20px' }}>
          Subscription: <span className={`status ${isSubscribed ? 'connected' : 'disconnected'}`}>
            {isSubscribed ? `subscribed to "${collection}"` : 'not subscribed'}
          </span>
        </span>
      </div>

      <div className="form-group">
        <input
          placeholder="Collection"
          value={collection}
          onChange={(e) => setCollection(e.target.value)}
          disabled={isSubscribed}
        />
      </div>

      <div className="buttons">
        <button onClick={handleConnect} disabled={status === 'connected'}>Connect</button>
        <button onClick={handleDisconnect} disabled={status === 'disconnected'}>Disconnect</button>
        <button onClick={handleSubscribe} disabled={isSubscribed || status !== 'connected'}>Subscribe</button>
        <button onClick={handleUnsubscribe} disabled={!isSubscribed}>Unsubscribe</button>
        <button onClick={clearEvents}>Clear Events</button>
      </div>

      {/* CRUD Controls */}
      <div className="form-group">
        <h3>Test CRUD Operations</h3>
        <p className="hint">Create, update, or delete documents to see realtime events appear below.</p>
        <div className="buttons">
          <button onClick={handleCreate}>Create Document</button>
          <button onClick={handleUpdate} disabled={!lastCreatedId}>Update Last Created</button>
          <button onClick={handleDelete} disabled={!lastCreatedId}>Delete Last Created</button>
        </div>
        {lastCreatedId && <p className="hint">Last created ID: {lastCreatedId}</p>}
      </div>

      <div className="events">
        <h3>Realtime Events ({events.length})</h3>
        {events.length === 0 ? (
          <p>No events yet. Subscribe and make changes to see events.</p>
        ) : (
          events.map((event, i) => (
            <div key={i} className={`event ${event.type}`}>
              <strong>{event.type}</strong> - {event.collection}/{event.documentId}
              <pre>{JSON.stringify(event.document, null, 2)}</pre>
            </div>
          ))
        )}
      </div>

      <pre className="output">{output || 'Operation log will appear here...'}</pre>
    </section>
  )
}

// ============ STORAGE DEMO ============
function StorageDemo({ sb }: { sb: SwiftBaseClient }) {
  const [files, setFiles] = useState<FileMetadata[]>([])
  const [uploadProgress, setUploadProgress] = useState(0)
  const [output, setOutput] = useState('')
  const fileInputRef = useRef<HTMLInputElement>(null)

  const log = (msg: string, data?: unknown) => {
    const text = data !== undefined ? `${msg}\n${formatData(data)}` : msg
    setOutput((prev) => `${text}\n\n${prev}`)
  }

  const handleUpload = async () => {
    const file = fileInputRef.current?.files?.[0]
    if (!file) return

    try {
      setUploadProgress(0)
      const result = await sb.storage.upload(file, {
        onProgress: (p) => setUploadProgress(p.percentage),
        metadata: { uploadedAt: new Date().toISOString() },
      })
      log('Uploaded:', result)
      setUploadProgress(0)
      handleListFiles()
    } catch (err) {
      log('Upload error:', err)
      setUploadProgress(0)
    }
  }

  const handleListFiles = async () => {
    try {
      const result = await sb.storage.list({ limit: 10 })
      setFiles(result.files)
      log('Listed files:', { total: result.total, files: result.files.length })
    } catch (err) {
      log('List error:', err)
    }
  }

  const handleDownload = async (fileId: string) => {
    try {
      const url = sb.storage.getFileUrl(fileId)
      window.open(url, '_blank')
      log('Opening file URL:', url)
    } catch (err) {
      log('Download error:', err)
    }
  }

  const handleDelete = async (fileId: string) => {
    try {
      await sb.storage.delete(fileId)
      log('Deleted file:', fileId)
      handleListFiles()
    } catch (err) {
      log('Delete error:', err)
    }
  }

  return (
    <section>
      <h2>File Storage</h2>

      <div className="form-group">
        <input type="file" ref={fileInputRef} />
        <button onClick={handleUpload}>Upload</button>
        {uploadProgress > 0 && <progress value={uploadProgress} max={100} />}
      </div>

      <div className="buttons">
        <button onClick={handleListFiles}>List Files</button>
      </div>

      <div className="file-list">
        <h3>Files ({files.length})</h3>
        {files.map((file) => (
          <div key={file.id} className="file-item">
            <span>{file.filename || file.originalName}</span>
            <span>{(file.size / 1024).toFixed(1)} KB</span>
            <button onClick={() => handleDownload(file.id)}>Download</button>
            <button onClick={() => handleDelete(file.id)}>Delete</button>
          </div>
        ))}
      </div>

      <pre className="output">{output || 'Output will appear here...'}</pre>
    </section>
  )
}

// ============ COLLECTIONS DEMO ============
function CollectionsDemo({ sb, isAdmin }: { sb: SwiftBaseClient; isAdmin: boolean }) {
  const [collections, setCollections] = useState<Collection[]>([])
  const [newName, setNewName] = useState('')
  const [output, setOutput] = useState('')

  const log = (msg: string, data?: unknown) => {
    const text = data !== undefined ? `${msg}\n${formatData(data)}` : msg
    setOutput((prev) => `${text}\n\n${prev}`)
  }

  const handleList = async () => {
    try {
      const result = await sb.collections.list()
      setCollections(result)
      log('Collections:', result)
    } catch (err) {
      log('List error:', err)
    }
  }

  const handleCreate = async () => {
    if (!newName.trim()) return
    try {
      const result = await sb.collections.create({
        name: newName,
        schema: {},
      })
      log('Created collection:', result)
      setNewName('')
      handleList()
    } catch (err) {
      log('Create error:', err)
    }
  }

  const handleStats = async (name: string) => {
    try {
      const stats = await sb.collections.stats(name)
      log(`Stats for ${name}:`, stats)
    } catch (err) {
      log('Stats error:', err)
    }
  }

  const handleDelete = async (name: string) => {
    if (!confirm(`Delete collection "${name}"?`)) return
    try {
      await sb.collections.delete(name)
      log('Deleted collection:', name)
      handleList()
    } catch (err) {
      log('Delete error:', err)
    }
  }

  if (!isAdmin) {
    return (
      <section>
        <h2>Collections Management</h2>
        <p className="warning">Admin login required for collection management.</p>
      </section>
    )
  }

  return (
    <section>
      <h2>Collections Management (Admin)</h2>

      <div className="form-group">
        <input placeholder="New collection name" value={newName} onChange={(e) => setNewName(e.target.value)} />
        <button onClick={handleCreate}>Create</button>
      </div>

      <div className="buttons">
        <button onClick={handleList}>List Collections</button>
      </div>

      <div className="collection-list">
        <h3>Collections ({collections.length})</h3>
        {collections.map((col) => (
          <div key={col.name} className="collection-item">
            <span>{col.name}</span>
            <button onClick={() => handleStats(col.name)}>Stats</button>
            <button onClick={() => handleDelete(col.name)}>Delete</button>
          </div>
        ))}
      </div>

      <pre className="output">{output || 'Output will appear here...'}</pre>
    </section>
  )
}
