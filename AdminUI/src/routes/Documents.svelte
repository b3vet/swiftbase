<script lang="ts">
  import { onMount } from 'svelte'
  import { router } from '@lib/router.svelte'
  import { notificationsStore } from '@lib/stores'
  import { queryApi } from '@lib/api'
  import { formatDate } from '@lib/utils'
  import { Card, Button, Modal, Spinner, Alert } from '@components/common'
  import { DocumentList, DocumentEditor } from '@components/documents'

  const collectionName = $derived(router.getParam('name') || '')

  let documents = $state<any[]>([])
  let selectedDocument = $state<any | null>(null)
  let showCreateModal = $state(false)
  let showEditModal = $state(false)
  let showViewModal = $state(false)
  let showDeleteModal = $state(false)
  let isLoading = $state(true)
  let isSubmitting = $state(false)
  let error = $state<string | null>(null)

  onMount(async () => {
    await fetchDocuments()
  })

  async function fetchDocuments() {
    if (!collectionName) return

    isLoading = true
    error = null

    try {
      const response = await queryApi.find(collectionName, {}, {
        orderBy: { updated_at: 'desc' },
        limit: 1000
      })

      if (response.success && response.data) {
        // Map documents to include proper structure
        documents = Array.isArray(response.data)
          ? response.data.map((item: any) => ({
              id: item._id || item.id,
              data: item,
              version: item.version || 1,
              created_at: item.created_at || new Date().toISOString(),
              updated_at: item.updated_at || new Date().toISOString()
            }))
          : []
      } else {
        error = response.error || 'Failed to fetch documents'
      }
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to fetch documents'
    } finally {
      isLoading = false
    }
  }

  async function handleCreate(data: any): Promise<boolean> {
    isSubmitting = true

    try {
      const response = await queryApi.create(collectionName, data)

      if (response.success) {
        showCreateModal = false
        notificationsStore.success('Document created successfully')
        await fetchDocuments()
        return true
      } else {
        notificationsStore.error(response.error || 'Failed to create document')
        return false
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to create document'
      notificationsStore.error(message)
      return false
    } finally {
      isSubmitting = false
    }
  }

  async function handleUpdate(data: any): Promise<boolean> {
    if (!selectedDocument) return false

    isSubmitting = true

    try {
      const response = await queryApi.update(
        collectionName,
        { _id: selectedDocument.id },
        { $set: data },
        { returnNew: true }
      )

      if (response.success) {
        showEditModal = false
        selectedDocument = null
        notificationsStore.success('Document updated successfully')
        await fetchDocuments()
        return true
      } else {
        notificationsStore.error(response.error || 'Failed to update document')
        return false
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update document'
      notificationsStore.error(message)
      return false
    } finally {
      isSubmitting = false
    }
  }

  async function handleDelete() {
    if (!selectedDocument) return

    isSubmitting = true

    try {
      const response = await queryApi.delete(collectionName, { _id: selectedDocument.id })

      if (response.success) {
        showDeleteModal = false
        selectedDocument = null
        notificationsStore.success('Document deleted successfully')
        await fetchDocuments()
      } else {
        notificationsStore.error(response.error || 'Failed to delete document')
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete document'
      notificationsStore.error(message)
    } finally {
      isSubmitting = false
    }
  }

  function openCreateModal() {
    showCreateModal = true
  }

  function openViewModal(document: any) {
    selectedDocument = document
    showViewModal = true
  }

  function openEditModal(document: any) {
    selectedDocument = document
    showEditModal = true
  }

  function openDeleteModal(document: any) {
    selectedDocument = document
    showDeleteModal = true
  }

  function closeModals() {
    showCreateModal = false
    showEditModal = false
    showViewModal = false
    showDeleteModal = false
    selectedDocument = null
  }

  function goBack() {
    router.navigate(`/collections/${collectionName}`)
  }
</script>

<div class="space-y-6">
  <!-- Header with Back Button -->
  <div class="flex items-center justify-between">
    <div class="flex items-center space-x-4">
      <Button variant="ghost" onclick={goBack}>
        <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 19l-7-7 7-7" />
        </svg>
        Back
      </Button>
      <div>
        <h1 class="text-3xl font-bold text-secondary-900">Documents</h1>
        <p class="mt-2 text-secondary-600">
          Collection: <span class="font-medium">{collectionName}</span>
        </p>
      </div>
    </div>
    <Button variant="primary" onclick={openCreateModal}>
      <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
      </svg>
      Create Document
    </Button>
  </div>

  <!-- Error Display -->
  {#if error}
    <Alert type="error" dismissible ondismiss={() => (error = null)}>
      {error}
    </Alert>
  {/if}

  <!-- Loading State -->
  {#if isLoading}
    <Card>
      <div class="flex justify-center items-center py-12">
        <Spinner size="lg" />
      </div>
    </Card>

  <!-- Empty State -->
  {:else if documents.length === 0}
    <Card>
      <div class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-secondary-900">No documents</h3>
        <p class="mt-1 text-sm text-secondary-500">
          Get started by creating a new document
        </p>
        <div class="mt-6">
          <Button variant="primary" onclick={openCreateModal}>
            <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Create Document
          </Button>
        </div>
      </div>
    </Card>

  <!-- Documents List -->
  {:else}
    <DocumentList
      {documents}
      onView={openViewModal}
      onEdit={openEditModal}
      onDelete={openDeleteModal}
    />
  {/if}
</div>

<!-- Create Modal -->
<Modal
  bind:open={showCreateModal}
  title="Create Document"
  size="xl"
  onclose={closeModals}
>
  <DocumentEditor
    onSubmit={handleCreate}
    onCancel={closeModals}
    isLoading={isSubmitting}
  />
</Modal>

<!-- Edit Modal -->
<Modal
  bind:open={showEditModal}
  title="Edit Document"
  size="xl"
  onclose={closeModals}
>
  {#if selectedDocument}
    <DocumentEditor
      document={selectedDocument}
      onSubmit={handleUpdate}
      onCancel={closeModals}
      isLoading={isSubmitting}
    />
  {/if}
</Modal>

<!-- View Modal -->
<Modal
  bind:open={showViewModal}
  title="View Document"
  size="xl"
  onclose={closeModals}
>
  {#if selectedDocument}
    <div class="space-y-4">
      <!-- Document Data -->
      <div>
        <h4 class="text-sm font-medium text-secondary-900 mb-2">Document Data</h4>
        <pre class="bg-secondary-50 p-4 rounded-lg overflow-x-auto text-sm"><code>{JSON.stringify(selectedDocument.data, null, 2)}</code></pre>
      </div>

      <!-- Metadata -->
      <div class="bg-secondary-50 rounded-lg p-4">
        <h4 class="text-sm font-medium text-secondary-900 mb-2">Metadata</h4>
        <dl class="grid grid-cols-2 gap-4 text-xs">
          <div>
            <dt class="text-secondary-500">ID</dt>
            <dd class="mt-1 font-mono text-secondary-900">{selectedDocument.id}</dd>
          </div>
          <div>
            <dt class="text-secondary-500">Version</dt>
            <dd class="mt-1 text-secondary-900">v{selectedDocument.version}</dd>
          </div>
          <div>
            <dt class="text-secondary-500">Created</dt>
            <dd class="mt-1 text-secondary-900">
              {formatDate(selectedDocument.created_at)}
            </dd>
          </div>
          <div>
            <dt class="text-secondary-500">Updated</dt>
            <dd class="mt-1 text-secondary-900">
              {formatDate(selectedDocument.updated_at)}
            </dd>
          </div>
        </dl>
      </div>

      <!-- Actions -->
      <div class="flex justify-end space-x-3">
        <Button variant="ghost" onclick={closeModals}>
          Close
        </Button>
        <Button
          variant="primary"
          onclick={() => {
            showViewModal = false
            openEditModal(selectedDocument)
          }}
        >
          Edit Document
        </Button>
      </div>
    </div>
  {/if}
</Modal>

<!-- Delete Confirmation Modal -->
<Modal
  bind:open={showDeleteModal}
  title="Delete Document"
  size="sm"
  onclose={closeModals}
>
  {#if selectedDocument}
    <div class="space-y-4">
      <Alert type="warning">
        This action cannot be undone. The document will be permanently deleted.
      </Alert>

      <p class="text-sm text-secondary-700">
        Are you sure you want to delete this document?
      </p>

      <div class="flex justify-end space-x-3">
        <Button variant="ghost" onclick={closeModals} disabled={isSubmitting}>
          Cancel
        </Button>
        <Button variant="danger" onclick={handleDelete} loading={isSubmitting} disabled={isSubmitting}>
          Delete Document
        </Button>
      </div>
    </div>
  {/if}
</Modal>
