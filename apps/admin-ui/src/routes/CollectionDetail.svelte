<script lang="ts">
  import { onMount } from 'svelte'
  import { router } from '@lib/router.svelte'
  import { collectionsStore } from '@lib/stores'
  import { Card, Badge, Button, Spinner, JsonViewer } from '@components/common'
  import { formatRelativeTime } from '@lib/utils'

  const collectionName = $derived(router.getParam('name') || '')

  let isLoadingStats = $state(false)

  onMount(async () => {
    if (collectionName) {
      await collectionsStore.fetchByName(collectionName)

      isLoadingStats = true
      await collectionsStore.fetchStats(collectionName)
      isLoadingStats = false
    }
  })

  function goBack() {
    router.navigate('/collections')
  }

  function viewDocuments() {
    router.navigate(`/collections/${collectionName}/documents`)
  }
</script>

<div class="space-y-6">
  <!-- Header with Back Button -->
  <div class="flex items-center space-x-4">
    <Button variant="ghost" onclick={goBack}>
      <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
      </svg>
      Back
    </Button>
    <div class="flex-1">
      <h1 class="text-3xl font-bold text-secondary-900">{collectionName}</h1>
      <p class="mt-2 text-secondary-600">Collection details and statistics</p>
    </div>
  </div>

  {#if collectionsStore.isLoading}
    <Card>
      <div class="flex justify-center items-center py-12">
        <Spinner size="lg" />
      </div>
    </Card>
  {:else if collectionsStore.currentCollection}
    <!-- Stats Cards -->
    <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
      <Card padding={false}>
        <div class="p-6">
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <p class="text-sm font-medium text-secondary-600">Documents</p>
              <p class="mt-2 text-3xl font-semibold text-secondary-900">
                {isLoadingStats ? '...' : (collectionsStore.currentStats?.documentCount ?? '0')}
              </p>
            </div>
            <div class="p-3 bg-blue-100 rounded-lg">
              <svg class="h-8 w-8 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
              </svg>
            </div>
          </div>
        </div>
      </Card>

      <Card padding={false}>
        <div class="p-6">
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <p class="text-sm font-medium text-secondary-600">Indexes</p>
              <p class="mt-2 text-3xl font-semibold text-secondary-900">
                {isLoadingStats ? '...' : (collectionsStore.currentStats?.indexCount ?? '0')}
              </p>
            </div>
            <div class="p-3 bg-purple-100 rounded-lg">
              <svg class="h-8 w-8 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 20l4-16m2 16l4-16M6 9h14M4 15h14" />
              </svg>
            </div>
          </div>
        </div>
      </Card>

      <Card padding={false}>
        <div class="p-6">
          <div class="flex items-center justify-between">
            <div class="flex-1">
              <p class="text-sm font-medium text-secondary-600">Size</p>
              <p class="mt-2 text-3xl font-semibold text-secondary-900">
                {#if isLoadingStats}
                  ...
                {:else if collectionsStore.currentStats?.totalSize}
                  {collectionsStore.currentStats.totalSize < 1024
                    ? `${collectionsStore.currentStats.totalSize} B`
                    : `${(collectionsStore.currentStats.totalSize / 1024).toFixed(2)} KB`}
                {:else}
                  0 B
                {/if}
              </p>
            </div>
            <div class="p-3 bg-green-100 rounded-lg">
              <svg class="h-8 w-8 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 7v10c0 2.21 3.582 4 8 4s8-1.79 8-4V7M4 7c0 2.21 3.582 4 8 4s8-1.79 8-4M4 7c0-2.21 3.582-4 8-4s8 1.79 8 4" />
              </svg>
            </div>
          </div>
        </div>
      </Card>
    </div>

    <!-- Collection Information -->
    <div class="grid grid-cols-1 gap-6 lg:grid-cols-2">
      <!-- Details Card -->
      <Card title="Collection Details">
        <dl class="space-y-4">
          <div>
            <dt class="text-sm font-medium text-secondary-500">Name</dt>
            <dd class="mt-1 text-sm text-secondary-900">{collectionsStore.currentCollection.name}</dd>
          </div>

          <div>
            <dt class="text-sm font-medium text-secondary-500">Created</dt>
            <dd class="mt-1 text-sm text-secondary-900">
              {formatRelativeTime(collectionsStore.currentCollection.createdAt)}
            </dd>
          </div>

          <div>
            <dt class="text-sm font-medium text-secondary-500">Updated</dt>
            <dd class="mt-1 text-sm text-secondary-900">
              {formatRelativeTime(collectionsStore.currentCollection.updatedAt)}
            </dd>
          </div>

          <div>
            <dt class="text-sm font-medium text-secondary-500">Has Schema</dt>
            <dd class="mt-1">
              {#if collectionsStore.currentCollection.schema}
                <Badge variant="success">Yes</Badge>
              {:else}
                <Badge variant="default">No</Badge>
              {/if}
            </dd>
          </div>
        </dl>
      </Card>

      <!-- Quick Actions -->
      <Card title="Quick Actions">
        <div class="space-y-3">
          <Button variant="primary" fullWidth onclick={viewDocuments}>
            <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
            </svg>
            View Documents
          </Button>

          <Button variant="outline" fullWidth>
            <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Add Document
          </Button>

          <Button variant="outline" fullWidth>
            <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-8l-4-4m0 0L8 8m4-4v12" />
            </svg>
            Export Data
          </Button>
        </div>
      </Card>
    </div>

    <!-- Schema -->
    {#if collectionsStore.currentCollection.schema}
      <Card title="Schema">
        <JsonViewer data={collectionsStore.currentCollection.schema} />
      </Card>
    {/if}

    <!-- Indexes -->
    {#if collectionsStore.currentCollection.indexes}
      <Card title="Indexes">
        <JsonViewer data={collectionsStore.currentCollection.indexes} />
      </Card>
    {/if}

    <!-- Options -->
    {#if collectionsStore.currentCollection.options}
      <Card title="Options">
        <JsonViewer data={collectionsStore.currentCollection.options} />
      </Card>
    {/if}
  {:else}
    <Card>
      <div class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9.172 16.172a4 4 0 015.656 0M9 10h.01M15 10h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-secondary-900">Collection not found</h3>
        <p class="mt-1 text-sm text-secondary-500">
          The collection "{collectionName}" doesn't exist
        </p>
        <div class="mt-6">
          <Button variant="primary" onclick={goBack}>
            Go Back
          </Button>
        </div>
      </div>
    </Card>
  {/if}
</div>
