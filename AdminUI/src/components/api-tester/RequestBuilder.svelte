<script lang="ts">
  import { Button } from '@components/common'

  interface KeyValue {
    key: string
    value: string
    enabled: boolean
  }

  interface Props {
    method?: string
    endpoint?: string
    headers?: KeyValue[]
    queryParams?: KeyValue[]
    body?: string
    useAuth?: boolean
    onSend?: (request: {
      method: string
      endpoint: string
      headers: KeyValue[]
      queryParams: KeyValue[]
      body: string
      useAuth: boolean
    }) => void
  }

  let {
    method = $bindable('GET'),
    endpoint = $bindable(''),
    headers = $bindable([]),
    queryParams = $bindable([]),
    body = $bindable(''),
    useAuth = $bindable(true),
    onSend
  }: Props = $props()

  const httpMethods = ['GET', 'POST', 'PUT', 'PATCH', 'DELETE']
  let activeTab = $state<'params' | 'headers' | 'body'>('params')

  function addHeader() {
    headers = [...headers, { key: '', value: '', enabled: true }]
  }

  function removeHeader(index: number) {
    headers = headers.filter((_, i) => i !== index)
  }

  function addQueryParam() {
    queryParams = [...queryParams, { key: '', value: '', enabled: true }]
  }

  function removeQueryParam(index: number) {
    queryParams = queryParams.filter((_, i) => i !== index)
  }

  function handleSend() {
    if (onSend) {
      onSend({
        method,
        endpoint,
        headers: headers.filter((h) => h.enabled && h.key),
        queryParams: queryParams.filter((q) => q.enabled && q.key),
        body,
        useAuth
      })
    }
  }

  function formatJson() {
    try {
      const parsed = JSON.parse(body)
      body = JSON.stringify(parsed, null, 2)
    } catch (err) {
      // Invalid JSON, do nothing
    }
  }
</script>

<div class="space-y-6">
  <!-- Request Line -->
  <div class="flex items-center space-x-3">
    <!-- Method Selector -->
    <select
      bind:value={method}
      class="px-4 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
    >
      {#each httpMethods as httpMethod}
        <option value={httpMethod}>{httpMethod}</option>
      {/each}
    </select>

    <!-- Endpoint Input -->
    <input
      type="text"
      bind:value={endpoint}
      placeholder="/api/collections"
      class="flex-1 px-4 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
    />

    <!-- Send Button -->
    <Button variant="primary" onclick={handleSend} disabled={!endpoint}>
      <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M14 5l7 7m0 0l-7 7m7-7H3"
        />
      </svg>
      Send
    </Button>
  </div>

  <!-- Authentication Toggle -->
  <div class="flex items-center space-x-2">
    <input
      type="checkbox"
      id="useAuth"
      bind:checked={useAuth}
      class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 rounded"
    />
    <label for="useAuth" class="text-sm font-medium text-secondary-700">
      Use Authentication Token
    </label>
  </div>

  <!-- Tabs for Query Params, Headers, Body -->
  <div class="border border-secondary-200 rounded-lg overflow-hidden">
    <!-- Tab Headers -->
    <div class="flex border-b border-secondary-200 bg-secondary-50">
      <button
        type="button"
        class="px-4 py-2 text-sm font-medium {activeTab === 'params'
          ? 'text-primary-600 border-b-2 border-primary-600'
          : 'text-secondary-700 hover:bg-secondary-100'}"
        onclick={() => (activeTab = 'params')}
      >
        Query Params ({queryParams.filter((q) => q.enabled && q.key).length})
      </button>
      <button
        type="button"
        class="px-4 py-2 text-sm font-medium {activeTab === 'headers'
          ? 'text-primary-600 border-b-2 border-primary-600'
          : 'text-secondary-700 hover:bg-secondary-100'}"
        onclick={() => (activeTab = 'headers')}
      >
        Headers ({headers.filter((h) => h.enabled && h.key).length})
      </button>
      <button
        type="button"
        class="px-4 py-2 text-sm font-medium {activeTab === 'body'
          ? 'text-primary-600 border-b-2 border-primary-600'
          : 'text-secondary-700 hover:bg-secondary-100'}"
        onclick={() => (activeTab = 'body')}
      >
        Body
      </button>
    </div>

    <!-- Tab Content -->
    <div class="p-4">
      <!-- Query Params Section -->
      {#if activeTab === 'params'}
        <div class="space-y-2">
          {#if queryParams.length === 0}
            <p class="text-sm text-secondary-500 text-center py-4">
              No query parameters. Click "Add Query Param" to add one.
            </p>
          {/if}
          {#each queryParams as param, index}
            <div class="flex items-center space-x-2">
              <input
                type="checkbox"
                bind:checked={param.enabled}
                class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 rounded"
              />
              <input
                type="text"
                bind:value={param.key}
                placeholder="Key"
                class="flex-1 px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
              <input
                type="text"
                bind:value={param.value}
                placeholder="Value"
                class="flex-1 px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
              <button
                type="button"
                aria-label="Remove query parameter"
                onclick={() => removeQueryParam(index)}
                class="p-2 text-danger-600 hover:bg-danger-50 rounded-lg"
              >
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
          {/each}
          <Button variant="outline" onclick={addQueryParam} size="sm">
            <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add Query Param
          </Button>
        </div>
      {/if}

      <!-- Headers Section -->
      {#if activeTab === 'headers'}
        <div class="space-y-2">
          {#if headers.length === 0}
            <p class="text-sm text-secondary-500 text-center py-4">
              No headers. Click "Add Header" to add one.
            </p>
          {/if}
          {#each headers as header, index}
            <div class="flex items-center space-x-2">
              <input
                type="checkbox"
                bind:checked={header.enabled}
                class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 rounded"
              />
              <input
                type="text"
                bind:value={header.key}
                placeholder="Header Name"
                class="flex-1 px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
              <input
                type="text"
                bind:value={header.value}
                placeholder="Value"
                class="flex-1 px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
              />
              <button
                type="button"
                aria-label="Remove header"
                onclick={() => removeHeader(index)}
                class="p-2 text-danger-600 hover:bg-danger-50 rounded-lg"
              >
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path
                    stroke-linecap="round"
                    stroke-linejoin="round"
                    stroke-width="2"
                    d="M6 18L18 6M6 6l12 12"
                  />
                </svg>
              </button>
            </div>
          {/each}
          <Button variant="outline" onclick={addHeader} size="sm">
            <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add Header
          </Button>
        </div>
      {/if}

      <!-- Body Section -->
      {#if activeTab === 'body'}
        <div class="space-y-2">
          <div class="flex justify-end">
            <Button variant="outline" onclick={formatJson} size="sm">
              <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path
                  stroke-linecap="round"
                  stroke-linejoin="round"
                  stroke-width="2"
                  d="M4 6h16M4 12h16m-7 6h7"
                />
              </svg>
              Format JSON
            </Button>
          </div>
          <textarea
            bind:value={body}
            placeholder={'{\n  "key": "value"\n}'}
            class="w-full h-64 px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500 font-mono text-sm"
            disabled={method === 'GET' || method === 'DELETE'}
          ></textarea>
          {#if method === 'GET' || method === 'DELETE'}
            <p class="text-xs text-secondary-500">
              Request body is not supported for {method} requests
            </p>
          {/if}
        </div>
      {/if}
    </div>
  </div>
</div>
