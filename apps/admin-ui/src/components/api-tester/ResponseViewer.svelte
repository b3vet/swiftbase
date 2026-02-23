<script lang="ts">
  import { Button, JsonViewer } from '@components/common'

  interface Props {
    status?: number
    statusText?: string
    headers?: Record<string, string>
    body?: string
    responseTime?: number
    responseSize?: number
    onCopy?: () => void
  }

  let {
    status,
    statusText,
    headers = {},
    body = '',
    responseTime,
    responseSize,
    onCopy
  }: Props = $props()

  let activeTab = $state<'body' | 'headers'>('body')

  const statusColor = $derived.by(() => {
    if (!status) return 'secondary'
    if (status >= 200 && status < 300) return 'success'
    if (status >= 300 && status < 400) return 'warning'
    if (status >= 400 && status < 500) return 'danger'
    if (status >= 500) return 'danger'
    return 'secondary'
  })

  const parsedBody = $derived.by(() => {
    if (!body) return null
    try {
      return JSON.parse(body)
    } catch {
      return null
    }
  })

  function formatBytes(bytes: number): string {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round(bytes / Math.pow(k, i) * 100) / 100 + ' ' + sizes[i]
  }

  function handleCopy() {
    navigator.clipboard.writeText(body)
    if (onCopy) {
      onCopy()
    }
  }
</script>

<div class="space-y-4">
  {#if status}
    <!-- Response Meta -->
    <div class="flex items-center justify-between p-4 bg-secondary-50 rounded-lg">
      <div class="flex items-center space-x-4">
        <!-- Status Code -->
        <div class="flex items-center space-x-2">
          <span class="text-sm font-medium text-secondary-700">Status:</span>
          <span
            class="px-3 py-1 text-sm font-semibold rounded-full {statusColor === 'success'
              ? 'bg-success-100 text-success-800'
              : statusColor === 'warning'
                ? 'bg-warning-100 text-warning-800'
                : statusColor === 'danger'
                  ? 'bg-danger-100 text-danger-800'
                  : 'bg-secondary-100 text-secondary-800'}"
          >
            {status} {statusText || ''}
          </span>
        </div>

        <!-- Response Time -->
        {#if responseTime !== undefined}
          <div class="flex items-center space-x-2">
            <span class="text-sm font-medium text-secondary-700">Time:</span>
            <span class="text-sm text-secondary-900">{responseTime}ms</span>
          </div>
        {/if}

        <!-- Response Size -->
        {#if responseSize !== undefined}
          <div class="flex items-center space-x-2">
            <span class="text-sm font-medium text-secondary-700">Size:</span>
            <span class="text-sm text-secondary-900">{formatBytes(responseSize)}</span>
          </div>
        {/if}
      </div>

      <!-- Copy Button -->
      <Button variant="outline" onclick={handleCopy} size="sm" disabled={!body}>
        <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z"
          />
        </svg>
        Copy Response
      </Button>
    </div>

    <!-- Response Content -->
    <div class="border border-secondary-200 rounded-lg overflow-hidden">
      <!-- Tabs -->
      <div class="flex border-b border-secondary-200 bg-secondary-50">
        <button
          type="button"
          class="px-4 py-2 text-sm font-medium {activeTab === 'body'
            ? 'text-primary-600 border-b-2 border-primary-600'
            : 'text-secondary-700 hover:bg-secondary-100'}"
          onclick={() => (activeTab = 'body')}
        >
          Response Body
        </button>
        <button
          type="button"
          class="px-4 py-2 text-sm font-medium {activeTab === 'headers'
            ? 'text-primary-600 border-b-2 border-primary-600'
            : 'text-secondary-700 hover:bg-secondary-100'}"
          onclick={() => (activeTab = 'headers')}
        >
          Headers ({Object.keys(headers).length})
        </button>
      </div>

      <!-- Tab Content -->
      <div class="p-4">
        {#if activeTab === 'body'}
          <!-- Response Body -->
          {#if parsedBody !== null}
            <JsonViewer data={parsedBody} theme="dark" maxHeight="24rem" />
          {:else if body}
            <pre class="bg-secondary-900 text-secondary-100 p-4 rounded-lg overflow-x-auto text-sm font-mono max-h-96 overflow-y-auto">{body}</pre>
          {:else}
            <p class="text-sm text-secondary-500 text-center py-8">No response body</p>
          {/if}
        {:else if activeTab === 'headers'}
          <!-- Response Headers -->
          {#if Object.keys(headers).length > 0}
            <div class="space-y-2">
              {#each Object.entries(headers) as [key, value]}
                <div class="flex items-start space-x-2 py-2 border-b border-secondary-200 last:border-0">
                  <span class="text-sm font-medium text-secondary-700 w-1/3">{key}:</span>
                  <span class="text-sm text-secondary-900 w-2/3 break-all">{value}</span>
                </div>
              {/each}
            </div>
          {:else}
            <p class="text-sm text-secondary-500 text-center py-8">No response headers</p>
          {/if}
        {/if}
      </div>
    </div>
  {:else}
    <!-- Empty State -->
    <div class="border-2 border-dashed border-secondary-300 rounded-lg p-12">
      <div class="text-center">
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
            d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z"
          />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-secondary-900">No Response</h3>
        <p class="mt-1 text-sm text-secondary-500">Send a request to see the response here</p>
      </div>
    </div>
  {/if}
</div>
