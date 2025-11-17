<script lang="ts">
  import type { SavedQuery } from '@lib/types'
  import { Button, Badge } from '@components/common'
  import { formatRelativeTime } from '@lib/utils'

  interface Props {
    queries: SavedQuery[]
    onLoad?: (query: SavedQuery) => void
    onDelete?: (query: SavedQuery) => void
  }

  let {
    queries,
    onLoad,
    onDelete
  }: Props = $props()

  function handleLoad(query: SavedQuery) {
    onLoad?.(query)
  }

  function handleDelete(event: MouseEvent, query: SavedQuery) {
    event.stopPropagation()
    onDelete?.(query)
  }

  function getActionBadgeVariant(action: string): 'success' | 'error' | 'warning' | 'info' | 'default' {
    switch (action) {
      case 'find':
      case 'findOne':
        return 'info'
      case 'create':
        return 'success'
      case 'update':
        return 'warning'
      case 'delete':
        return 'error'
      default:
        return 'default'
    }
  }
</script>

<div class="bg-white rounded-lg shadow-sm border border-secondary-200">
  <div class="px-6 py-4 border-b border-secondary-200">
    <h3 class="text-lg font-semibold text-secondary-900">Saved Queries</h3>
    <p class="mt-1 text-sm text-secondary-600">
      Your frequently used queries
    </p>
  </div>

  <div class="divide-y divide-secondary-200">
    {#if queries.length === 0}
      <div class="px-6 py-12 text-center">
        <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4" />
        </svg>
        <h4 class="mt-2 text-sm font-medium text-secondary-900">No saved queries</h4>
        <p class="mt-1 text-sm text-secondary-500">
          Save queries for quick access later
        </p>
      </div>
    {:else}
      {#each queries as query (query.id)}
        <div
          role="button"
          tabindex="0"
          class="px-6 py-4 hover:bg-secondary-50 cursor-pointer"
          onclick={() => handleLoad(query)}
          onkeydown={(e) => (e.key === 'Enter' || e.key === ' ') && handleLoad(query)}
        >
          <div class="flex items-start justify-between">
            <div class="flex-1">
              <div class="flex items-center space-x-2">
                <h4 class="text-sm font-medium text-secondary-900">{query.name}</h4>
                <Badge variant={getActionBadgeVariant(query.query.action)} size="sm">
                  {query.query.action}
                </Badge>
              </div>
              {#if query.description}
                <p class="mt-1 text-sm text-secondary-600">{query.description}</p>
              {/if}
              <div class="mt-2 flex items-center space-x-4 text-xs text-secondary-500">
                <span>Collection: <span class="font-medium">{query.query.collection}</span></span>
                <span>Created {formatRelativeTime(query.created_at)}</span>
              </div>
            </div>

            <div class="flex items-center space-x-2 ml-4">
              <Button
                variant="ghost"
                size="sm"
                onclick={(e: MouseEvent) => {
                  e.stopPropagation()
                  handleLoad(query)
                }}
              >
                Load
              </Button>
              <button
                type="button"
                class="p-1 text-secondary-400 hover:text-red-600 transition-colors"
                onclick={(e) => handleDelete(e, query)}
                title="Delete"
              >
                <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                </svg>
              </button>
            </div>
          </div>
        </div>
      {/each}
    {/if}
  </div>
</div>
