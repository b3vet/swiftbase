<script lang="ts">
  interface Props {
    data: any
    maxHeight?: string
    copyable?: boolean
    theme?: 'light' | 'dark'
    onCopy?: () => void
  }

  let {
    data,
    maxHeight = 'none',
    copyable = false,
    theme = 'light',
    onCopy
  }: Props = $props()

  const formattedJson = $derived.by(() => {
    try {
      return JSON.stringify(data, null, 2)
    } catch {
      return String(data)
    }
  })

  async function handleCopy() {
    try {
      await navigator.clipboard.writeText(formattedJson)
      onCopy?.()
    } catch (err) {
      console.error('Failed to copy JSON:', err)
    }
  }
</script>

<div
  class="relative rounded-lg"
  class:bg-secondary-50={theme === 'light'}
  class:bg-secondary-900={theme === 'dark'}
>
  {#if copyable}
    <button
      type="button"
      onclick={handleCopy}
      class="absolute top-2 right-2 p-1.5 rounded transition-colors"
      class:text-secondary-500={theme === 'light'}
      class:hover:text-secondary-700={theme === 'light'}
      class:hover:bg-secondary-200={theme === 'light'}
      class:text-secondary-400={theme === 'dark'}
      class:hover:text-secondary-200={theme === 'dark'}
      class:hover:bg-secondary-700={theme === 'dark'}
      title="Copy JSON"
    >
      <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
      </svg>
    </button>
  {/if}
  <pre
    class="p-4 text-sm font-mono overflow-x-auto"
    class:text-secondary-900={theme === 'light'}
    class:text-secondary-100={theme === 'dark'}
    style:max-height={maxHeight}
    class:overflow-y-auto={maxHeight !== 'none'}
  ><code>{formattedJson}</code></pre>
</div>
