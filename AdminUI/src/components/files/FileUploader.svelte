<script lang="ts">
  import { Button, Alert } from '@components/common'

  interface Props {
    onUpload: (files: File[]) => Promise<void>
    maxFileSize?: number // in bytes
    accept?: string
    multiple?: boolean
    isLoading?: boolean
  }

  let {
    onUpload,
    maxFileSize = 100 * 1024 * 1024, // 100MB default
    accept,
    multiple = true,
    isLoading = false
  }: Props = $props()

  let isDragging = $state(false)
  let error = $state<string | null>(null)
  let fileInput: HTMLInputElement

  function handleDragEnter(e: DragEvent) {
    e.preventDefault()
    e.stopPropagation()
    isDragging = true
  }

  function handleDragLeave(e: DragEvent) {
    e.preventDefault()
    e.stopPropagation()
    isDragging = false
  }

  function handleDragOver(e: DragEvent) {
    e.preventDefault()
    e.stopPropagation()
  }

  function handleDrop(e: DragEvent) {
    e.preventDefault()
    e.stopPropagation()
    isDragging = false

    const files = Array.from(e.dataTransfer?.files || [])
    handleFiles(files)
  }

  function handleFileSelect(e: Event) {
    const target = e.target as HTMLInputElement
    const files = Array.from(target.files || [])
    handleFiles(files)

    // Reset input
    target.value = ''
  }

  function validateFiles(files: File[]): string | null {
    for (const file of files) {
      if (file.size > maxFileSize) {
        return `File "${file.name}" exceeds maximum size of ${formatFileSize(maxFileSize)}`
      }
    }
    return null
  }

  async function handleFiles(files: File[]) {
    error = null

    if (files.length === 0) {
      return
    }

    const validationError = validateFiles(files)
    if (validationError) {
      error = validationError
      return
    }

    try {
      await onUpload(files)
    } catch (err) {
      error = err instanceof Error ? err.message : 'Upload failed'
    }
  }

  function formatFileSize(bytes: number): string {
    if (bytes === 0) return '0 Bytes'
    const k = 1024
    const sizes = ['Bytes', 'KB', 'MB', 'GB']
    const i = Math.floor(Math.log(bytes) / Math.log(k))
    return Math.round((bytes / Math.pow(k, i)) * 100) / 100 + ' ' + sizes[i]
  }

  function openFilePicker() {
    fileInput?.click()
  }
</script>

<div class="space-y-4">
  {#if error}
    <Alert type="error" dismissible ondismiss={() => (error = null)}>
      {error}
    </Alert>
  {/if}

  <!-- Drop Zone -->
  <div
    class="relative border-2 border-dashed rounded-lg transition-colors {isDragging
      ? 'border-primary-500 bg-primary-50'
      : 'border-secondary-300 bg-white'} {isLoading ? 'opacity-50 pointer-events-none' : ''}"
    ondragenter={handleDragEnter}
    ondragleave={handleDragLeave}
    ondragover={handleDragOver}
    ondrop={handleDrop}
    role="button"
    tabindex="0"
    onkeydown={(e) => e.key === 'Enter' && openFilePicker()}
  >
    <div class="p-12 text-center">
      <svg
        class="mx-auto h-12 w-12 {isDragging ? 'text-primary-500' : 'text-secondary-400'}"
        fill="none"
        viewBox="0 0 24 24"
        stroke="currentColor"
      >
        <path
          stroke-linecap="round"
          stroke-linejoin="round"
          stroke-width="2"
          d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12"
        />
      </svg>

      <div class="mt-4">
        <p class="text-sm text-secondary-900 font-medium">
          {#if isDragging}
            Drop files here
          {:else}
            Drag and drop files here, or click to browse
          {/if}
        </p>
        <p class="mt-1 text-xs text-secondary-500">
          Maximum file size: {formatFileSize(maxFileSize)}
        </p>
      </div>

      <div class="mt-6">
        <Button
          variant="primary"
          onclick={openFilePicker}
          disabled={isLoading}
          loading={isLoading}
        >
          <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path
              stroke-linecap="round"
              stroke-linejoin="round"
              stroke-width="2"
              d="M12 4v16m8-8H4"
            />
          </svg>
          Select Files
        </Button>
      </div>
    </div>
  </div>

  <!-- Hidden File Input -->
  <input
    bind:this={fileInput}
    type="file"
    class="hidden"
    {accept}
    {multiple}
    onchange={handleFileSelect}
  />
</div>
