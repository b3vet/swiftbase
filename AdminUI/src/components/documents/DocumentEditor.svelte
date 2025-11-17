<script lang="ts">
  import { Button, Alert } from '@components/common'
  import { JSONEditor, Mode } from 'svelte-jsoneditor'
  import { formatDate } from '@lib/utils'

  interface Props {
    document?: any
    onSubmit: (data: any) => Promise<boolean>
    onCancel: () => void
    isLoading?: boolean
  }

  let {
    document,
    onSubmit,
    onCancel,
    isLoading = false
  }: Props = $props()

  let content = $state({
    json: document?.data || {}
  })
  let error = $state<string | null>(null)

  const isEditMode = $derived(!!document)

  async function handleSubmit(event: Event) {
    event.preventDefault()

    try {
      const data = content.json
      const success = await onSubmit(data)

      if (success) {
        // Parent will handle navigation/modal close
      }
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to save document'
    }
  }
</script>

<form class="space-y-4" onsubmit={handleSubmit}>
  {#if error}
    <Alert type="error" dismissible ondismiss={() => (error = null)}>
      {error}
    </Alert>
  {/if}

  <!-- JSON Editor -->
  <div>
    <label class="block text-sm font-medium text-secondary-700 mb-2">
      Document Data (JSON)
    </label>

    <div class="border border-secondary-300 rounded-lg overflow-hidden" style="height: 400px;">
      <JSONEditor
        bind:content
        mode={Mode.text}
        mainMenuBar={true}
        statusBar={false}
        readOnly={isLoading}
      />
    </div>

    <p class="mt-2 text-xs text-secondary-500">
      Enter valid JSON data for the document. Fields starting with _ are reserved.
    </p>
  </div>

  <!-- Document Metadata (if editing) -->
  {#if isEditMode && document}
    <div class="bg-secondary-50 rounded-lg p-4 space-y-2">
      <h4 class="text-sm font-medium text-secondary-900">Document Info</h4>
      <div class="grid grid-cols-2 gap-4 text-xs">
        <div>
          <span class="text-secondary-500">ID:</span>
          <code class="ml-2 text-secondary-900">{document.id}</code>
        </div>
        <div>
          <span class="text-secondary-500">Version:</span>
          <span class="ml-2 text-secondary-900">v{document.version}</span>
        </div>
        <div>
          <span class="text-secondary-500">Created:</span>
          <span class="ml-2 text-secondary-900">
            {formatDate(document.created_at)}
          </span>
        </div>
        <div>
          <span class="text-secondary-500">Updated:</span>
          <span class="ml-2 text-secondary-900">
            {formatDate(document.updated_at)}
          </span>
        </div>
      </div>
    </div>
  {/if}

  <!-- Actions -->
  <div class="flex justify-end space-x-3 pt-4">
    <Button
      type="button"
      variant="ghost"
      onclick={onCancel}
      disabled={isLoading}
    >
      Cancel
    </Button>
    <Button
      type="submit"
      variant="primary"
      loading={isLoading}
      disabled={isLoading}
    >
      {isEditMode ? 'Update Document' : 'Create Document'}
    </Button>
  </div>
</form>

