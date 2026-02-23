<script lang="ts">
  import { onMount, onDestroy } from 'svelte'
  import type { FileMetadata } from '@lib/types'
  import { Badge, Button } from '@components/common'
  import { formatBytes, formatDate, canPreviewFile, createBlobUrl, revokeBlobUrl } from '@lib/utils'

  interface Props {
    file: FileMetadata
  }

  let { file }: Props = $props()

  let blobUrl = $state<string | null>(null)
  let isLoadingPreview = $state(false)
  let previewError = $state<string | null>(null)

  const canPreview = $derived(canPreviewFile(file.size))
  const isPreviewable = $derived(
    canPreview && (isImageFile(file) || isVideoFile(file) || isAudioFile(file) || isPdfFile(file))
  )

  function isImageFile(file: FileMetadata): boolean {
    return file.content_type?.startsWith('image/') ?? false
  }

  function isVideoFile(file: FileMetadata): boolean {
    return file.content_type?.startsWith('video/') ?? false
  }

  function isAudioFile(file: FileMetadata): boolean {
    return file.content_type?.startsWith('audio/') ?? false
  }

  function isTextFile(file: FileMetadata): boolean {
    const textTypes = ['text/', 'application/json', 'application/javascript']
    return textTypes.some((type) => file.content_type?.includes(type)) ?? false
  }

  function isPdfFile(file: FileMetadata): boolean {
    return file.content_type?.includes('pdf') ?? false
  }

  async function loadPreview() {
    if (!isPreviewable) return

    isLoadingPreview = true
    previewError = null

    try {
      blobUrl = await createBlobUrl(file.id)
    } catch (error) {
      previewError = error instanceof Error ? error.message : 'Failed to load preview'
      console.error('Preview error:', error)
    } finally {
      isLoadingPreview = false
    }
  }

  async function handleDownload() {
    try {
      // Fetch file with authentication
      const blobUrl = await createBlobUrl(file.id)

      // Create a download link and trigger download
      const link = document.createElement('a')
      link.href = blobUrl
      link.download = file.original_name
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)

      // Cleanup blob URL after download
      setTimeout(() => revokeBlobUrl(blobUrl), 100)
    } catch (error) {
      console.error('Download failed:', error)
    }
  }

  onMount(() => {
    loadPreview()
  })

  onDestroy(() => {
    if (blobUrl) {
      revokeBlobUrl(blobUrl)
    }
  })
</script>

<div class="space-y-6">
  <!-- File Preview -->
  <div class="bg-secondary-50 rounded-lg overflow-hidden">
    {#if isLoadingPreview}
      <div class="p-12 text-center">
        <div class="inline-block animate-spin rounded-full h-12 w-12 border-b-2 border-primary-600"></div>
        <p class="mt-4 text-sm text-secondary-600">Loading preview...</p>
      </div>
    {:else if previewError}
      <div class="p-12 text-center">
        <svg class="mx-auto h-16 w-16 text-danger-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 8v4m0 4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
        </svg>
        <h3 class="mt-4 text-sm font-medium text-secondary-900">Failed to load preview</h3>
        <p class="mt-1 text-sm text-secondary-500">{previewError}</p>
        <div class="mt-4">
          <Button variant="primary" size="sm" onclick={handleDownload}>
            Download File
          </Button>
        </div>
      </div>
    {:else if !canPreview}
      <div class="p-12 text-center">
        <svg class="mx-auto h-16 w-16 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
        </svg>
        <h3 class="mt-4 text-sm font-medium text-secondary-900">File too large for preview</h3>
        <p class="mt-1 text-sm text-secondary-500">
          This file is {formatBytes(file.size)} (max preview size: 10 MB)
        </p>
        <p class="mt-1 text-sm text-secondary-500">
          Download the file to view it
        </p>
        <div class="mt-4">
          <Button variant="primary" size="sm" onclick={handleDownload}>
            <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 16v1a3 3 0 003 3h10a3 3 0 003-3v-1m-4-4l-4 4m0 0l-4-4m4 4V4" />
            </svg>
            Download File
          </Button>
        </div>
      </div>
    {:else if !isPreviewable}
      <div class="p-12 text-center">
        <svg class="mx-auto h-16 w-16 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
        </svg>
        <h3 class="mt-4 text-sm font-medium text-secondary-900">Preview not available</h3>
        <p class="mt-1 text-sm text-secondary-500">
          This file type cannot be previewed in the browser
        </p>
        <div class="mt-4">
          <Button variant="primary" size="sm" onclick={handleDownload}>
            Download File
          </Button>
        </div>
      </div>
    {:else if blobUrl && isImageFile(file)}
      <img
        src={blobUrl}
        alt={file.original_name}
        class="w-full h-auto max-h-[600px] object-contain"
      />
    {:else if blobUrl && isVideoFile(file)}
      <video
        src={blobUrl}
        controls
        class="w-full h-auto max-h-[600px]"
      >
        <track kind="captions" />
        Your browser does not support the video tag.
      </video>
    {:else if blobUrl && isAudioFile(file)}
      <div class="p-12 flex items-center justify-center">
        <div class="w-full max-w-md">
          <div class="text-center mb-6">
            <svg class="mx-auto h-16 w-16 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3" />
            </svg>
          </div>
          <audio
            src={blobUrl}
            controls
            class="w-full"
          >
            Your browser does not support the audio element.
          </audio>
        </div>
      </div>
    {:else if blobUrl && isPdfFile(file)}
      <iframe
        src={blobUrl}
        title={file.original_name}
        class="w-full h-[600px] border-0"
      ></iframe>
    {/if}
  </div>

  <!-- File Metadata -->
  <div class="bg-white rounded-lg border border-secondary-200 p-6">
    <h3 class="text-lg font-semibold text-secondary-900 mb-4">File Information</h3>

    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div>
        <dt class="text-sm font-medium text-secondary-500">File Name</dt>
        <dd class="mt-1 text-sm text-secondary-900 break-all">{file.original_name}</dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-secondary-500">File Size</dt>
        <dd class="mt-1 text-sm text-secondary-900">{formatBytes(file.size)}</dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-secondary-500">File Type</dt>
        <dd class="mt-1">
          {#if file.content_type}
            <Badge variant="default">{file.content_type}</Badge>
          {:else}
            <span class="text-sm text-secondary-500">Unknown</span>
          {/if}
        </dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-secondary-500">File ID</dt>
        <dd class="mt-1 text-sm text-secondary-900 font-mono break-all">{file.id}</dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-secondary-500">Created At</dt>
        <dd class="mt-1 text-sm text-secondary-900">{formatDate(file.created_at)}</dd>
      </div>
    </dl>
  </div>
</div>
