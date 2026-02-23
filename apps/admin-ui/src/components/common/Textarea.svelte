<script lang="ts">
  interface Props {
    id?: string
    value?: string
    placeholder?: string
    label?: string
    error?: string
    disabled?: boolean
    required?: boolean
    readonly?: boolean
    rows?: number
    maxlength?: number
    oninput?: (event: Event) => void
    onchange?: (event: Event) => void
    onfocus?: (event: FocusEvent) => void
    onblur?: (event: FocusEvent) => void
  }

  let {
    id,
    value = $bindable(''),
    placeholder = '',
    label,
    error,
    disabled = false,
    required = false,
    readonly = false,
    rows = 4,
    maxlength,
    oninput,
    onchange,
    onfocus,
    onblur
  }: Props = $props()

  const textareaId = id ?? `textarea-${Math.random().toString(36).substring(2, 9)}`

  const baseClasses = 'block w-full rounded-lg border px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-offset-1 transition-colors disabled:opacity-50 disabled:cursor-not-allowed resize-y'

  const textareaClasses = $derived(
    error
      ? `${baseClasses} border-red-300 focus:border-red-500 focus:ring-red-500`
      : `${baseClasses} border-secondary-300 focus:border-primary-500 focus:ring-primary-500`
  )
</script>

<div class="w-full">
  {#if label}
    <label for={textareaId} class="block text-sm font-medium text-secondary-700 mb-1">
      {label}
      {#if required}
        <span class="text-red-500">*</span>
      {/if}
    </label>
  {/if}

  <textarea
    id={textareaId}
    bind:value
    {placeholder}
    {disabled}
    {required}
    {readonly}
    {rows}
    {maxlength}
    class={textareaClasses}
    oninput={oninput}
    onchange={onchange}
    onfocus={onfocus}
    onblur={onblur}
  ></textarea>

  {#if error}
    <p class="mt-1 text-sm text-red-600">{error}</p>
  {/if}
</div>
