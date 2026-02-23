<script lang="ts">
  import type { Snippet } from 'svelte'
  import Button from './Button.svelte'

  interface Props {
    open?: boolean
    title?: string
    size?: 'sm' | 'md' | 'lg' | 'xl'
    closeOnBackdrop?: boolean
    showCloseButton?: boolean
    onclose?: () => void
    children: Snippet
    footer?: Snippet
  }

  let {
    open = $bindable(false),
    title,
    size = 'md',
    closeOnBackdrop = true,
    showCloseButton = true,
    onclose,
    children,
    footer
  }: Props = $props()

  const sizeClasses = {
    sm: 'max-w-md',
    md: 'max-w-lg',
    lg: 'max-w-2xl',
    xl: 'max-w-4xl'
  }

  function handleBackdropClick() {
    if (closeOnBackdrop) {
      close()
    }
  }

  function close() {
    open = false
    onclose?.()
  }

  function handleKeydown(event: KeyboardEvent) {
    if (event.key === 'Escape' && open) {
      close()
    }
  }

  $effect(() => {
    if (open) {
      document.body.style.overflow = 'hidden'
      window.addEventListener('keydown', handleKeydown)
    } else {
      document.body.style.overflow = ''
      window.removeEventListener('keydown', handleKeydown)
    }

    return () => {
      document.body.style.overflow = ''
      window.removeEventListener('keydown', handleKeydown)
    }
  })
</script>

{#if open}
  <div class="fixed inset-0 z-50 overflow-y-auto">
    <!-- Backdrop -->
    <div
      class="fixed inset-0 bg-black bg-opacity-50 transition-opacity"
      onclick={handleBackdropClick}
      role="presentation"
    ></div>

    <!-- Modal Container -->
    <div class="flex min-h-full items-center justify-center p-4">
      <!-- Modal Panel -->
      <div
        class="relative bg-white rounded-lg shadow-xl w-full {sizeClasses[size]} transform transition-all"
        role="dialog"
        aria-modal="true"
      >
        <!-- Header -->
        {#if title || showCloseButton}
          <div class="flex items-center justify-between px-6 py-4 border-b border-secondary-200">
            {#if title}
              <h3 class="text-lg font-semibold text-secondary-900">{title}</h3>
            {:else}
              <div></div>
            {/if}

            {#if showCloseButton}
              <button
                type="button"
                class="text-secondary-400 hover:text-secondary-600 transition-colors"
                onclick={close}
                aria-label="Close modal"
              >
                <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                  <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            {/if}
          </div>
        {/if}

        <!-- Body -->
        <div class="px-6 py-4">
          {@render children()}
        </div>

        <!-- Footer -->
        {#if footer}
          <div class="px-6 py-4 border-t border-secondary-200 bg-secondary-50 rounded-b-lg">
            {@render footer()}
          </div>
        {/if}
      </div>
    </div>
  </div>
{/if}
