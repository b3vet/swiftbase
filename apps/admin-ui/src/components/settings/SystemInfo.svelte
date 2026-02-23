<script lang="ts">
  import { onMount } from 'svelte'
  import { apiClient } from '@lib/api'
  import { Spinner } from '@components/common'

  interface SystemStats {
    version: string
    uptime: number
    collections: number
    documents: number
    users: number
    storage: number
  }

  let isLoading = $state(true)
  let stats = $state<SystemStats | null>(null)
  let error = $state<string | null>(null)

  const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8090'
  const adminVersion = '1.0.0'

  onMount(async () => {
    await loadStats()
  })

  async function loadStats() {
    isLoading = true
    error = null

    try {
      // Try to fetch system stats from API
      const response = await apiClient.get<SystemStats>('/api/admin/stats')

      if (response.success && response.data) {
        stats = response.data
      } else {
        // If stats endpoint doesn't exist, use placeholder data
        stats = {
          version: 'Unknown',
          uptime: 0,
          collections: 0,
          documents: 0,
          users: 0,
          storage: 0
        }
      }
    } catch (err) {
      // Stats endpoint may not be implemented yet
      stats = {
        version: 'Unknown',
        uptime: 0,
        collections: 0,
        documents: 0,
        users: 0,
        storage: 0
      }
    } finally {
      isLoading = false
    }
  }

  function formatUptime(seconds: number): string {
    if (seconds === 0) return 'N/A'

    const days = Math.floor(seconds / 86400)
    const hours = Math.floor((seconds % 86400) / 3600)
    const minutes = Math.floor((seconds % 3600) / 60)

    const parts = []
    if (days > 0) parts.push(`${days}d`)
    if (hours > 0) parts.push(`${hours}h`)
    if (minutes > 0) parts.push(`${minutes}m`)

    return parts.join(' ') || '< 1m'
  }

  function formatBytes(bytes: number): string {
    if (bytes === 0) return '0 Bytes'

    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))

    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }

  function formatNumber(num: number): string {
    return num.toLocaleString()
  }

  async function handleRefresh() {
    await loadStats()
  }
</script>

<div class="space-y-6">
  <!-- Section Header -->
  <div class="flex items-center justify-between">
    <div>
      <h3 class="text-lg font-semibold text-secondary-900">System Information</h3>
      <p class="mt-1 text-sm text-secondary-600">
        Server status and database statistics
      </p>
    </div>
    <button
      type="button"
      onclick={handleRefresh}
      disabled={isLoading}
      class="px-3 py-1.5 text-sm font-medium text-secondary-700 bg-white border border-secondary-300 rounded-lg hover:bg-secondary-50 focus:outline-none focus:ring-2 focus:ring-primary-500 disabled:opacity-50"
    >
      <svg class="h-4 w-4 inline-block mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
        />
      </svg>
      Refresh
    </button>
  </div>

  {#if isLoading}
    <div class="flex justify-center py-8">
      <Spinner size="md" />
    </div>
  {:else if error}
    <div class="p-4 bg-danger-50 border border-danger-200 rounded-lg text-danger-800 text-sm">
      {error}
    </div>
  {:else}
    <!-- Version Information -->
    <div class="bg-white border border-secondary-200 rounded-lg p-4">
      <h4 class="text-sm font-semibold text-secondary-900 mb-3">Version Information</h4>
      <dl class="space-y-2">
        <div class="flex justify-between text-sm">
          <dt class="text-secondary-600">SwiftBase Admin UI</dt>
          <dd class="text-secondary-900 font-medium">{adminVersion}</dd>
        </div>
        <div class="flex justify-between text-sm">
          <dt class="text-secondary-600">SwiftBase Server</dt>
          <dd class="text-secondary-900 font-medium">{stats?.version || 'Unknown'}</dd>
        </div>
        <div class="flex justify-between text-sm">
          <dt class="text-secondary-600">API Endpoint</dt>
          <dd class="text-secondary-900 font-medium text-xs break-all">{apiUrl}</dd>
        </div>
      </dl>
    </div>

    <!-- Server Status -->
    <div class="bg-white border border-secondary-200 rounded-lg p-4">
      <h4 class="text-sm font-semibold text-secondary-900 mb-3">Server Status</h4>
      <dl class="space-y-2">
        <div class="flex justify-between text-sm">
          <dt class="text-secondary-600">Connection</dt>
          <dd class="flex items-center">
            <span class="inline-block w-2 h-2 bg-success-500 rounded-full mr-2"></span>
            <span class="text-secondary-900 font-medium">Connected</span>
          </dd>
        </div>
        <div class="flex justify-between text-sm">
          <dt class="text-secondary-600">Server Uptime</dt>
          <dd class="text-secondary-900 font-medium">
            {formatUptime(stats?.uptime || 0)}
          </dd>
        </div>
      </dl>
    </div>

    <!-- Database Statistics -->
    <div class="bg-white border border-secondary-200 rounded-lg p-4">
      <h4 class="text-sm font-semibold text-secondary-900 mb-3">Database Statistics</h4>
      <dl class="grid grid-cols-2 gap-4">
        <div>
          <dt class="text-xs text-secondary-600 mb-1">Collections</dt>
          <dd class="text-2xl font-bold text-secondary-900">
            {formatNumber(stats?.collections || 0)}
          </dd>
        </div>
        <div>
          <dt class="text-xs text-secondary-600 mb-1">Documents</dt>
          <dd class="text-2xl font-bold text-secondary-900">
            {formatNumber(stats?.documents || 0)}
          </dd>
        </div>
        <div>
          <dt class="text-xs text-secondary-600 mb-1">Users</dt>
          <dd class="text-2xl font-bold text-secondary-900">
            {formatNumber(stats?.users || 0)}
          </dd>
        </div>
        <div>
          <dt class="text-xs text-secondary-600 mb-1">Storage Used</dt>
          <dd class="text-2xl font-bold text-secondary-900">
            {formatBytes(stats?.storage || 0)}
          </dd>
        </div>
      </dl>
    </div>

    <!-- Browser Information -->
    <div class="bg-white border border-secondary-200 rounded-lg p-4">
      <h4 class="text-sm font-semibold text-secondary-900 mb-3">Browser Information</h4>
      <dl class="space-y-2">
        <div class="flex justify-between text-sm">
          <dt class="text-secondary-600">User Agent</dt>
          <dd class="text-secondary-900 font-medium text-xs break-all max-w-xs">
            {navigator.userAgent}
          </dd>
        </div>
        <div class="flex justify-between text-sm">
          <dt class="text-secondary-600">Language</dt>
          <dd class="text-secondary-900 font-medium">{navigator.language}</dd>
        </div>
        <div class="flex justify-between text-sm">
          <dt class="text-secondary-600">Online Status</dt>
          <dd class="text-secondary-900 font-medium">
            {navigator.onLine ? 'Online' : 'Offline'}
          </dd>
        </div>
      </dl>
    </div>
  {/if}
</div>
