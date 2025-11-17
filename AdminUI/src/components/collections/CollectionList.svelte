<script lang="ts">
  import type { Collection } from '@lib/types'
  import { Card, Badge } from '@components/common'
  import { formatRelativeTime } from '@lib/utils'
  import { router } from '@lib/router.svelte'

  interface Props {
    collections: Collection[]
    onDelete?: (collection: Collection) => void
    onEdit?: (collection: Collection) => void
  }

  let {
    collections,
    onDelete,
    onEdit
  }: Props = $props()

  let viewMode = $state<'grid' | 'list'>('grid')

  function handleCollectionClick(collection: Collection) {
    router.navigate(`/collections/${collection.name}`)
  }

  function handleDeleteClick(event: MouseEvent, collection: Collection) {
    event.stopPropagation()
    onDelete?.(collection)
  }

  function handleEditClick(event: MouseEvent, collection: Collection) {
    event.stopPropagation()
    onEdit?.(collection)
  }
</script>

<div>
  <!-- View Mode Toggle -->
  <div class="flex justify-end mb-4">
    <div class="inline-flex rounded-lg border border-secondary-200 p-1">
      <button
        type="button"
        aria-label="Grid view"
        class="px-3 py-1.5 rounded-md text-sm font-medium transition-colors {viewMode === 'grid'
          ? 'bg-primary-600 text-white'
          : 'text-secondary-600 hover:text-secondary-900'}"
        onclick={() => (viewMode = 'grid')}
      >
        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2V6zM14 6a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2V6zM4 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2H6a2 2 0 01-2-2v-2zM14 16a2 2 0 012-2h2a2 2 0 012 2v2a2 2 0 01-2 2h-2a2 2 0 01-2-2v-2z" />
        </svg>
      </button>
      <button
        type="button"
        aria-label="List view"
        class="px-3 py-1.5 rounded-md text-sm font-medium transition-colors {viewMode === 'list'
          ? 'bg-primary-600 text-white'
          : 'text-secondary-600 hover:text-secondary-900'}"
        onclick={() => (viewMode = 'list')}
      >
        <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
        </svg>
      </button>
    </div>
  </div>

  <!-- Grid View -->
  {#if viewMode === 'grid'}
    <div class="grid grid-cols-1 gap-6 sm:grid-cols-2 lg:grid-cols-3">
      {#each collections as collection (collection.id)}
        <Card hover padding={false}>
          <div
            class="w-full text-left p-6 cursor-pointer"
            onclick={() => handleCollectionClick(collection)}
            role="button"
            tabindex="0"
            onkeydown={(e) => e.key === 'Enter' && handleCollectionClick(collection)}
          >
            <div class="flex items-start justify-between">
              <div class="flex items-center">
                <div class="flex-shrink-0 p-3 bg-primary-100 rounded-lg">
                  <svg class="h-6 w-6 text-primary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                  </svg>
                </div>
              </div>
              <div class="flex space-x-1">
                <button
                  type="button"
                  class="p-1 text-secondary-400 hover:text-primary-600 transition-colors"
                  onclick={(e) => handleEditClick(e, collection)}
                  title="Edit"
                >
                  <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                  </svg>
                </button>
                <button
                  type="button"
                  class="p-1 text-secondary-400 hover:text-red-600 transition-colors"
                  onclick={(e) => handleDeleteClick(e, collection)}
                  title="Delete"
                >
                  <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              </div>
            </div>

            <h3 class="mt-4 text-lg font-semibold text-secondary-900">
              {collection.name}
            </h3>

            <div class="mt-4 flex items-center justify-between text-sm">
              <span class="text-secondary-500">
                Created {formatRelativeTime(collection.created_at)}
              </span>
            </div>

            {#if collection.schema}
              <div class="mt-2">
                <Badge variant="info" size="sm">Has Schema</Badge>
              </div>
            {/if}
          </div>
        </Card>
      {/each}
    </div>
  {:else}
    <!-- List View -->
    <div class="bg-white rounded-lg shadow-sm border border-secondary-200 overflow-hidden">
      <table class="min-w-full divide-y divide-secondary-200">
        <thead class="bg-secondary-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Name
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Schema
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Created
            </th>
            <th class="px-6 py-3 text-right text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-secondary-200">
          {#each collections as collection (collection.id)}
            <tr class="hover:bg-secondary-50 cursor-pointer" onclick={() => handleCollectionClick(collection)}>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <div class="flex-shrink-0 p-2 bg-primary-100 rounded-lg">
                    <svg class="h-5 w-5 text-primary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
                    </svg>
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-secondary-900">
                      {collection.name}
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                {#if collection.schema}
                  <Badge variant="info" size="sm">Yes</Badge>
                {:else}
                  <Badge variant="default" size="sm">No</Badge>
                {/if}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-secondary-500">
                {formatRelativeTime(collection.created_at)}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <button
                  type="button"
                  class="text-primary-600 hover:text-primary-900 mr-4"
                  onclick={(e) => handleEditClick(e, collection)}
                >
                  Edit
                </button>
                <button
                  type="button"
                  class="text-red-600 hover:text-red-900"
                  onclick={(e) => handleDeleteClick(e, collection)}
                >
                  Delete
                </button>
              </td>
            </tr>
          {/each}
        </tbody>
      </table>
    </div>
  {/if}
</div>
