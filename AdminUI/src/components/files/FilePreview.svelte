<script lang="ts">
  import type { FileMetadata } from '@lib/types'
  import { Badge } from '@components/common'
  import { formatBytes, formatDate } from '@lib/utils'

  interface Props {
    file: FileMetadata
  }

  let { file }: Props = $props()

  function getFileUrl(file: FileMetadata): string {
    const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8080'
    return `${apiUrl}/api/files/${file.id}`
  }

  function isImageFile(file: FileMetadata): boolean {
    return file.mime_type?.startsWith('image/') ?? false
  }

  function isVideoFile(file: FileMetadata): boolean {
    return file.mime_type?.startsWith('video/') ?? false
  }

  function isAudioFile(file: FileMetadata): boolean {
    return file.mime_type?.startsWith('audio/') ?? false
  }

  function isTextFile(file: FileMetadata): boolean {
    const textTypes = ['text/', 'application/json', 'application/javascript']
    return textTypes.some((type) => file.mime_type?.includes(type)) ?? false
  }

  function isPdfFile(file: FileMetadata): boolean {
    return file.mime_type?.includes('pdf') ?? false
  }
</script>

<div class="space-y-6">
  <!-- File Preview -->
  <div class="bg-secondary-50 rounded-lg overflow-hidden">
    {#if isImageFile(file)}
      <img
        src={getFileUrl(file)}
        alt={file.name}
        class="w-full h-auto max-h-[600px] object-contain"
      />
    {:else if isVideoFile(file)}
      <video
        src={getFileUrl(file)}
        controls
        class="w-full h-auto max-h-[600px]"
      >
        <track kind="captions" />
        Your browser does not support the video tag.
      </video>
    {:else if isAudioFile(file)}
      <div class="p-12 flex items-center justify-center">
        <div class="w-full max-w-md">
          <div class="text-center mb-6">
            <svg class="mx-auto h-16 w-16 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 19V6l12-3v13M9 19c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zm12-3c0 1.105-1.343 2-3 2s-3-.895-3-2 1.343-2 3-2 3 .895 3 2zM9 10l12-3" />
            </svg>
          </div>
          <audio
            src={getFileUrl(file)}
            controls
            class="w-full"
          >
            Your browser does not support the audio element.
          </audio>
        </div>
      </div>
    {:else if isPdfFile(file)}
      <div class="p-12 text-center">
        <svg class="mx-auto h-16 w-16 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
        </svg>
        <h3 class="mt-4 text-sm font-medium text-secondary-900">PDF Document</h3>
        <p class="mt-1 text-sm text-secondary-500">
          Preview not available. Download the file to view it.
        </p>
      </div>
    {:else}
      <div class="p-12 text-center">
        <svg class="mx-auto h-16 w-16 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
        </svg>
        <h3 class="mt-4 text-sm font-medium text-secondary-900">Preview not available</h3>
        <p class="mt-1 text-sm text-secondary-500">
          This file type cannot be previewed in the browser
        </p>
      </div>
    {/if}
  </div>

  <!-- File Metadata -->
  <div class="bg-white rounded-lg border border-secondary-200 p-6">
    <h3 class="text-lg font-semibold text-secondary-900 mb-4">File Information</h3>

    <dl class="grid grid-cols-1 gap-4 sm:grid-cols-2">
      <div>
        <dt class="text-sm font-medium text-secondary-500">File Name</dt>
        <dd class="mt-1 text-sm text-secondary-900 break-all">{file.name}</dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-secondary-500">File Size</dt>
        <dd class="mt-1 text-sm text-secondary-900">{formatBytes(file.size)}</dd>
      </div>

      <div>
        <dt class="text-sm font-medium text-secondary-500">File Type</dt>
        <dd class="mt-1">
          {#if file.mime_type}
            <Badge variant="default">{file.mime_type}</Badge>
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

      <div>
        <dt class="text-sm font-medium text-secondary-500">Updated At</dt>
        <dd class="mt-1 text-sm text-secondary-900">{formatDate(file.updated_at)}</dd>
      </div>

      {#if file.user_id}
        <div>
          <dt class="text-sm font-medium text-secondary-500">Uploaded By</dt>
          <dd class="mt-1 text-sm text-secondary-900 font-mono">{file.user_id}</dd>
        </div>
      {/if}

      <div>
        <dt class="text-sm font-medium text-secondary-500">File URL</dt>
        <dd class="mt-1 text-sm text-primary-600 break-all">
          <a href={getFileUrl(file)} target="_blank" rel="noopener noreferrer" class="hover:underline">
            {getFileUrl(file)}
          </a>
        </dd>
      </div>
    </dl>
  </div>
</div>
