<script lang="ts">
  import { onMount } from 'svelte'
  import type { Collection, CreateCollectionRequest } from '@lib/types'
  import { collectionsStore, notificationsStore } from '@lib/stores'
  import { Card, Button, Modal, Spinner, Alert } from '@components/common'
  import { CollectionList, CollectionForm } from '@components/collections'

  let showCreateModal = $state(false)
  let showEditModal = $state(false)
  let showDeleteModal = $state(false)
  let selectedCollection = $state<Collection | null>(null)
  let isSubmitting = $state(false)

  onMount(async () => {
    await collectionsStore.fetchAll()
  })

  async function handleCreate(data: CreateCollectionRequest): Promise<boolean> {
    isSubmitting = true

    const success = await collectionsStore.create(data)

    if (success) {
      showCreateModal = false
      notificationsStore.success(`Collection "${data.name}" created successfully`)
    } else if (collectionsStore.error) {
      notificationsStore.error(collectionsStore.error)
    }

    isSubmitting = false
    return success
  }

  async function handleEdit(data: CreateCollectionRequest): Promise<boolean> {
    if (!selectedCollection) return false

    isSubmitting = true

    const collectionName = selectedCollection.name
    const success = await collectionsStore.update(collectionName, data as any)

    if (success) {
      showEditModal = false
      selectedCollection = null
      notificationsStore.success(`Collection "${collectionName}" updated successfully`)
    } else if (collectionsStore.error) {
      notificationsStore.error(collectionsStore.error)
    }

    isSubmitting = false
    return success
  }

  async function handleDelete() {
    if (!selectedCollection) return

    isSubmitting = true

    const success = await collectionsStore.remove(selectedCollection.name)

    if (success) {
      showDeleteModal = false
      notificationsStore.success(`Collection "${selectedCollection.name}" deleted successfully`)
      selectedCollection = null
    } else if (collectionsStore.error) {
      notificationsStore.error(collectionsStore.error)
    }

    isSubmitting = false
  }

  function openCreateModal() {
    showCreateModal = true
  }

  function openEditModal(collection: Collection) {
    selectedCollection = collection
    showEditModal = true
  }

  function openDeleteModal(collection: Collection) {
    selectedCollection = collection
    showDeleteModal = true
  }

  function closeModals() {
    showCreateModal = false
    showEditModal = false
    showDeleteModal = false
    selectedCollection = null
    collectionsStore.clearError()
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-3xl font-bold text-secondary-900">Collections</h1>
      <p class="mt-2 text-secondary-600">
        Manage your data collections
      </p>
    </div>
    <Button variant="primary" onclick={openCreateModal}>
      <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
      </svg>
      Create Collection
    </Button>
  </div>

  <!-- Loading State -->
  {#if collectionsStore.isLoading}
    <Card>
      <div class="flex justify-center items-center py-12">
        <Spinner size="lg" />
      </div>
    </Card>

  <!-- Empty State -->
  {:else if collectionsStore.collections.length === 0}
    <Card>
      <div class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-secondary-900">No collections</h3>
        <p class="mt-1 text-sm text-secondary-500">
          Get started by creating a new collection
        </p>
        <div class="mt-6">
          <Button variant="primary" onclick={openCreateModal}>
            <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
            </svg>
            Create Collection
          </Button>
        </div>
      </div>
    </Card>

  <!-- Collections List -->
  {:else}
    <CollectionList
      collections={collectionsStore.collections}
      onEdit={openEditModal}
      onDelete={openDeleteModal}
    />
  {/if}

  <!-- Error Display -->
  {#if collectionsStore.error}
    <Alert type="error" dismissible ondismiss={() => collectionsStore.clearError()}>
      {collectionsStore.error}
    </Alert>
  {/if}
</div>

<!-- Create Modal -->
<Modal
  bind:open={showCreateModal}
  title="Create Collection"
  size="lg"
  onclose={closeModals}
>
  <CollectionForm
    onSubmit={handleCreate}
    onCancel={closeModals}
    isLoading={isSubmitting}
  />
</Modal>

<!-- Edit Modal -->
<Modal
  bind:open={showEditModal}
  title="Edit Collection"
  size="lg"
  onclose={closeModals}
>
  {#if selectedCollection}
    <CollectionForm
      collection={selectedCollection}
      onSubmit={handleEdit}
      onCancel={closeModals}
      isLoading={isSubmitting}
    />
  {/if}
</Modal>

<!-- Delete Confirmation Modal -->
<Modal
  bind:open={showDeleteModal}
  title="Delete Collection"
  size="sm"
  onclose={closeModals}
>
  {#if selectedCollection}
    <div class="space-y-4">
      <Alert type="warning">
        This action cannot be undone. All documents in this collection will be permanently deleted.
      </Alert>

      <p class="text-sm text-secondary-700">
        Are you sure you want to delete the collection <strong>{selectedCollection.name}</strong>?
      </p>

      <div class="flex justify-end space-x-3">
        <Button variant="ghost" onclick={closeModals} disabled={isSubmitting}>
          Cancel
        </Button>
        <Button variant="danger" onclick={handleDelete} loading={isSubmitting} disabled={isSubmitting}>
          Delete Collection
        </Button>
      </div>
    </div>
  {/if}
</Modal>
