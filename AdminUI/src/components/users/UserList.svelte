<script lang="ts">
  import type { User } from '@lib/types'
  import { Button, Badge, Table } from '@components/common'
  import { formatRelativeTime } from '@lib/utils'

  interface Props {
    users: User[]
    onEdit?: (user: User) => void
    onDelete?: (user: User) => void
    onView?: (user: User) => void
    isLoading?: boolean
  }

  let {
    users,
    onEdit,
    onDelete,
    onView,
    isLoading = false
  }: Props = $props()

  let searchTerm = $state('')
  let statusFilter = $state<'all' | 'verified' | 'unverified'>('all')

  const filteredUsers = $derived.by(() => {
    let result = users

    // Filter by search term
    if (searchTerm) {
      const term = searchTerm.toLowerCase()
      result = result.filter((user) =>
        user.email.toLowerCase().includes(term) ||
        user.id.toLowerCase().includes(term)
      )
    }

    // Filter by verification status
    if (statusFilter !== 'all') {
      result = result.filter((user) =>
        statusFilter === 'verified' ? user.email_verified : !user.email_verified
      )
    }

    return result
  })

  function handleEdit(user: User) {
    onEdit?.(user)
  }

  function handleDelete(user: User) {
    onDelete?.(user)
  }

  function handleView(user: User) {
    onView?.(user)
  }

  function getUserStatusBadge(user: User) {
    if (user.email_verified) {
      return { variant: 'success' as const, text: 'Verified' }
    }
    return { variant: 'warning' as const, text: 'Unverified' }
  }
</script>

<div class="space-y-4">
  <!-- Search and Filters -->
  <div class="flex flex-col sm:flex-row gap-4">
    <div class="flex-1">
      <div class="relative">
        <input
          type="text"
          bind:value={searchTerm}
          placeholder="Search users by email or ID..."
          class="block w-full rounded-lg border border-secondary-300 pl-10 pr-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
        />
        <div class="absolute inset-y-0 left-0 pl-3 flex items-center pointer-events-none">
          <svg class="h-5 w-5 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
          </svg>
        </div>
      </div>
    </div>

    <div class="flex gap-2">
      <select
        bind:value={statusFilter}
        class="rounded-lg border border-secondary-300 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
      >
        <option value="all">All Users</option>
        <option value="verified">Verified Only</option>
        <option value="unverified">Unverified Only</option>
      </select>
    </div>
  </div>

  <!-- Results Count -->
  <div class="text-sm text-secondary-600">
    Showing {filteredUsers.length} of {users.length} users
  </div>

  <!-- User Table -->
  {#if isLoading}
    <div class="text-center py-12">
      <div class="inline-block animate-spin rounded-full h-8 w-8 border-b-2 border-primary-600"></div>
      <p class="mt-2 text-sm text-secondary-600">Loading users...</p>
    </div>
  {:else if filteredUsers.length === 0}
    <div class="text-center py-12 bg-white rounded-lg border border-secondary-200">
      <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
      </svg>
      <h3 class="mt-2 text-sm font-medium text-secondary-900">No users found</h3>
      <p class="mt-1 text-sm text-secondary-500">
        {searchTerm || statusFilter !== 'all' ? 'Try adjusting your filters' : 'No users have been created yet'}
      </p>
    </div>
  {:else}
    <div class="bg-white rounded-lg shadow-sm border border-secondary-200 overflow-hidden">
      <Table>
        <thead class="bg-secondary-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              User
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Status
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Created
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Last Login
            </th>
            <th class="px-6 py-3 text-right text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-secondary-200">
          {#each filteredUsers as user (user.id)}
            <tr class="hover:bg-secondary-50 cursor-pointer" onclick={() => handleView(user)}>
              <td class="px-6 py-4 whitespace-nowrap">
                <div class="flex items-center">
                  <div class="flex-shrink-0 h-10 w-10 rounded-full bg-primary-100 flex items-center justify-center">
                    <span class="text-primary-600 font-medium text-sm">
                      {user.email.charAt(0).toUpperCase()}
                    </span>
                  </div>
                  <div class="ml-4">
                    <div class="text-sm font-medium text-secondary-900">
                      {user.email}
                    </div>
                    <div class="text-sm text-secondary-500">
                      ID: {user.id.substring(0, 8)}...
                    </div>
                  </div>
                </div>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <Badge variant={getUserStatusBadge(user).variant}>
                  {getUserStatusBadge(user).text}
                </Badge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-secondary-500">
                {formatRelativeTime(user.created_at)}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-secondary-500">
                {user.last_login ? formatRelativeTime(user.last_login) : 'Never'}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium">
                <div class="flex items-center justify-end space-x-2">
                  <Button
                    variant="ghost"
                    size="sm"
                    onclick={(e: MouseEvent) => {
                      e.stopPropagation()
                      handleEdit(user)
                    }}
                  >
                    Edit
                  </Button>
                  <button
                    type="button"
                    class="p-1 text-secondary-400 hover:text-red-600 transition-colors"
                    onclick={(e: MouseEvent) => {
                      e.stopPropagation()
                      handleDelete(user)
                    }}
                    title="Delete"
                  >
                    <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                      <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                    </svg>
                  </button>
                </div>
              </td>
            </tr>
          {/each}
        </tbody>
      </Table>
    </div>
  {/if}
</div>
