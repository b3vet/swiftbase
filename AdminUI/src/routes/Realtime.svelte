<script lang="ts">
  import { onMount, onDestroy } from 'svelte'
  import type { RealtimeEvent, Subscription } from '@lib/types'
  import { ConnectionStatus } from '@lib/types'
  import { collectionsStore, notificationsStore } from '@lib/stores'
  import { realtimeClient } from '@lib/api'
  import { generateId } from '@lib/utils'
  import { Modal, Button, Alert } from '@components/common'
  import { ConnectionStatus as ConnectionStatusComponent, SubscriptionManager, EventFeed, EventDetail } from '@components/realtime'

  let connectionStatus = $state<ConnectionStatus>(ConnectionStatus.DISCONNECTED)
  let lastPing = $state<Date | null>(null)
  let subscriptions = $state<Subscription[]>([])
  let events = $state<RealtimeEvent[]>([])
  let selectedEvent = $state<RealtimeEvent | null>(null)
  let showEventModal = $state(false)
  let error = $state<string | null>(null)
  let statusUnsubscribe: (() => void) | null = null

  const collectionNames = $derived(collectionsStore.collections.map((c) => c.name))

  onMount(async () => {
    await collectionsStore.fetchAll()

    // Listen to status changes
    statusUnsubscribe = realtimeClient.onStatusChange((status) => {
      connectionStatus = status

      if (status === ConnectionStatus.CONNECTED) {
        lastPing = new Date()
        notificationsStore.success('WebSocket connected')
      } else if (status === ConnectionStatus.DISCONNECTED) {
        notificationsStore.info('WebSocket disconnected')
      } else if (status === ConnectionStatus.ERROR) {
        notificationsStore.error('WebSocket connection error')
      }
    })

    // Connect to WebSocket
    connectWebSocket()
  })

  onDestroy(() => {
    // Unsubscribe from status updates
    if (statusUnsubscribe) {
      statusUnsubscribe()
    }

    // Disconnect WebSocket
    disconnectWebSocket()
  })

  function connectWebSocket() {
    try {
      realtimeClient.connect()
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to connect'
      notificationsStore.error('Failed to connect to WebSocket')
    }
  }

  function disconnectWebSocket() {
    realtimeClient.disconnect()
    subscriptions = []
  }

  function handleRealtimeEvent(event: RealtimeEvent) {
    // Add event to the beginning of the list (newest first)
    events = [event, ...events]

    // Limit to 100 events
    if (events.length > 100) {
      events = events.slice(0, 100)
    }

    // Show notification
    const eventType = event.event.toUpperCase()
    notificationsStore.info(`${eventType}: ${event.collection}`)
  }

  function handleSubscribe(collection: string, documentId?: string) {
    try {
      const callback = (event: RealtimeEvent) => {
        handleRealtimeEvent(event)
      }

      if (documentId) {
        realtimeClient.subscribeToDocument(collection, documentId, callback)
      } else {
        realtimeClient.subscribe(collection, callback)
      }

      const subscription: Subscription = {
        id: generateId(),
        collection,
        documentId,
        createdAt: new Date()
      }

      subscriptions = [...subscriptions, subscription]

      const message = documentId
        ? `Subscribed to document in ${collection}`
        : `Subscribed to ${collection}`
      notificationsStore.success(message)
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to subscribe'
      notificationsStore.error(message)
      throw err
    }
  }

  function handleUnsubscribe(subscription: Subscription) {
    try {
      if (subscription.documentId) {
        realtimeClient.unsubscribeFromDocument(subscription.collection, subscription.documentId)
      } else {
        realtimeClient.unsubscribe(subscription.collection)
      }

      subscriptions = subscriptions.filter((s) => s.id !== subscription.id)

      notificationsStore.success('Unsubscribed successfully')
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to unsubscribe'
      notificationsStore.error(message)
      throw err
    }
  }

  function handleEventClick(event: RealtimeEvent) {
    selectedEvent = event
    showEventModal = true
  }

  function handleCopyJson() {
    notificationsStore.success('Event JSON copied to clipboard')
  }

  function closeEventModal() {
    showEventModal = false
    selectedEvent = null
  }

  function handleReconnect() {
    disconnectWebSocket()
    setTimeout(() => {
      connectWebSocket()
    }, 1000)
  }

  function handleClearEvents() {
    events = []
    notificationsStore.success('Event feed cleared')
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-3xl font-bold text-secondary-900">Realtime Monitor</h1>
      <p class="mt-2 text-secondary-600">
        Monitor database changes in realtime via WebSocket
      </p>
    </div>
    <div class="flex items-center space-x-3">
      {#if events.length > 0}
        <Button variant="outline" onclick={handleClearEvents}>
          <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
          </svg>
          Clear Events
        </Button>
      {/if}
      {#if connectionStatus === ConnectionStatus.ERROR || connectionStatus === ConnectionStatus.DISCONNECTED}
        <Button variant="primary" onclick={handleReconnect}>
          <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
          </svg>
          Reconnect
        </Button>
      {/if}
    </div>
  </div>

  <!-- Error Alert -->
  {#if error}
    <Alert type="error" dismissible ondismiss={() => (error = null)}>
      {error}
    </Alert>
  {/if}

  <!-- Connection Status -->
  <ConnectionStatusComponent status={connectionStatus} {lastPing} />

  <div class="grid grid-cols-1 gap-6 lg:grid-cols-3">
    <!-- Subscription Manager -->
    <div class="lg:col-span-1">
      <SubscriptionManager
        {subscriptions}
        collections={collectionNames}
        onSubscribe={handleSubscribe}
        onUnsubscribe={handleUnsubscribe}
        isConnected={connectionStatus === ConnectionStatus.CONNECTED}
      />
    </div>

    <!-- Event Feed -->
    <div class="lg:col-span-2">
      <EventFeed
        {events}
        onEventClick={handleEventClick}
      />
    </div>
  </div>
</div>

<!-- Event Detail Modal -->
<Modal
  bind:open={showEventModal}
  title="Event Details"
  size="xl"
  onclose={closeEventModal}
>
  {#if selectedEvent}
    <EventDetail
      event={selectedEvent}
      onCopyJson={handleCopyJson}
    />
  {/if}
</Modal>
