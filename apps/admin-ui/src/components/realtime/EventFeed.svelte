<script lang="ts">
  import type { RealtimeEvent, RealtimeEventType } from '@lib/types'
  import { Badge } from '@components/common'
  import { formatDate, formatRelativeTime } from '@lib/utils'

  interface Props {
    events: RealtimeEvent[]
    onEventClick?: (event: RealtimeEvent) => void
  }

  let {
    events,
    onEventClick
  }: Props = $props()

  let searchTerm = $state('')
  let eventTypeFilter = $state<RealtimeEventType | 'all'>('all')

  const filteredEvents = $derived.by(() => {
    let result = events

    // Filter by search term
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      result = result.filter((event) =>
        event.collection.toLowerCase().includes(term) ||
        event.documentId?.toLowerCase().includes(term) ||
        JSON.stringify(event.document).toLowerCase().includes(term)
      )
    }

    // Filter by event type
    if (eventTypeFilter !== 'all') {
      result = result.filter((event) => event.event === eventTypeFilter)
    }

    return result
  })

  function getEventBadge(eventType: RealtimeEventType) {
    switch (eventType) {
      case 'create':
        return { variant: 'success' as const, text: 'CREATE', icon: 'M12 4v16m8-8H4' }
      case 'update':
        return { variant: 'warning' as const, text: 'UPDATE', icon: 'M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z' }
      case 'delete':
        return { variant: 'error' as const, text: 'DELETE', icon: 'M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16' }
      default:
        return { variant: 'default' as const, text: String(eventType).toUpperCase(), icon: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z' }
    }
  }

  function handleEventClick(event: RealtimeEvent) {
    onEventClick?.(event)
  }
</script>

<div class="bg-white rounded-lg border border-secondary-200">
  <div class="px-6 py-4 border-b border-secondary-200">
    <h3 class="text-lg font-semibold text-secondary-900">Event Feed</h3>
    <p class="mt-1 text-sm text-secondary-600">
      Realtime database change events
    </p>
  </div>

  <!-- Filters -->
  <div class="px-6 py-4 border-b border-secondary-200 bg-secondary-50">
    <div class="flex flex-col sm:flex-row gap-4">
      <div class="flex-1">
        <div class="relative">
          <input
            type="text"
            bind:value={searchTerm}
            placeholder="Search events..."
            class="block w-full rounded-lg border border-secondary-300 pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
          />
          <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
            <svg class="h-5 w-5 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
            </svg>
          </div>
        </div>
      </div>

      <div>
        <select
          bind:value={eventTypeFilter}
          class="block w-full rounded-lg border border-secondary-300 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
        >
          <option value="all">All Events</option>
          <option value="create">Create Only</option>
          <option value="update">Update Only</option>
          <option value="delete">Delete Only</option>
        </select>
      </div>
    </div>

    <div class="mt-2 text-xs text-secondary-500">
      Showing {filteredEvents.length} of {events.length} events
    </div>
  </div>

  <!-- Events List -->
  <div class="divide-y divide-secondary-200 max-h-[600px] overflow-y-auto">
    {#if filteredEvents.length === 0}
      <div class="px-6 py-12 text-center">
        <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
        </svg>
        <h4 class="mt-2 text-sm font-medium text-secondary-900">No events</h4>
        <p class="mt-1 text-sm text-secondary-500">
          {searchTerm || eventTypeFilter !== 'all' ? 'No events match your filters' : 'Waiting for realtime events...'}
        </p>
      </div>
    {:else}
      {#each filteredEvents as event, index (index)}
        <div
          class="px-6 py-4 hover:bg-secondary-50 cursor-pointer transition-colors"
          onclick={() => handleEventClick(event)}
          role="button"
          tabindex="0"
          onkeydown={(e) => e.key === 'Enter' && handleEventClick(event)}
        >
          <div class="flex items-start justify-between">
            <div class="flex items-start space-x-3 flex-1">
              <div class="flex-shrink-0 mt-1">
                <svg class="h-5 w-5 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={getEventBadge(event.event).icon} />
                </svg>
              </div>

              <div class="flex-1 min-w-0">
                <div class="flex items-center space-x-2">
                  <Badge variant={getEventBadge(event.event).variant} size="sm">
                    {getEventBadge(event.event).text}
                  </Badge>
                  <span class="text-sm font-medium text-secondary-900">
                    {event.collection}
                  </span>
                  {#if event.documentId}
                    <span class="text-xs text-secondary-500 font-mono">
                      {event.documentId.substring(0, 8)}...
                    </span>
                  {/if}
                </div>

                <div class="mt-1 text-sm text-secondary-600">
                  {#if event.document._id}
                    <span class="font-medium">ID:</span> {event.document._id.substring(0, 16)}...
                  {/if}
                </div>

                <div class="mt-2 text-xs text-secondary-500 flex items-center space-x-4">
                  <span title={formatDate(event.timestamp)}>
                    {formatRelativeTime(event.timestamp)}
                  </span>
                </div>
              </div>
            </div>

            <div class="flex-shrink-0 ml-4">
              <svg class="h-5 w-5 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 5l7 7-7 7" />
              </svg>
            </div>
          </div>
        </div>
      {/each}
    {/if}
  </div>
</div>
