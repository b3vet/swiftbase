<script lang="ts">
  import { onMount } from 'svelte'
  import type { FileMetadata } from '@lib/types'
  import { notificationsStore } from '@lib/stores'
  import { filesApi } from '@lib/api'
  import { Card, Modal, Button, Alert } from '@components/common'
  import { FileUploader, FileList, FilePreview } from '@components/files'

  let files = $state<FileMetadata[]>([])
  let selectedFile = $state<FileMetadata | null>(null)
  let isLoading = $state(false)
  let isUploading = $state(false)
  let showPreviewModal = $state(false)
  let showDeleteModal = $state(false)
  let error = $state<string | null>(null)

  onMount(async () => {
    await loadFiles()
  })

  async function loadFiles() {
    isLoading = true
    error = null

    try {
      const response = await filesApi.list()

      if (response.success) {
        files = response.data
      } else {
        error = response.error || 'Failed to load files'
        notificationsStore.error(error)
      }
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to load files'
      notificationsStore.error(error)
    } finally {
      isLoading = false
    }
  }

  async function handleUpload(uploadFiles: File[]) {
    isUploading = true

    try {
      const uploadPromises = uploadFiles.map((file) =>
        filesApi.upload(file, (progress) => {
          // Could track progress per file here if needed
          console.log(`Uploading ${file.name}: ${progress}%`)
        })
      )

      const responses = await Promise.all(uploadPromises)

      const successCount = responses.filter((r) => r.success).length
      const failCount = responses.length - successCount

      if (successCount > 0) {
        notificationsStore.success(
          `Successfully uploaded ${successCount} file${successCount > 1 ? 's' : ''}`
        )
        await loadFiles()
      }

      if (failCount > 0) {
        notificationsStore.error(
          `Failed to upload ${failCount} file${failCount > 1 ? 's' : ''}`
        )
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Upload failed'
      notificationsStore.error(message)
    } finally {
      isUploading = false
    }
  }

  function openPreviewModal(file: FileMetadata) {
    selectedFile = file
    showPreviewModal = true
  }

  function openDeleteModal(file: FileMetadata) {
    selectedFile = file
    showDeleteModal = true
  }

  async function handleDownload(file: FileMetadata) {
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8080'
      const fileUrl = `${apiUrl}/api/files/${file.id}`

      // Create a temporary link and trigger download
      const link = document.createElement('a')
      link.href = fileUrl
      link.download = file.name
      link.target = '_blank'
      document.body.appendChild(link)
      link.click()
      document.body.removeChild(link)

      notificationsStore.success('Download started')
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Download failed'
      notificationsStore.error(message)
    }
  }

  async function handleDelete() {
    if (!selectedFile) return

    try {
      const response = await filesApi.delete(selectedFile.id)

      if (response.success) {
        notificationsStore.success('File deleted successfully')
        showDeleteModal = false
        selectedFile = null
        await loadFiles()
      } else {
        throw new Error(response.error || 'Failed to delete file')
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete file'
      notificationsStore.error(message)
    }
  }

  async function handleCopyUrl(file: FileMetadata) {
    try {
      const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8080'
      const fileUrl = `${apiUrl}/api/files/${file.id}`

      await navigator.clipboard.writeText(fileUrl)
      notificationsStore.success('File URL copied to clipboard')
    } catch (err) {
      notificationsStore.error('Failed to copy URL')
    }
  }

  function closeModals() {
    showPreviewModal = false
    showDeleteModal = false
    selectedFile = null
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div>
    <h1 class="text-3xl font-bold text-secondary-900">File Storage</h1>
    <p class="mt-2 text-secondary-600">
      Upload, manage, and organize your files
    </p>
  </div>

  <!-- Error Alert -->
  {#if error && !isLoading}
    <Alert type="error" dismissible ondismiss={() => (error = null)}>
      {error}
    </Alert>
  {/if}

  <!-- File Uploader -->
  <Card title="Upload Files" subtitle="Drag and drop or click to select files">
    <FileUploader
      onUpload={handleUpload}
      multiple={true}
      isLoading={isUploading}
    />
  </Card>

  <!-- File List -->
  <Card title="Files" subtitle={`${files.length} file${files.length !== 1 ? 's' : ''} total`}>
    <FileList
      {files}
      {isLoading}
      onPreview={openPreviewModal}
      onDownload={handleDownload}
      onDelete={openDeleteModal}
      onCopyUrl={handleCopyUrl}
    />
  </Card>
</div>

<!-- Preview Modal -->
<Modal
  bind:open={showPreviewModal}
  title="File Preview"
  size="xl"
  onclose={closeModals}
>
  {#if selectedFile}
    <FilePreview file={selectedFile} />
  {/if}
</Modal>

<!-- Delete Confirmation Modal -->
<Modal
  bind:open={showDeleteModal}
  title="Delete File"
  size="sm"
  onclose={closeModals}
>
  <div class="space-y-4">
    <Alert type="warning">
      Are you sure you want to delete this file? This action cannot be undone.
    </Alert>

    {#if selectedFile}
      <div class="bg-secondary-50 p-4 rounded-lg">
        <p class="text-sm text-secondary-900">
          <span class="font-medium">File:</span> {selectedFile.name}
        </p>
        <p class="text-sm text-secondary-500 mt-1">
          <span class="font-medium">ID:</span> {selectedFile.id}
        </p>
      </div>
    {/if}

    <div class="flex justify-end space-x-3">
      <Button variant="ghost" onclick={closeModals}>
        Cancel
      </Button>
      <Button variant="danger" onclick={handleDelete}>
        Delete File
      </Button>
    </div>
  </div>
</Modal>
