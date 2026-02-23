<script lang="ts">
  import type { Snippet } from 'svelte'

  interface Props {
    striped?: boolean
    hoverable?: boolean
    children: Snippet
  }

  let {
    striped = false,
    hoverable = true,
    children
  }: Props = $props()
</script>

<div class="overflow-x-auto">
  <table class="min-w-full divide-y divide-secondary-200">
    {@render children()}
  </table>
</div>

<style>
  :global(table thead) {
    @apply bg-secondary-50;
  }

  :global(table th) {
    @apply px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider;
  }

  :global(table tbody) {
    @apply bg-white;
  }

  :global(table td) {
    @apply px-6 py-4 whitespace-nowrap text-sm text-secondary-900;
  }

  :global(table tr:hover td) {
    @apply bg-secondary-50;
  }
</style>
