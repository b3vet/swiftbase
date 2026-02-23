<script lang="ts">
  import type { Snippet } from 'svelte'

  interface Props {
    type?: 'success' | 'error' | 'warning' | 'info'
    title?: string
    dismissible?: boolean
    ondismiss?: () => void
    children: Snippet
  }

  let {
    type = 'info',
    title,
    dismissible = false,
    ondismiss,
    children
  }: Props = $props()

  let visible = $state(true)

  const typeConfig = {
    success: {
      bg: 'bg-green-50',
      border: 'border-green-200',
      text: 'text-green-800',
      icon: 'text-green-400',
      iconPath: 'M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z'
    },
    error: {
      bg: 'bg-red-50',
      border: 'border-red-200',
      text: 'text-red-800',
      icon: 'text-red-400',
      iconPath: 'M10 14l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2m7-2a9 9 0 11-18 0 9 9 0 0118 0z'
    },
    warning: {
      bg: 'bg-yellow-50',
      border: 'border-yellow-200',
      text: 'text-yellow-800',
      icon: 'text-yellow-400',
      iconPath: 'M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z'
    },
    info: {
      bg: 'bg-blue-50',
      border: 'border-blue-200',
      text: 'text-blue-800',
      icon: 'text-blue-400',
      iconPath: 'M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z'
    }
  }

  const config = $derived(typeConfig[type])

  function handleDismiss() {
    visible = false
    ondismiss?.()
  }
</script>

{#if visible}
  <div class="rounded-lg border p-4 {config.bg} {config.border}" role="alert">
    <div class="flex">
      <!-- Icon -->
      <div class="flex-shrink-0">
        <svg class="h-5 w-5 {config.icon}" viewBox="0 0 24 24" fill="none" stroke="currentColor">
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d={config.iconPath}
          />
        </svg>
      </div>

      <!-- Content -->
      <div class="ml-3 flex-1">
        {#if title}
          <h3 class="text-sm font-medium {config.text}">{title}</h3>
        {/if}
        <div class="text-sm {config.text} {title ? 'mt-2' : ''}">
          {@render children()}
        </div>
      </div>

      <!-- Dismiss button -->
      {#if dismissible}
        <div class="ml-auto pl-3">
          <button
            type="button"
            class="-mx-1.5 -my-1.5 rounded-lg p-1.5 inline-flex h-8 w-8 {config.bg} {config.text} hover:bg-opacity-75 focus:outline-none focus:ring-2 focus:ring-offset-2"
            onclick={handleDismiss}
          >
            <span class="sr-only">Dismiss</span>
            <svg class="h-5 w-5" viewBox="0 0 20 20" fill="currentColor">
              <path
                fill-rule="evenodd"
                d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z"
                clip-rule="evenodd"
              />
            </svg>
          </button>
        </div>
      {/if}
    </div>
  </div>
{/if}
