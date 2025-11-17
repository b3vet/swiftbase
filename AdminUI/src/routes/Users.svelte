<script lang="ts">
  import { onMount } from 'svelte'
  import type { User } from '@lib/types'
  import { notificationsStore } from '@lib/stores'
  import { usersApi } from '@lib/api'
  import { Card, Modal, Button, Alert } from '@components/common'
  import { UserList, UserForm, UserDetail } from '@components/users'

  let users = $state<User[]>([])
  let selectedUser = $state<User | null>(null)
  let isLoading = $state(false)
  let isSubmitting = $state(false)
  let showCreateModal = $state(false)
  let showEditModal = $state(false)
  let showDeleteModal = $state(false)
  let showDetailModal = $state(false)
  let error = $state<string | null>(null)

  onMount(async () => {
    await loadUsers()
  })

  async function loadUsers() {
    isLoading = true
    error = null

    try {
      const response = await usersApi.list()

      if (response.success) {
        users = response.data
      } else {
        error = response.error || 'Failed to load users'
        notificationsStore.error(error)
      }
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to load users'
      notificationsStore.error(error)
    } finally {
      isLoading = false
    }
  }

  async function handleCreateUser(data: { email: string; password?: string; metadata: Record<string, any> }) {
    if (!data.password) {
      notificationsStore.error('Password is required for new users')
      return
    }

    isSubmitting = true

    try {
      const response = await usersApi.create({
        email: data.email,
        password: data.password,
        metadata: data.metadata
      })

      if (response.success) {
        notificationsStore.success('User created successfully')
        showCreateModal = false
        await loadUsers()
      } else {
        throw new Error(response.error || 'Failed to create user')
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to create user'
      notificationsStore.error(message)
      throw err
    } finally {
      isSubmitting = false
    }
  }

  async function handleUpdateUser(data: { email: string; password?: string; metadata: Record<string, any> }) {
    if (!selectedUser) return

    isSubmitting = true

    try {
      const updateData: any = {
        metadata: data.metadata
      }

      if (data.password) {
        updateData.password = data.password
      }

      const response = await usersApi.update(selectedUser.id, updateData)

      if (response.success) {
        notificationsStore.success('User updated successfully')
        showEditModal = false
        selectedUser = null
        await loadUsers()
      } else {
        throw new Error(response.error || 'Failed to update user')
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update user'
      notificationsStore.error(message)
      throw err
    } finally {
      isSubmitting = false
    }
  }

  async function handleDeleteUser() {
    if (!selectedUser) return

    isSubmitting = true

    try {
      const response = await usersApi.delete(selectedUser.id)

      if (response.success) {
        notificationsStore.success('User deleted successfully')
        showDeleteModal = false
        showDetailModal = false
        selectedUser = null
        await loadUsers()
      } else {
        throw new Error(response.error || 'Failed to delete user')
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete user'
      notificationsStore.error(message)
    } finally {
      isSubmitting = false
    }
  }

  async function handleVerifyUser(user: User) {
    isSubmitting = true

    try {
      const response = await usersApi.update(user.id, {
        email_verified: true
      })

      if (response.success) {
        notificationsStore.success('User verified successfully')
        await loadUsers()

        // Update the selected user if it's the detail view
        if (selectedUser?.id === user.id) {
          selectedUser = response.data
        }
      } else {
        throw new Error(response.error || 'Failed to verify user')
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to verify user'
      notificationsStore.error(message)
    } finally {
      isSubmitting = false
    }
  }

  function openCreateModal() {
    selectedUser = null
    showCreateModal = true
  }

  function openEditModal(user: User) {
    selectedUser = user
    showEditModal = true
  }

  function openDeleteModal(user: User) {
    selectedUser = user
    showDeleteModal = true
  }

  function openDetailModal(user: User) {
    selectedUser = user
    showDetailModal = true
  }

  function closeModals() {
    showCreateModal = false
    showEditModal = false
    showDeleteModal = false
    showDetailModal = false
    selectedUser = null
  }
</script>

<div class="space-y-6">
  <!-- Header -->
  <div class="flex items-center justify-between">
    <div>
      <h1 class="text-3xl font-bold text-secondary-900">User Management</h1>
      <p class="mt-2 text-secondary-600">
        Manage user accounts and permissions
      </p>
    </div>
    <Button variant="primary" onclick={openCreateModal}>
      <svg class="h-5 w-5 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4v16m8-8H4" />
      </svg>
      Create User
    </Button>
  </div>

  <!-- Error Alert -->
  {#if error && !isLoading}
    <Alert type="error" dismissible ondismiss={() => (error = null)}>
      {error}
    </Alert>
  {/if}

  <!-- User List -->
  <UserList
    {users}
    {isLoading}
    onEdit={openEditModal}
    onDelete={openDeleteModal}
    onView={openDetailModal}
  />
</div>

<!-- Create User Modal -->
<Modal
  bind:open={showCreateModal}
  title="Create User"
  size="md"
  onclose={closeModals}
>
  <UserForm
    onSubmit={handleCreateUser}
    onCancel={closeModals}
    isLoading={isSubmitting}
  />
</Modal>

<!-- Edit User Modal -->
<Modal
  bind:open={showEditModal}
  title="Edit User"
  size="md"
  onclose={closeModals}
>
  <UserForm
    user={selectedUser}
    onSubmit={handleUpdateUser}
    onCancel={closeModals}
    isLoading={isSubmitting}
  />
</Modal>

<!-- Delete Confirmation Modal -->
<Modal
  bind:open={showDeleteModal}
  title="Delete User"
  size="sm"
  onclose={closeModals}
>
  <div class="space-y-4">
    <Alert type="warning">
      Are you sure you want to delete this user? This action cannot be undone.
    </Alert>

    {#if selectedUser}
      <div class="bg-secondary-50 p-4 rounded-lg">
        <p class="text-sm text-secondary-900">
          <span class="font-medium">Email:</span> {selectedUser.email}
        </p>
        <p class="text-sm text-secondary-500 mt-1">
          <span class="font-medium">ID:</span> {selectedUser.id}
        </p>
      </div>
    {/if}

    <div class="flex justify-end space-x-3">
      <Button variant="ghost" onclick={closeModals} disabled={isSubmitting}>
        Cancel
      </Button>
      <Button variant="danger" onclick={handleDeleteUser} loading={isSubmitting}>
        Delete User
      </Button>
    </div>
  </div>
</Modal>

<!-- User Detail Modal -->
<Modal
  bind:open={showDetailModal}
  title="User Details"
  size="xl"
  onclose={closeModals}
>
  {#if selectedUser}
    <UserDetail
      user={selectedUser}
      onEdit={openEditModal}
      onDelete={openDeleteModal}
      onVerify={handleVerifyUser}
      isLoading={isSubmitting}
    />
  {/if}
</Modal>
