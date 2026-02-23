<script lang="ts">
  import { onMount } from 'svelte'
  import { authStore, collectionsStore } from '@lib/stores'
  import { usersApi, filesApi } from '@lib/api'
  import { router } from '@lib/router.svelte'
  import { Card, Badge, Spinner } from '@components/common'
  import { formatRelativeTime } from '@lib/utils'

  let isLoading = $state(true)
  let userCount = $state(0)
  let storageSize = $state('0 B')

  // Calculate total documents from all collections
  const totalDocuments = $derived(
    collectionsStore.collections.reduce((sum, col) => sum + (col.documentCount || 0), 0)
  )

  // Format bytes to human-readable size
  function formatBytes(bytes: number): string {
    if (bytes === 0) return '0 B'
    if (bytes < 1024) return `${bytes} B`
    if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(2)} KB`
    if (bytes < 1024 * 1024 * 1024) return `${(bytes / 1024 / 1024).toFixed(2)} MB`
    return `${(bytes / 1024 / 1024 / 1024).toFixed(2)} GB`
  }

  onMount(async () => {
    // Fetch collections data for statistics
    await collectionsStore.fetchAll()

    // Fetch user statistics
    try {
      const response = await usersApi.getStats()
      if (response.success && response.data) {
        userCount = response.data.total_users || 0
      }
    } catch (err) {
      console.error('Failed to load user stats:', err)
    }

    // Fetch storage statistics
    try {
      const response = await filesApi.getStats()
      if (response.success && response.data) {
        storageSize = formatBytes(response.data.totalSize)
      }
    } catch (err) {
      console.error('Failed to load storage stats:', err)
    }

    isLoading = false
  })

  interface StatCard {
    title: string
    value: string | number
    icon: string
    color: string
    description: string
    link?: string
  }

  const stats = $derived<StatCard[]>([
    {
      title: 'Collections',
      value: collectionsStore.collectionCount,
      icon: 'M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10',
      color: 'text-blue-600',
      description: 'Total collections',
      link: '/collections'
    },
    {
      title: 'Users',
      value: userCount,
      icon: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z',
      color: 'text-green-600',
      description: 'Registered users',
      link: '/users'
    },
    {
      title: 'Documents',
      value: totalDocuments,
      icon: 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z',
      color: 'text-purple-600',
      description: 'Total documents'
    },
    {
      title: 'Storage',
      value: storageSize,
      icon: 'M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z',
      color: 'text-orange-600',
      description: 'Files stored',
      link: '/files'
    }
  ])

  function handleStatClick(link?: string) {
    if (link) {
      router.navigate(link)
    }
  }
</script>

<div class="space-y-6">
  <!-- Welcome Header -->
  <div>
    <h1 class="text-3xl font-bold text-secondary-900">
      Welcome back, {authStore.admin?.username}!
    </h1>
    <p class="mt-2 text-secondary-600">
      Here's what's happening with your SwiftBase backend today.
    </p>
  </div>

  <!-- Status Badge -->
  <div class="flex items-center space-x-2">
    <Badge variant="success">System Online</Badge>
    <span class="text-sm text-secondary-600">
      Last login: {authStore.admin?.lastLogin ? formatRelativeTime(authStore.admin.lastLogin) : 'Just now'}
    </span>
  </div>

  <!-- Statistics Cards -->
  {#if isLoading}
    <div class="flex justify-center items-center h-48">
      <Spinner size="lg" />
    </div>
  {:else}
    <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-4">
      {#each stats as stat}
        <Card
          hover={!!stat.link}
          padding={false}
        >
          <button
            type="button"
            class="w-full p-6 text-left {stat.link ? 'cursor-pointer' : 'cursor-default'}"
            onclick={() => handleStatClick(stat.link)}
            disabled={!stat.link}
          >
            <div class="flex items-center justify-between">
              <div class="flex-1">
                <p class="text-sm font-medium text-secondary-600">{stat.title}</p>
                <p class="mt-2 text-3xl font-semibold text-secondary-900">{stat.value}</p>
                <p class="mt-2 text-sm text-secondary-500">{stat.description}</p>
              </div>
              <div class="flex-shrink-0">
                <div class="p-3 bg-secondary-50 rounded-lg">
                  <svg class="h-8 w-8 {stat.color}" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={stat.icon} />
                  </svg>
                </div>
              </div>
            </div>
          </button>
        </Card>
      {/each}
    </div>
  {/if}

  <!-- Quick Actions -->
  <Card title="Quick Actions">
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3">
      <button
        type="button"
        class="flex items-center p-4 border border-secondary-200 rounded-lg hover:bg-secondary-50 hover:border-primary-300 transition-colors"
        onclick={() => router.navigate('/collections')}
      >
        <div class="flex-shrink-0 p-2 bg-blue-100 rounded-lg">
          <svg class="h-6 w-6 text-blue-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
          </svg>
        </div>
        <div class="ml-4">
          <p class="text-sm font-medium text-secondary-900">Create Collection</p>
          <p class="text-xs text-secondary-500">Add a new data collection</p>
        </div>
      </button>

      <button
        type="button"
        class="flex items-center p-4 border border-secondary-200 rounded-lg hover:bg-secondary-50 hover:border-primary-300 transition-colors"
        onclick={() => router.navigate('/query')}
      >
        <div class="flex-shrink-0 p-2 bg-purple-100 rounded-lg">
          <svg class="h-6 w-6 text-purple-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
        <div class="ml-4">
          <p class="text-sm font-medium text-secondary-900">Query Data</p>
          <p class="text-xs text-secondary-500">Execute MongoDB queries</p>
        </div>
      </button>

      <button
        type="button"
        class="flex items-center p-4 border border-secondary-200 rounded-lg hover:bg-secondary-50 hover:border-primary-300 transition-colors"
        onclick={() => router.navigate('/api-tester')}
      >
        <div class="flex-shrink-0 p-2 bg-green-100 rounded-lg">
          <svg class="h-6 w-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4" />
          </svg>
        </div>
        <div class="ml-4">
          <p class="text-sm font-medium text-secondary-900">Test API</p>
          <p class="text-xs text-secondary-500">Test your endpoints</p>
        </div>
      </button>
    </div>
  </Card>

  <!-- Recent Collections -->
  {#if collectionsStore.collections.length > 0}
    <Card title="Recent Collections" subtitle="Your most recently created collections">
      <div class="space-y-3">
        {#each collectionsStore.collections.slice(0, 5) as collection}
          <button
            type="button"
            class="w-full flex items-center justify-between p-3 border border-secondary-200 rounded-lg hover:bg-secondary-50 hover:border-primary-300 transition-colors"
            onclick={() => router.navigate(`/collections/${collection.name}`)}
          >
            <div class="flex items-center">
              <div class="flex-shrink-0 p-2 bg-primary-100 rounded-lg">
                <svg class="h-5 w-5 text-primary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                </svg>
              </div>
              <div class="ml-3 text-left">
                <p class="text-sm font-medium text-secondary-900">{collection.name}</p>
                <p class="text-xs text-secondary-500">
                  Created {formatRelativeTime(collection.createdAt)}
                </p>
              </div>
            </div>
            <svg class="h-5 w-5 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
            </svg>
          </button>
        {/each}
      </div>
    </Card>
  {/if}

  <!-- Getting Started -->
  {#if collectionsStore.collections.length === 0}
    <Card title="Getting Started" subtitle="Start building your backend">
      <div class="space-y-4">
        <div class="flex items-start">
          <div class="flex-shrink-0">
            <div class="flex items-center justify-center h-8 w-8 rounded-full bg-primary-100 text-primary-600 font-semibold">
              1
            </div>
          </div>
          <div class="ml-4">
            <h4 class="text-sm font-medium text-secondary-900">Create your first collection</h4>
            <p class="mt-1 text-sm text-secondary-600">
              Collections store your data. Think of them like database tables.
            </p>
          </div>
        </div>

        <div class="flex items-start">
          <div class="flex-shrink-0">
            <div class="flex items-center justify-center h-8 w-8 rounded-full bg-primary-100 text-primary-600 font-semibold">
              2
            </div>
          </div>
          <div class="ml-4">
            <h4 class="text-sm font-medium text-secondary-900">Add documents</h4>
            <p class="mt-1 text-sm text-secondary-600">
              Documents are JSON objects stored in collections.
            </p>
          </div>
        </div>

        <div class="flex items-start">
          <div class="flex-shrink-0">
            <div class="flex items-center justify-center h-8 w-8 rounded-full bg-primary-100 text-primary-600 font-semibold">
              3
            </div>
          </div>
          <div class="ml-4">
            <h4 class="text-sm font-medium text-secondary-900">Query your data</h4>
            <p class="mt-1 text-sm text-secondary-600">
              Use MongoDB-style queries to find and manipulate data.
            </p>
          </div>
        </div>
      </div>
    </Card>
  {/if}
</div>
