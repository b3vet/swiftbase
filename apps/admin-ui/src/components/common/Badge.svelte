<script lang="ts">
  import type { Snippet } from 'svelte'

  interface Props {
    variant?: 'success' | 'error' | 'warning' | 'info' | 'default'
    size?: 'sm' | 'md' | 'lg'
    rounded?: boolean
    children: Snippet
  }

  let {
    variant = 'default',
    size = 'md',
    rounded = false,
    children
  }: Props = $props()

  const baseClasses = 'inline-flex items-center font-medium'

  const variantClasses = {
    success: 'bg-green-100 text-green-800',
    error: 'bg-red-100 text-red-800',
    warning: 'bg-yellow-100 text-yellow-800',
    info: 'bg-blue-100 text-blue-800',
    default: 'bg-secondary-100 text-secondary-800'
  }

  const sizeClasses = {
    sm: 'px-2 py-0.5 text-xs',
    md: 'px-2.5 py-1 text-sm',
    lg: 'px-3 py-1.5 text-base'
  }

  const roundedClass = rounded ? 'rounded-full' : 'rounded'

  const badgeClasses = $derived(
    `${baseClasses} ${variantClasses[variant]} ${sizeClasses[size]} ${roundedClass}`
  )
</script>

<span class={badgeClasses}>
  {@render children()}
</span>
