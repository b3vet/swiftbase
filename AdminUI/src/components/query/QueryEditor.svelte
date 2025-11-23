<script lang="ts">
  import type { QueryAction } from '@lib/types'
  import { Button, Alert } from '@components/common'
  import { JSONEditor, Mode } from 'svelte-jsoneditor'
  import { parseJSON } from '@lib/utils'

  interface Props {
    collections: string[]
    onExecute: (query: any) => Promise<void>
    isLoading?: boolean
    loadedQuery?: { action: QueryAction, collection: string, query: any, data?: any } | null
  }

  let {
    collections,
    onExecute,
    isLoading = false,
    loadedQuery = null
  }: Props = $props()

  let selectedCollection = $state('')
  let action = $state<QueryAction>('find')
  let error = $state<string | null>(null)

  // JSONEditor content for query
  let queryContent = $state({
    json: {
      where: {},
      limit: 20
    }
  })

  // JSONEditor content for data (create/update)
  let dataContent = $state({
    json: {}
  })

  // Watch for loaded query changes and update state
  $effect(() => {
    if (loadedQuery) {
      console.log('QueryEditor received loadedQuery:', loadedQuery)
      console.log('Setting collection:', loadedQuery.collection)
      console.log('Setting action:', loadedQuery.action)
      console.log('Setting query:', loadedQuery.query)
      console.log('Setting data:', loadedQuery.data)

      selectedCollection = loadedQuery.collection
      action = loadedQuery.action
      // Handle undefined query by providing a default empty object
      queryContent = { json: loadedQuery.query || {} }
      if (loadedQuery.data) {
        dataContent = { json: loadedQuery.data }
      }
    }
  })

  const actions: QueryAction[] = ['find', 'findOne', 'create', 'update', 'delete', 'count']
  const needsData = $derived(action === 'create' || action === 'update')
  const needsQuery = $derived(action !== 'create')

  function loadExample() {
    const examples: Record<QueryAction, any> = {
      find: {
        where: { active: true },
        orderBy: { created_at: 'desc' },
        limit: 20
      },
      findOne: {
        where: { _id: 'document_id' }
      },
      create: {},
      update: {
        where: { _id: 'document_id' }
      },
      delete: {
        where: { _id: 'document_id' }
      },
      count: {
        where: { active: true }
      },
      aggregate: {
        pipeline: [
          { $match: { status: 'active' } },
          { $group: { _id: '$category', total: { $sum: 1 } } }
        ]
      },
      custom: {
        command: 'db.collection.method(params)'
      }
    }

    queryContent = { json: examples[action] }

    if (needsData) {
      dataContent = {
        json: {
          field: 'value',
          active: true
        }
      }
    }
  }

  async function handleExecute() {
    error = null

    if (!selectedCollection) {
      error = 'Please select a collection'
      return
    }

    try {
      // Get JSON from the editors - parse text mode if needed
      const query = queryContent.text ? JSON.parse(queryContent.text) : queryContent.json
      const data = needsData ? (dataContent.text ? JSON.parse(dataContent.text) : dataContent.json) : undefined

      await onExecute({
        action,
        collection: selectedCollection,
        query,
        data
      })
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to execute query'
    }
  }
</script>

<div class="space-y-4">
  {#if error}
    <Alert type="error" dismissible ondismiss={() => (error = null)}>
      {error}
    </Alert>
  {/if}

  <!-- Collection and Action Selection -->
  <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
    <div>
      <label for="collection-select" class="block text-sm font-medium text-secondary-700 mb-1">
        Collection
      </label>
      <select
        id="collection-select"
        bind:value={selectedCollection}
        class="block w-full rounded-lg border border-secondary-300 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
        disabled={isLoading}
      >
        <option value="">Select a collection</option>
        {#each collections as collection}
          <option value={collection}>{collection}</option>
        {/each}
      </select>
    </div>

    <div>
      <label for="action-select" class="block text-sm font-medium text-secondary-700 mb-1">
        Action
      </label>
      <select
        id="action-select"
        bind:value={action}
        class="block w-full rounded-lg border border-secondary-300 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
        disabled={isLoading}
      >
        {#each actions as actionOption}
          <option value={actionOption}>{actionOption}</option>
        {/each}
      </select>
    </div>
  </div>

  <!-- Query Editor -->
  {#if needsQuery}
    <div>
      <div class="flex items-center justify-between mb-2">
        <label class="block text-sm font-medium text-secondary-700">
          Query (MongoDB Syntax)
        </label>
        <button
          type="button"
          class="text-xs text-primary-600 hover:text-primary-800 font-medium"
          onclick={loadExample}
        >
          Load Example
        </button>
      </div>

      <div class="border border-secondary-300 rounded-lg overflow-hidden" style="height: 300px;">
        <JSONEditor
          bind:content={queryContent}
          mode={Mode.text}
          mainMenuBar={false}
          statusBar={false}
          readOnly={isLoading}
        />
      </div>

      <p class="mt-2 text-xs text-secondary-500">
        Use MongoDB-style query syntax. Operators: $eq, $ne, $gt, $gte, $lt, $lte, $in, $nin, $and, $or, $exists
      </p>
    </div>
  {/if}

  <!-- Data Editor (for create/update) -->
  {#if needsData}
    <div>
      <label class="block text-sm font-medium text-secondary-700 mb-2">
        Data
      </label>

      <div class="border border-secondary-300 rounded-lg overflow-hidden" style="height: 250px;">
        <JSONEditor
          bind:content={dataContent}
          mode={Mode.text}
          mainMenuBar={false}
          statusBar={false}
          readOnly={isLoading}
        />
      </div>
    </div>
  {/if}

  <!-- Execute Button -->
  <div class="flex justify-end">
    <Button
      variant="primary"
      size="lg"
      onclick={handleExecute}
      loading={isLoading}
      disabled={isLoading || !selectedCollection}
    >
      <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M14.752 11.168l-3.197-2.132A1 1 0 0010 9.87v4.263a1 1 0 001.555.832l3.197-2.132a1 1 0 000-1.664z" />
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
      </svg>
      Execute Query
    </Button>
  </div>
</div>

