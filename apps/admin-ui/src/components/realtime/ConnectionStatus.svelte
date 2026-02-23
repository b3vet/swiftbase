<script lang="ts">
  import { ConnectionStatus } from '@lib/types'
  import { Badge } from '@components/common'

  interface Props {
    status: ConnectionStatus
    lastPing?: Date | null
  }

  let {
    status,
    lastPing = null
  }: Props = $props()

  function getStatusBadge(status: ConnectionStatus) {
    switch (status) {
      case ConnectionStatus.CONNECTED:
        return { variant: 'success' as const, text: 'Connected', icon: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z' }
      case ConnectionStatus.CONNECTING:
        return { variant: 'warning' as const, text: 'Connecting...', icon: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15' }
      case ConnectionStatus.RECONNECTING:
        return { variant: 'warning' as const, text: 'Reconnecting...', icon: 'M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15' }
      case ConnectionStatus.DISCONNECTED:
        return { variant: 'default' as const, text: 'Disconnected', icon: 'M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728A9 9 0 015.636 5.636m12.728 12.728L5.636 5.636' }
      case ConnectionStatus.ERROR:
        return { variant: 'error' as const, text: 'Connection Error', icon: 'M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z' }
      default:
        return { variant: 'default' as const, text: 'Unknown', icon: 'M8.228 9c.549-1.165 2.03-2 3.772-2 2.21 0 4 1.343 4 3 0 1.4-1.278 2.575-3.006 2.907-.542.104-.994.54-.994 1.093m0 3h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z' }
    }
  }

  function formatLastPing(date: Date | null): string {
    if (!date) return 'Never'

    const now = new Date()
    const diff = now.getTime() - date.getTime()
    const seconds = Math.floor(diff / 1000)

    if (seconds < 5) return 'Just now'
    if (seconds < 60) return `${seconds}s ago`

    const minutes = Math.floor(seconds / 60)
    if (minutes < 60) return `${minutes}m ago`

    const hours = Math.floor(minutes / 60)
    return `${hours}h ago`
  }

  const badge = $derived(getStatusBadge(status))
</script>

<div class="bg-white rounded-lg border border-secondary-200 p-4">
  <div class="flex items-center justify-between">
    <div class="flex items-center space-x-3">
      <div class="flex-shrink-0">
        <svg class="h-8 w-8 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={badge.icon} />
        </svg>
      </div>
      <div>
        <h3 class="text-sm font-medium text-secondary-900">WebSocket Connection</h3>
        <div class="mt-1 flex items-center space-x-2">
          <Badge variant={badge.variant}>
            {badge.text}
          </Badge>
          {#if status === ConnectionStatus.CONNECTED}
            <span class="flex items-center text-xs text-secondary-500">
              <span class="flex h-2 w-2 mr-1.5">
                <span class="animate-ping absolute inline-flex h-2 w-2 rounded-full bg-green-400 opacity-75"></span>
                <span class="relative inline-flex rounded-full h-2 w-2 bg-green-500"></span>
              </span>
              Live
            </span>
          {/if}
        </div>
      </div>
    </div>

    <div class="text-right">
      <div class="text-xs text-secondary-500">Last Heartbeat</div>
      <div class="text-sm font-medium text-secondary-900">
        {formatLastPing(lastPing)}
      </div>
    </div>
  </div>
</div>
