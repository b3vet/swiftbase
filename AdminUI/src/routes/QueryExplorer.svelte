<script lang="ts">
  import { onMount } from 'svelte'
  import type { SavedQuery } from '@lib/types'
  import { savedQueryToQueryRequest } from '@lib/types'
  import { collectionsStore, notificationsStore } from '@lib/stores'
  import { queryApi } from '@lib/api'
  import * as savedQueriesApi from '@lib/api/savedQueries'
  import { Card, Modal, Button, Input, Textarea, Alert } from '@components/common'
  import { QueryEditor, QueryResults, SavedQueries } from '@components/query'

  let isExecuting = $state(false)
  let queryResult = $state<any>(null)
  let executionTime = $state<number | undefined>(undefined)
  let savedQueries = $state<SavedQuery[]>([])
  let isLoadingSavedQueries = $state(false)
  let showSaveModal = $state(false)
  let currentQuery = $state<any>(null)
  let loadedQuery = $state<any>(null)

  // Save query form
  let saveName = $state('')
  let saveDescription = $state('')
  let saveError = $state<string | null>(null)

  const collectionNames = $derived(
    collectionsStore.collections.map((c) => c.name)
  )

  onMount(async () => {
    await collectionsStore.fetchAll()
    await loadSavedQueries()
  })

  async function loadSavedQueries() {
    isLoadingSavedQueries = true
    try {
      savedQueries = await savedQueriesApi.getSavedQueries()
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to load saved queries'
      notificationsStore.error(message)
      savedQueries = []
    } finally {
      isLoadingSavedQueries = false
    }
  }

  async function handleExecute(query: any) {
    isExecuting = true
    queryResult = null
    executionTime = undefined

    try {
      const startTime = performance.now()

      const response = await queryApi.execute(query)

      const endTime = performance.now()
      executionTime = endTime - startTime

      if (response.success) {
        // Pass the full response data (includes data, count, etc.) to QueryResults
        const { success, ...resultData } = response
        queryResult = resultData
        currentQuery = query
        notificationsStore.success('Query executed successfully')
      } else {
        notificationsStore.error(response.error || 'Query execution failed')
        queryResult = { error: response.error || 'Query execution failed' }
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Query execution failed'
      notificationsStore.error(message)
      queryResult = { error: message }
    } finally {
      isExecuting = false
    }
  }

  function openSaveModal() {
    if (!currentQuery) {
      notificationsStore.error('Execute a query first before saving')
      return
    }

    saveName = ''
    saveDescription = ''
    saveError = null
    showSaveModal = true
  }

  async function handleSaveQuery() {
    if (!saveName.trim()) {
      saveError = 'Query name is required'
      return
    }

    if (!currentQuery) {
      saveError = 'No query to save'
      return
    }

    try {
      const createRequest: savedQueriesApi.CreateSavedQueryRequest = {
        name: saveName,
        description: saveDescription || undefined,
        collection_id: currentQuery.collection,
        action: currentQuery.action,
        query: currentQuery.query || {},
        data: currentQuery.data
      }

      const newQuery = await savedQueriesApi.createSavedQuery(createRequest)
      savedQueries = [...savedQueries, newQuery]

      showSaveModal = false
      notificationsStore.success('Query saved successfully')
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to save query'
      saveError = message
      notificationsStore.error(message)
    }
  }

  function handleLoadQuery(query: SavedQuery) {
    // Convert SavedQuery to QueryRequest format for the editor
    const queryRequest = savedQueryToQueryRequest(query)

    // Set the loaded query which will trigger the editor to update
    loadedQuery = queryRequest
    notificationsStore.info(`Loaded query: ${query.name}`)
  }

  async function handleDeleteQuery(query: SavedQuery) {
    try {
      await savedQueriesApi.deleteSavedQuery(query.name)
      savedQueries = savedQueries.filter((q) => q.id !== query.id)
      notificationsStore.success('Query deleted')
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete query'
      notificationsStore.error(message)
    }
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-3xl font-bold text-secondary-900">Query Explorer</h1>
      <p class="mt-2 text-secondary-600">
        Execute MongoDB-style queries against your collections
      </p>
    </div>
    <div class="flex space-x-3">
      {#if currentQuery}
        <Button variant="outline" onclick={openSaveModal}>
          <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 7H5a2 2 0 00-2 2v9a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-3m-1 4l-3 3m0 0l-3-3m3 3V4" />
          </svg>
          Save Query
        </Button>
      {/if}
    </div>
  </div>

  {#if collectionsStore.collections.length === 0}
    <!-- No Collections State -->
    <Card>
      <div class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-secondary-900">No collections</h3>
        <p class="mt-1 text-sm text-secondary-500">
          Create a collection first to start querying data
        </p>
      </div>
    </Card>
  {:else}
    <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
      <!-- Main Query Editor (2/3 width) -->
      <div class="lg:col-span-2 space-y-6">
        <!-- Query Editor -->
        <Card title="Query Editor" subtitle="Write and execute MongoDB-style queries">
          <QueryEditor
            collections={collectionNames}
            onExecute={handleExecute}
            isLoading={isExecuting}
            loadedQuery={loadedQuery}
          />
        </Card>

        <!-- Query Results -->
        {#if queryResult}
          <QueryResults result={queryResult} {executionTime} />
        {/if}
      </div>

      <!-- Saved Queries Sidebar (1/3 width) -->
      <div class="space-y-6">
        <SavedQueries
          queries={savedQueries}
          onLoad={handleLoadQuery}
          onDelete={handleDeleteQuery}
        />

        <!-- Query Examples Card -->
        <Card title="Query Examples">
          <div class="space-y-4 text-sm">
            <div>
              <h4 class="font-medium text-secondary-900 mb-1">Find documents</h4>
              <pre class="bg-secondary-50 p-2 rounded text-xs overflow-x-auto">
<code>{JSON.stringify({
  where: { active: true },
  limit: 20
}, null, 2)}</code>
              </pre>
            </div>

            <div>
              <h4 class="font-medium text-secondary-900 mb-1">Query operators</h4>
              <pre class="bg-secondary-50 p-2 rounded text-xs overflow-x-auto">
<code>{JSON.stringify({
  where: {
    price: { $gte: 10, $lte: 100 },
    category: { $in: ['books', 'electronics'] }
  }
}, null, 2)}</code>
              </pre>
            </div>

            <div>
              <h4 class="font-medium text-secondary-900 mb-1">Sort and limit</h4>
              <pre class="bg-secondary-50 p-2 rounded text-xs overflow-x-auto">
<code>{JSON.stringify({
  orderBy: { created_at: 'desc' },
  limit: 10,
  offset: 0
}, null, 2)}</code>
              </pre>
            </div>
          </div>
        </Card>
      </div>
    </div>
  {/if}
</div>

<!-- Save Query Modal -->
<Modal
  bind:open={showSaveModal}
  title="Save Query"
  size="md"
  onclose={() => (showSaveModal = false)}
>
  <div class="space-y-4">
    {#if saveError}
      <Alert type="error" dismissible ondismiss={() => (saveError = null)}>
        {saveError}
      </Alert>
    {/if}

    <Input
      type="text"
      label="Query Name"
      bind:value={saveName}
      placeholder="My Custom Query"
      required
    />

    <Textarea
      label="Description (Optional)"
      bind:value={saveDescription}
      placeholder="Brief description of what this query does"
      rows={3}
    />

    <div class="flex justify-end space-x-3">
      <Button variant="ghost" onclick={() => (showSaveModal = false)}>
        Cancel
      </Button>
      <Button variant="primary" onclick={handleSaveQuery}>
        Save Query
      </Button>
    </div>
  </div>
</Modal>
