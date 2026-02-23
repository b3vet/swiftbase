<script lang="ts">
  import { onMount } from 'svelte'
  import { RequestBuilder, ResponseViewer, RequestHistory } from '@components/api-tester'
  import { Button, Modal, Alert } from '@components/common'
  import { notificationsStore } from '@lib/stores'
  import { apiClient } from '@lib/api'
  import { generateId, storage } from '@lib/utils'

  interface KeyValue {
    key: string
    value: string
    enabled: boolean
  }

  interface SavedRequest {
    id: string
    name: string
    method: string
    endpoint: string
    headers: KeyValue[]
    queryParams: KeyValue[]
    body: string
    useAuth: boolean
    createdAt: Date
  }

  // Request state
  let method = $state('GET')
  let endpoint = $state('/api/collections')
  let headers = $state<KeyValue[]>([])
  let queryParams = $state<KeyValue[]>([])
  let body = $state('')
  let useAuth = $state(true)

  // Response state
  let responseStatus = $state<number | undefined>(undefined)
  let responseStatusText = $state<string | undefined>(undefined)
  let responseHeaders = $state<Record<string, string>>({})
  let responseBody = $state('')
  let responseTime = $state<number | undefined>(undefined)
  let responseSize = $state<number | undefined>(undefined)

  // UI state
  let isLoading = $state(false)
  let error = $state<string | null>(null)
  let showSaveModal = $state(false)
  let requestName = $state('')
  let savedRequests = $state<SavedRequest[]>([])

  const STORAGE_KEY = 'api_tester_requests'

  onMount(() => {
    loadSavedRequests()
  })

  function loadSavedRequests() {
    const saved = storage.get<SavedRequest[]>(STORAGE_KEY) || []
    // Convert createdAt strings back to Date objects
    savedRequests = saved.map((req) => ({
      ...req,
      createdAt: new Date(req.createdAt)
    }))
  }

  function saveSavedRequests() {
    storage.set(STORAGE_KEY, savedRequests)
  }

  async function handleSend(request: {
    method: string
    endpoint: string
    headers: KeyValue[]
    queryParams: KeyValue[]
    body: string
    useAuth: boolean
  }) {
    error = null
    isLoading = true

    const startTime = performance.now()

    try {
      // Build URL with base and query params
      const baseUrl = import.meta.env.VITE_API_URL || 'http://localhost:8090'
      let url = `${baseUrl}${request.endpoint}`

      // Add query parameters
      if (request.queryParams.length > 0) {
        const params = new URLSearchParams()
        request.queryParams.forEach((param) => {
          params.append(param.key, param.value)
        })
        url += `?${params.toString()}`
      }

      // Build headers
      const requestHeaders: Record<string, string> = {}

      // Add custom headers
      request.headers.forEach((header) => {
        requestHeaders[header.key] = header.value
      })

      // Add auth header if enabled
      if (request.useAuth) {
        const token = apiClient.getAccessToken()
        if (token) {
          requestHeaders['Authorization'] = `Bearer ${token}`
        }
      }

      // Add content-type if not specified and body exists
      if (request.body && !requestHeaders['Content-Type']) {
        requestHeaders['Content-Type'] = 'application/json'
      }

      // Make request
      const fetchOptions: RequestInit = {
        method: request.method,
        headers: requestHeaders
      }

      // Add body for non-GET/DELETE requests
      if (request.body && request.method !== 'GET' && request.method !== 'DELETE') {
        fetchOptions.body = request.body
      }

      const response = await fetch(url, fetchOptions)
      const endTime = performance.now()

      // Extract response headers
      const resHeaders: Record<string, string> = {}
      response.headers.forEach((value, key) => {
        resHeaders[key] = value
      })

      // Get response body
      const contentType = response.headers.get('content-type')
      let resBody = ''

      if (contentType?.includes('application/json')) {
        const json = await response.json()
        resBody = JSON.stringify(json)
      } else {
        resBody = await response.text()
      }

      // Update response state
      responseStatus = response.status
      responseStatusText = response.statusText
      responseHeaders = resHeaders
      responseBody = resBody
      responseTime = Math.round(endTime - startTime)
      responseSize = new Blob([resBody]).size

      notificationsStore.success('Request completed')
    } catch (err) {
      const errorMessage = err instanceof Error ? err.message : 'Request failed'
      error = errorMessage
      notificationsStore.error(errorMessage)

      // Reset response state on error
      responseStatus = undefined
      responseStatusText = undefined
      responseHeaders = {}
      responseBody = ''
      responseTime = undefined
      responseSize = undefined
    } finally {
      isLoading = false
    }
  }

  function handleSaveRequest() {
    showSaveModal = true
    requestName = `${method} ${endpoint}`
  }

  function saveRequest() {
    if (!requestName.trim()) {
      notificationsStore.error('Please enter a name for the request')
      return
    }

    const savedRequest: SavedRequest = {
      id: generateId(),
      name: requestName.trim(),
      method,
      endpoint,
      headers: [...headers],
      queryParams: [...queryParams],
      body,
      useAuth,
      createdAt: new Date()
    }

    savedRequests = [savedRequest, ...savedRequests]
    saveSavedRequests()

    showSaveModal = false
    requestName = ''

    notificationsStore.success('Request saved successfully')
  }

  function handleLoadRequest(request: SavedRequest) {
    method = request.method
    endpoint = request.endpoint
    headers = [...request.headers]
    queryParams = [...request.queryParams]
    body = request.body
    useAuth = request.useAuth

    notificationsStore.success('Request loaded')
  }

  function handleDeleteRequest(requestId: string) {
    savedRequests = savedRequests.filter((req) => req.id !== requestId)
    saveSavedRequests()
    notificationsStore.success('Request deleted')
  }

  function handleCopyResponse() {
    notificationsStore.success('Response copied to clipboard')
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-3xl font-bold text-secondary-900">API Tester</h1>
      <p class="mt-2 text-secondary-600">Test API endpoints and inspect responses</p>
    </div>
    <Button variant="outline" onclick={handleSaveRequest}>
      <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4"
        />
      </svg>
      Save Request
    </Button>
  </div>

  <!-- Error Alert -->
  {#if error}
    <Alert type="error" dismissible ondismiss={() => (error = null)}>
      {error}
    </Alert>
  {/if}

  <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
    <!-- Request Builder & History -->
    <div class="lg:col-span-2 space-y-6">
      <!-- Request Builder -->
      <div class="bg-white border border-secondary-200 rounded-lg p-6">
        <h2 class="text-lg font-semibold text-secondary-900 mb-4">Request</h2>
        <RequestBuilder
          bind:method
          bind:endpoint
          bind:headers
          bind:queryParams
          bind:body
          bind:useAuth
          onSend={handleSend}
        />
      </div>

      <!-- Response Viewer -->
      <div class="bg-white border border-secondary-200 rounded-lg p-6">
        <h2 class="text-lg font-semibold text-secondary-900 mb-4">Response</h2>
        {#if isLoading}
          <div class="flex items-center justify-center py-12">
            <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
            <span class="ml-3 text-secondary-600">Sending request...</span>
          </div>
        {:else}
          <ResponseViewer
            status={responseStatus}
            statusText={responseStatusText}
            headers={responseHeaders}
            body={responseBody}
            responseTime={responseTime}
            responseSize={responseSize}
            onCopy={handleCopyResponse}
          />
        {/if}
      </div>
    </div>

    <!-- Request History -->
    <div class="lg:col-span-1">
      <div class="bg-white border border-secondary-200 rounded-lg p-6 sticky top-6">
        <RequestHistory
          requests={savedRequests}
          onLoad={handleLoadRequest}
          onDelete={handleDeleteRequest}
        />
      </div>
    </div>
  </div>
</div>

<!-- Save Request Modal -->
<Modal bind:open={showSaveModal} title="Save Request" size="md">
  <div class="space-y-4">
    <div>
      <label for="requestName" class="block text-sm font-medium text-secondary-700 mb-1">
        Request Name
      </label>
      <input
        type="text"
        id="requestName"
        bind:value={requestName}
        placeholder="Enter a name for this request"
        class="w-full px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
      />
    </div>

    <div class="bg-secondary-50 p-3 rounded-lg text-sm text-secondary-700">
      <p><strong>Method:</strong> {method}</p>
      <p><strong>Endpoint:</strong> {endpoint}</p>
    </div>
  </div>

  {#snippet footer()}
    <div class="flex justify-end space-x-3">
      <Button variant="outline" onclick={() => (showSaveModal = false)}>Cancel</Button>
      <Button variant="primary" onclick={saveRequest}>Save</Button>
    </div>
  {/snippet}
</Modal>
