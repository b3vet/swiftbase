<script lang="ts">
  import type { Snippet } from 'svelte'

  interface Props {
    title?: string
    subtitle?: string
    padding?: boolean
    hover?: boolean
    children: Snippet
    header?: Snippet
    footer?: Snippet
  }

  let {
    title,
    subtitle,
    padding = true,
    hover = false,
    children,
    header,
    footer
  }: Props = $props()

  const baseClasses = 'bg-white rounded-lg shadow-sm border border-secondary-200'
  const hoverClasses = hover ? 'hover:shadow-md transition-shadow' : ''
  const cardClasses = $derived(`${baseClasses} ${hoverClasses}`)
</script>

<div class={cardClasses}>
  {#if header || title || subtitle}
    <div class="px-6 py-4 border-b border-secondary-200">
      {#if header}
        {@render header()}
      {:else}
        {#if title}
          <h3 class="text-lg font-semibold text-secondary-900">{title}</h3>
        {/if}
        {#if subtitle}
          <p class="text-sm text-secondary-600 mt-1">{subtitle}</p>
        {/if}
      {/if}
    </div>
  {/if}

  <div class={padding ? 'px-6 py-4' : ''}>
    {@render children()}
  </div>

  {#if footer}
    <div class="px-6 py-4 border-t border-secondary-200 bg-secondary-50 rounded-b-lg">
      {@render footer()}
    </div>
  {/if}
</div>
