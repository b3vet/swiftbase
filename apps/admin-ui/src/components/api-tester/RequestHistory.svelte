<script lang="ts">
  import { Button } from '@components/common'

  interface SavedRequest {
    id: string
    name: string
    method: string
    endpoint: string
    headers: Array<{ key: string; value: string; enabled: boolean }>
    queryParams: Array<{ key: string; value: string; enabled: boolean }>
    body: string
    useAuth: boolean
    createdAt: Date
  }

  interface Props {
    requests?: SavedRequest[]
    onLoad?: (request: SavedRequest) => void
    onDelete?: (requestId: string) => void
  }

  let { requests = [], onLoad, onDelete }: Props = $props()

  let searchTerm = $state('')

  const filteredRequests = $derived.by(() => {
    if (!searchTerm) return requests

    const term = searchTerm.toLowerCase()
    return requests.filter(
      (req) =>
        req.name.toLowerCase().includes(term) ||
        req.method.toLowerCase().includes(term) ||
        req.endpoint.toLowerCase().includes(term)
    )
  })

  function getMethodColor(method: string): string {
    switch (method) {
      case 'GET':
        return 'bg-success-100 text-success-800'
      case 'POST':
        return 'bg-primary-100 text-primary-800'
      case 'PUT':
        return 'bg-warning-100 text-warning-800'
      case 'PATCH':
        return 'bg-info-100 text-info-800'
      case 'DELETE':
        return 'bg-danger-100 text-danger-800'
      default:
        return 'bg-secondary-100 text-secondary-800'
    }
  }

  function formatDate(date: Date): string {
    const now = new Date()
    const diffMs = now.getTime() - new Date(date).getTime()
    const diffMins = Math.floor(diffMs / 60000)
    const diffHours = Math.floor(diffMs / 3600000)
    const diffDays = Math.floor(diffMs / 86400000)

    if (diffMins < 1) return 'Just now'
    if (diffMins < 60) return `${diffMins} min ago`
    if (diffHours < 24) return `${diffHours} hours ago`
    if (diffDays < 7) return `${diffDays} days ago`

    return new Date(date).toLocaleDateString()
  }

  function handleLoad(request: SavedRequest) {
    if (onLoad) {
      onLoad(request)
    }
  }

  function handleDelete(requestId: string) {
    if (onDelete) {
      onDelete(requestId)
    }
  }
</script>

<div class="space-y-4">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <h3 class="text-lg font-semibold text-secondary-900">Saved Requests</h3>
    <span class="text-sm text-secondary-600">{requests.length} saved</span>
  </div>

  <!-- Search -->
  {#if requests.length > 0}
    <div class="relative">
      <svg
        class="absolute left-3 top-1/2 -translate-y-1/2 h-5 w-5 text-secondary-400"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
        />
      </svg>
      <input
        type="text"
        bind:value={searchTerm}
        placeholder="Search requests..."
        class="w-full pl-10 pr-4 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
      />
    </div>
  {/if}

  <!-- Request List -->
  <div class="space-y-2 max-h-96 overflow-y-auto">
    {#if filteredRequests.length === 0}
      <div class="text-center py-8">
        {#if requests.length === 0}
          <svg
            class="mx-auto h-12 w-12 text-secondary-400"
            fill="none"
            viewBox="0 0 24 24"
            stroke="currentColor"
          >
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10"
            />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-secondary-900">No Saved Requests</h3>
          <p class="mt-1 text-sm text-secondary-500">
            Save your API requests to access them later
          </p>
        {:else}
          <p class="text-sm text-secondary-500">No requests match your search</p>
        {/if}
      </div>
    {:else}
      {#each filteredRequests as request (request.id)}
        <div
          class="group p-4 bg-white border border-secondary-200 rounded-lg hover:border-primary-300 hover:shadow-sm transition-all"
        >
          <div class="flex items-start justify-between">
            <div
              class="flex-1 cursor-pointer"
              onclick={() => handleLoad(request)}
              role="button"
              tabindex="0"
              onkeydown={(e) => e.key === 'Enter' && handleLoad(request)}
            >
              <div class="flex items-center space-x-2">
                <span class="px-2 py-1 text-xs font-semibold rounded {getMethodColor(request.method)}">
                  {request.method}
                </span>
                <h4 class="text-sm font-medium text-secondary-900">{request.name}</h4>
              </div>
              <p class="mt-1 text-sm text-secondary-600 truncate">{request.endpoint}</p>
              <div class="mt-2 flex items-center space-x-4 text-xs text-secondary-500">
                <span>{formatDate(request.createdAt)}</span>
                {#if request.useAuth}
                  <span class="flex items-center">
                    <svg class="h-3 w-3 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path
                        stroke-linecap="round"
                        stroke-linejoin="round"
                        stroke-width="2"
                        d="M12 15v2m-6 4h12a2 2 0 002-2v-6a2 2 0 00-2-2H6a2 2 0 00-2 2v6a2 2 0 002 2zm10-10V7a4 4 0 00-8 0v4h8z"
                      />
                    </svg>
                    Auth
                  </span>
                {/if}
                {#if request.headers.filter((h) => h.enabled && h.key).length > 0}
                  <span>{request.headers.filter((h) => h.enabled && h.key).length} headers</span>
                {/if}
                {#if request.queryParams.filter((q) => q.enabled && q.key).length > 0}
                  <span>{request.queryParams.filter((q) => q.enabled && q.key).length} params</span>
                {/if}
              </div>
            </div>

            <!-- Delete Button -->
            <button
              type="button"
              aria-label="Delete request"
              onclick={() => handleDelete(request.id)}
              class="opacity-0 group-hover:opacity-100 p-2 text-danger-600 hover:bg-danger-50 rounded-lg transition-opacity"
            >
              <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16"
                />
              </svg>
            </button>
          </div>
        </div>
      {/each}
    {/if}
  </div>
</div>
