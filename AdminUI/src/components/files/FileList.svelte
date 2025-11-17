<script lang="ts">
  import type { FileMetadata } from '@lib/types'
  import { Button, Badge } from '@components/common'
  import { formatBytes, formatRelativeTime } from '@lib/utils'

  interface Props {
    files: FileMetadata[]
    onPreview?: (file: FileMetadata) => void
    onDownload?: (file: FileMetadata) => void
    onDelete?: (file: FileMetadata) => void
    onCopyUrl?: (file: FileMetadata) => void
    isLoading?: boolean
  }

  let {
    files,
    onPreview,
    onDownload,
    onDelete,
    onCopyUrl,
    isLoading = false
  }: Props = $props()

  let searchTerm = $state('')

  const filteredFiles = $derived.by(() => {
    if (!searchTerm) return files

    const term = searchTerm.toLowerCase()
    return files.filter((file) =>
      file.name.toLowerCase().includes(term) ||
      file.mime_type?.toLowerCase().includes(term)
    )
  })

  function getFileIcon(file: FileMetadata): string {
    const mimeType = file.mime_type || ''

    if (mimeType.startsWith('image/')) {
      return 'M4 16l4.586-4.586a2 2 0 012.828 0L16 16m-2-2l1.586-1.586a2 2 0 012.828 0L20 14m-6-6h.01M6 20h12a2 2 0 002-2V6a2 2 0 00-2-2H6a2 2 0 00-2 2v12a2 2 0 002 2z'
    } else if (mimeType.startsWith('video/')) {
      return 'M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z'
    } else if (mimeType.startsWith('audio/')) {
      return 'M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3'
    } else if (mimeType.includes('pdf')) {
      return 'M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z'
    } else if (mimeType.includes('text') || mimeType.includes('json') || mimeType.includes('javascript')) {
      return 'M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z'
    } else if (mimeType.includes('zip') || mimeType.includes('archive') || mimeType.includes('compressed')) {
      return 'M5 8h14M5 8a2 2 0 110-4h14a2 2 0 110 4M5 8v10a2 2 0 002 2h10a2 2 0 002-2V8m-9 4h4'
    }

    return 'M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z'
  }

  function isImageFile(file: FileMetadata): boolean {
    return file.mime_type?.startsWith('image/') ?? false
  }

  function getFileUrl(file: FileMetadata): string {
    // Construct file URL based on API base URL
    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8080'
    return `${apiUrl}/api/files/${file.id}`
  }

  function handlePreview(file: FileMetadata) {
    onPreview?.(file)
  }

  function handleDownload(file: FileMetadata) {
    onDownload?.(file)
  }

  function handleDelete(file: FileMetadata) {
    onDelete?.(file)
  }

  function handleCopyUrl(file: FileMetadata) {
    onCopyUrl?.(file)
  }
</script>

<div class="space-y-4">
  <!-- Search -->
  <div class="relative">
    <input
      type="text"
      bind:value={searchTerm}
      placeholder="Search files by name or type..."
      class="block w-full rounded-lg border border-secondary-300 pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
    />
    <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
      <svg class="h-5 w-5 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
      </svg>
    </div>
  </div>

  <!-- Results Count -->
  <div class="text-sm text-secondary-600">
    Showing {filteredFiles.length} of {files.length} files
  </div>

  <!-- File Grid -->
  {#if isLoading}
    <div class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      <p class="mt-2 text-sm text-secondary-600">Loading files...</p>
    </div>
  {:else if filteredFiles.length === 0}
    <div class="text-center py-12 bg-white rounded-lg border border-secondary-200">
      <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-secondary-900">No files found</h3>
      <p class="mt-1 text-sm text-secondary-500">
        {searchTerm ? 'Try adjusting your search' : 'Upload some files to get started'}
      </p>
    </div>
  {:else}
    <div class="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4">
      {#each filteredFiles as file (file.id)}
        <div class="bg-white rounded-lg border border-secondary-200 overflow-hidden hover:shadow-md transition-shadow">
          <!-- File Thumbnail/Icon -->
          <div
            class="h-48 bg-secondary-50 flex items-center justify-center cursor-pointer"
            onclick={() => handlePreview(file)}
            role="button"
            tabindex="0"
            onkeydown={(e) => e.key === 'Enter' && handlePreview(file)}
          >
            {#if isImageFile(file)}
              <img
                src={getFileUrl(file)}
                alt={file.name}
                class="h-full w-full object-cover"
              />
            {:else}
              <svg class="h-16 w-16 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={getFileIcon(file)} />
              </svg>
            {/if}
          </div>

          <!-- File Info -->
          <div class="p-4">
            <div class="flex items-start justify-between">
              <div class="flex-1 min-w-0">
                <h3 class="text-sm font-medium text-secondary-900 truncate" title={file.name}>
                  {file.name}
                </h3>
                <div class="mt-1 flex items-center space-x-2 text-xs text-secondary-500">
                  <span>{formatBytes(file.size)}</span>
                  <span>•</span>
                  <span>{formatRelativeTime(file.created_at)}</span>
                </div>
                {#if file.mime_type}
                  <div class="mt-2">
                    <Badge variant="default" size="sm">{file.mime_type}</Badge>
                  </div>
                {/if}
              </div>
            </div>

            <!-- Actions -->
            <div class="mt-4 flex items-center space-x-2">
              {#if onPreview}
                <button
                  type="button"
                  class="flex-1 px-2 py-1 text-xs text-primary-600 hover:text-primary-800 border border-primary-200 rounded hover:bg-primary-50 transition-colors"
                  onclick={() => handlePreview(file)}
                  title="Preview"
                >
                  View
                </button>
              {/if}

              {#if onDownload}
                <button
                  type="button"
                  class="flex-1 px-2 py-1 text-xs text-secondary-600 hover:text-secondary-800 border border-secondary-200 rounded hover:bg-secondary-50 transition-colors"
                  onclick={() => handleDownload(file)}
                  title="Download"
                >
                  Download
                </button>
              {/if}

              {#if onCopyUrl}
                <button
                  type="button"
                  class="p-1 text-secondary-400 hover:text-secondary-600 transition-colors"
                  onclick={() => handleCopyUrl(file)}
                  title="Copy URL"
                >
                  <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                </button>
              {/if}

              {#if onDelete}
                <button
                  type="button"
                  class="p-1 text-secondary-400 hover:text-red-600 transition-colors"
                  onclick={() => handleDelete(file)}
                  title="Delete"
                >
                  <svg class="h-4 w-4" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                  </svg>
                </button>
              {/if}
            </div>
          </div>
        </div>
      {/each}
    </div>
  {/if}
</div>
