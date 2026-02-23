<script lang="ts">
  import type { Collection, CreateCollectionRequest } from '@lib/types'
  import { Input, Textarea, Button, Alert } from '@components/common'
  import { validation, parseJSON, formatJSON } from '@lib/utils'

  interface Props {
    collection?: Collection
    onSubmit: (data: CreateCollectionRequest) => Promise<boolean>
    onCancel: () => void
    isLoading?: boolean
  }

  let {
    collection,
    onSubmit,
    onCancel,
    isLoading = false
  }: Props = $props()

  let name = $state(collection?.name || '')
  let schemaJson = $state(collection?.schema ? formatJSON(collection.schema) : '')
  let indexesJson = $state(collection?.indexes ? formatJSON(collection.indexes) : '')
  let optionsJson = $state(collection?.options ? formatJSON(collection.options) : '')

  let errors = $state<{
    name?: string
    schema?: string
    indexes?: string
    options?: string
    submit?: string
  }>({})

  const isEditMode = $derived(!!collection)

  function validateForm(): boolean {
    const newErrors: typeof errors = {}

    // Validate name
    if (!validation.isRequired(name)) {
      newErrors.name = 'Collection name is required'
    } else if (!validation.isValidName(name)) {
      newErrors.name = 'Name must start with a letter and contain only letters, numbers, and underscores'
    }

    // Validate schema JSON if provided
    if (schemaJson.trim() && !validation.isValidJSON(schemaJson)) {
      newErrors.schema = 'Invalid JSON format'
    }

    // Validate indexes JSON if provided
    if (indexesJson.trim() && !validation.isValidJSON(indexesJson)) {
      newErrors.indexes = 'Invalid JSON format'
    }

    // Validate options JSON if provided
    if (optionsJson.trim() && !validation.isValidJSON(optionsJson)) {
      newErrors.options = 'Invalid JSON format'
    }

    errors = newErrors
    return Object.keys(newErrors).length === 0
  }

  async function handleSubmit(event: Event) {
    event.preventDefault()

    if (!validateForm()) {
      return
    }

    const data: CreateCollectionRequest = {
      name,
      schema: schemaJson.trim() ? parseJSON(schemaJson) ?? undefined : undefined,
      indexes: indexesJson.trim() ? parseJSON(indexesJson) ?? undefined : undefined,
      options: optionsJson.trim() ? parseJSON(optionsJson) ?? undefined : undefined
    }

    try {
      const success = await onSubmit(data)
      if (success) {
        // Form submission successful, parent will handle navigation
      }
    } catch (error) {
      errors = {
        ...errors,
        submit: error instanceof Error ? error.message : 'Failed to save collection'
      }
    }
  }

  function handleNameInput() {
    if (errors.name) {
      errors = { ...errors, name: undefined }
    }
  }

  function handleSchemaInput() {
    if (errors.schema) {
      errors = { ...errors, schema: undefined }
    }
  }

  function handleIndexesInput() {
    if (errors.indexes) {
      errors = { ...errors, indexes: undefined }
    }
  }

  function handleOptionsInput() {
    if (errors.options) {
      errors = { ...errors, options: undefined }
    }
  }

  function formatSchemaJson() {
    if (schemaJson.trim() && validation.isValidJSON(schemaJson)) {
      const parsed = parseJSON(schemaJson)
      schemaJson = formatJSON(parsed)
    }
  }

  function formatIndexesJson() {
    if (indexesJson.trim() && validation.isValidJSON(indexesJson)) {
      const parsed = parseJSON(indexesJson)
      indexesJson = formatJSON(parsed)
    }
  }

  function formatOptionsJson() {
    if (optionsJson.trim() && validation.isValidJSON(optionsJson)) {
      const parsed = parseJSON(optionsJson)
      optionsJson = formatJSON(parsed)
    }
  }
</script>

<form class="space-y-6" onsubmit={handleSubmit}>
  {#if errors.submit}
    <Alert type="error" dismissible ondismiss={() => (errors.submit = undefined)}>
      {errors.submit}
    </Alert>
  {/if}

  <!-- Collection Name -->
  <Input
    type="text"
    label="Collection Name"
    bind:value={name}
    placeholder="e.g., products, users, orders"
    error={errors.name}
    required
    disabled={isEditMode || isLoading}
    oninput={handleNameInput}
  />

  {#if isEditMode}
    <Alert type="info">
      Collection name cannot be changed after creation.
    </Alert>
  {/if}

  <!-- Schema (Optional) -->
  <div>
    <div class="flex items-center justify-between mb-1">
      <label for="schema-json" class="block text-sm font-medium text-secondary-700">
        Schema (Optional)
      </label>
      {#if schemaJson.trim() && validation.isValidJSON(schemaJson)}
        <button
          type="button"
          class="text-xs text-primary-600 hover:text-primary-800"
          onclick={formatSchemaJson}
        >
          Format JSON
        </button>
      {/if}
    </div>
    <Textarea
      id="schema-json"
      bind:value={schemaJson}
      placeholder={'{"type": "object", "properties": {}}'}
      error={errors.schema}
      rows={6}
      disabled={isLoading}
      oninput={handleSchemaInput}
    />
    <p class="mt-1 text-xs text-secondary-500">
      JSON Schema for document validation (optional)
    </p>
  </div>

  <!-- Indexes (Optional) -->
  <div>
    <div class="flex items-center justify-between mb-1">
      <label for="indexes-json" class="block text-sm font-medium text-secondary-700">
        Indexes (Optional)
      </label>
      {#if indexesJson.trim() && validation.isValidJSON(indexesJson)}
        <button
          type="button"
          class="text-xs text-primary-600 hover:text-primary-800"
          onclick={formatIndexesJson}
        >
          Format JSON
        </button>
      {/if}
    </div>
    <Textarea
      id="indexes-json"
      bind:value={indexesJson}
      placeholder={'{"email": "unique", "created_at": "index"}'}
      error={errors.indexes}
      rows={4}
      disabled={isLoading}
      oninput={handleIndexesInput}
    />
    <p class="mt-1 text-xs text-secondary-500">
      Index definitions for improved query performance (optional)
    </p>
  </div>

  <!-- Options (Optional) -->
  <div>
    <div class="flex items-center justify-between mb-1">
      <label for="options-json" class="block text-sm font-medium text-secondary-700">
        Options (Optional)
      </label>
      {#if optionsJson.trim() && validation.isValidJSON(optionsJson)}
        <button
          type="button"
          class="text-xs text-primary-600 hover:text-primary-800"
          onclick={formatOptionsJson}
        >
          Format JSON
        </button>
      {/if}
    </div>
    <Textarea
      id="options-json"
      bind:value={optionsJson}
      placeholder={'{"timestamps": true, "softDelete": false}'}
      error={errors.options}
      rows={4}
      disabled={isLoading}
      oninput={handleOptionsInput}
    />
    <p class="mt-1 text-xs text-secondary-500">
      Collection-specific options (optional)
    </p>
  </div>

  <!-- Actions -->
  <div class="flex justify-end space-x-3">
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
      {isEditMode ? 'Update Collection' : 'Create Collection'}
    </Button>
  </div>
</form>
