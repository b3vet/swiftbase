<script lang="ts">
  import type { Subscription } from '@lib/types'
  import { Button, Input, Badge, Alert } from '@components/common'
  import { formatRelativeTime } from '@lib/utils'

  interface Props {
    subscriptions: Subscription[]
    collections: string[]
    onSubscribe: (collection: string, documentId?: string) => void
    onUnsubscribe: (subscription: Subscription) => void
    isConnected: boolean
  }

  let {
    subscriptions,
    collections,
    onSubscribe,
    onUnsubscribe,
    isConnected
  }: Props = $props()

  let selectedCollection = $state('')
  let documentId = $state('')
  let error = $state<string | null>(null)

  function handleSubscribe() {
    error = null

    if (!selectedCollection) {
      error = 'Please select a collection'
      return
    }

    if (!isConnected) {
      error = 'WebSocket is not connected'
      return
    }

    try {
      onSubscribe(selectedCollection, documentId || undefined)
      selectedCollection = ''
      documentId = ''
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to subscribe'
    }
  }

  function handleUnsubscribe(subscription: Subscription) {
    try {
      onUnsubscribe(subscription)
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to unsubscribe'
    }
  }

  function getSubscriptionLabel(subscription: Subscription): string {
    if (subscription.documentId) {
      return `${subscription.collection}/${subscription.documentId.substring(0, 8)}...`
    }
    return subscription.collection
  }
</script>

<div class="bg-white rounded-lg border border-secondary-200">
  <div class="px-6 py-4 border-b border-secondary-200">
    <h3 class="text-lg font-semibold text-secondary-900">Subscriptions</h3>
    <p class="mt-1 text-sm text-secondary-600">
      Subscribe to collection or document changes
    </p>
  </div>

  <div class="p-6 space-y-6">
    <!-- Subscribe Form -->
    <div class="space-y-4">
      {#if error}
        <Alert type="error" dismissible ondismiss={() => (error = null)}>
          {error}
        </Alert>
      {/if}

      <div class="grid grid-cols-1 gap-4 sm:grid-cols-2">
        <div>
          <label for="subscription-collection" class="block text-sm font-medium text-secondary-700 mb-1">
            Collection
          </label>
          <select
            id="subscription-collection"
            bind:value={selectedCollection}
            class="block w-full rounded-lg border border-secondary-300 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
            disabled={!isConnected}
          >
            <option value="">Select a collection</option>
            {#each collections as collection}
              <option value={collection}>{collection}</option>
            {/each}
          </select>
        </div>

        <div>
          <label for="subscription-document-id" class="block text-sm font-medium text-secondary-700 mb-1">
            Document ID (Optional)
          </label>
          <Input
            id="subscription-document-id"
            type="text"
            bind:value={documentId}
            placeholder="Leave empty for all documents"
            disabled={!isConnected}
          />
        </div>
      </div>

      <div class="flex justify-end">
        <Button
          variant="primary"
          onclick={handleSubscribe}
          disabled={!isConnected || !selectedCollection}
        >
          <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
          </svg>
          Subscribe
        </Button>
      </div>
    </div>

    <!-- Active Subscriptions -->
    <div>
      <h4 class="text-sm font-medium text-secondary-900 mb-3">
        Active Subscriptions ({subscriptions.length})
      </h4>

      {#if subscriptions.length === 0}
        <div class="text-center py-8 bg-secondary-50 rounded-lg">
          <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 17h5l-1.405-1.405A2.032 2.032 0 0118 14.158V11a6.002 6.002 0 00-4-5.659V5a2 2 0 10-4 0v.341C7.67 6.165 6 8.388 6 11v3.159c0 .538-.214 1.055-.595 1.436L4 17h5m6 0v1a3 3 0 11-6 0v-1m6 0H9" />
          </svg>
          <h5 class="mt-2 text-sm font-medium text-secondary-900">No active subscriptions</h5>
          <p class="mt-1 text-sm text-secondary-500">
            Subscribe to collections to receive realtime updates
          </p>
        </div>
      {:else}
        <div class="space-y-2">
          {#each subscriptions as subscription (subscription.id)}
            <div class="flex items-center justify-between p-3 bg-secondary-50 rounded-lg">
              <div class="flex items-center space-x-3">
                <div class="flex-shrink-0">
                  <div class="h-2 w-2 rounded-full bg-green-500 animate-pulse"></div>
                </div>
                <div>
                  <div class="text-sm font-medium text-secondary-900">
                    {getSubscriptionLabel(subscription)}
                  </div>
                  <div class="text-xs text-secondary-500">
                    Subscribed {formatRelativeTime(subscription.createdAt)}
                  </div>
                </div>
                {#if subscription.documentId}
                  <Badge variant="info" size="sm">Document</Badge>
                {:else}
                  <Badge variant="success" size="sm">Collection</Badge>
                {/if}
              </div>

              <button
                type="button"
                class="p-1 text-secondary-400 hover:text-red-600 transition-colors"
                onclick={() => handleUnsubscribe(subscription)}
                title="Unsubscribe"
              >
                <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>
          {/each}
        </div>
      {/if}
    </div>
  </div>
</div>
