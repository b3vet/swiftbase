<script lang="ts">
  import type { RealtimeEvent } from '@lib/types'
  import { Badge, Button } from '@components/common'
  import { formatDate, formatJSON } from '@lib/utils'

  interface Props {
    event: RealtimeEvent
    onCopyJson?: () => void
  }

  let {
    event,
    onCopyJson
  }: Props = $props()

  function getEventBadge(eventType: string) {
    switch (eventType) {
      case 'create':
        return { variant: 'success' as const, text: 'CREATE' }
      case 'update':
        return { variant: 'warning' as const, text: 'UPDATE' }
      case 'delete':
        return { variant: 'error' as const, text: 'DELETE' }
      default:
        return { variant: 'default' as const, text: eventType.toUpperCase() }
    }
  }

  async function handleCopyJson() {
    try {
      await navigator.clipboard.writeText(formatJSON(event))
      onCopyJson?.()
    } catch (err) {
      console.error('Failed to copy JSON:', err)
    }
  }

  const badge = $derived(getEventBadge(event.event))
</script>

<div class="space-y-6">
  <!-- Event Header -->
  <div class="bg-white rounded-lg border border-secondary-200 p-6">
    <div class="flex items-start justify-between">
      <div>
        <div class="flex items-center space-x-2 mb-2">
          <Badge variant={badge.variant} size="sm">
            {badge.text}
          </Badge>
          <h3 class="text-lg font-semibold text-secondary-900">
            {event.collection}
          </h3>
        </div>
        <div class="text-sm text-secondary-600">
          {formatDate(event.timestamp)}
        </div>
      </div>

      <Button variant="outline" size="sm" onclick={handleCopyJson}>
        <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
        </svg>
        Copy JSON
      </Button>
    </div>
  </div>

  <!-- Event Metadata -->
  <div class="bg-white rounded-lg border border-secondary-200 p-6">
    <h4 class="text-sm font-semibold text-secondary-900 mb-4">Event Metadata</h4>
    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div>
        <dt class="text-sm font-medium text-secondary-500">Event Type</dt>
        <dd class="mt-1">
          <Badge variant={badge.variant}>
            {badge.text}
          </Badge>
        </dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-secondary-500">Collection</dt>
        <dd class="mt-1 text-sm text-secondary-900">{event.collection}</dd>
      </div>

      {#if event.documentId}
        <div>
          <dt class="text-sm font-medium text-secondary-500">Document ID</dt>
          <dd class="mt-1 text-sm text-secondary-900 font-mono break-all">{event.documentId}</dd>
        </div>
      {/if}

      <div>
        <dt class="text-sm font-medium text-secondary-500">Timestamp</dt>
        <dd class="mt-1 text-sm text-secondary-900">{formatDate(event.timestamp)}</dd>
      </div>
    </dl>
  </div>

  <!-- Document Data -->
  <div class="bg-white rounded-lg border border-secondary-200 p-6">
    <h4 class="text-sm font-semibold text-secondary-900 mb-4">Document Data</h4>

    <div class="bg-secondary-50 rounded-lg p-4">
      <pre class="text-sm overflow-x-auto">
        <code>{formatJSON(event.document)}</code>
      </pre>
    </div>
  </div>

  <!-- Full Event JSON -->
  <div class="bg-white rounded-lg border border-secondary-200 p-6">
    <h4 class="text-sm font-semibold text-secondary-900 mb-4">Full Event JSON</h4>

    <div class="bg-secondary-50 rounded-lg p-4">
      <pre class="text-sm overflow-x-auto">
        <code>{formatJSON(event)}</code>
      </pre>
    </div>
  </div>
</div>
