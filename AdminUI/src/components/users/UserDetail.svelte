<script lang="ts">
  import type { User } from '@lib/types'
  import { Card, Badge, Button } from '@components/common'
  import { formatDate, formatRelativeTime, formatJSON } from '@lib/utils'

  interface Props {
    user: User
    onEdit?: (user: User) => void
    onDelete?: (user: User) => void
    onVerify?: (user: User) => void
    isLoading?: boolean
  }

  let {
    user,
    onEdit,
    onDelete,
    onVerify,
    isLoading = false
  }: Props = $props()

  function handleEdit() {
    onEdit?.(user)
  }

  function handleDelete() {
    onDelete?.(user)
  }

  function handleVerify() {
    onVerify?.(user)
  }

  function getUserStatusBadge(user: User) {
    if (user.email_verified) {
      return { variant: 'success' as const, text: 'Verified' }
    }
    return { variant: 'warning' as const, text: 'Unverified' }
  }
</script>

<div class="space-y-6">
  <!-- User Header -->
  <Card>
    <div class="flex items-start justify-between">
      <div class="flex items-center space-x-4">
        <div class="flex-shrink-0 h-16 w-16 rounded-full bg-primary-100 flex items-center justify-center">
          <span class="text-primary-600 font-medium text-2xl">
            {user.email.charAt(0).toUpperCase()}
          </span>
        </div>
        <div>
          <h2 class="text-2xl font-bold text-secondary-900">{user.email}</h2>
          <div class="mt-1 flex items-center space-x-3">
            <Badge variant={getUserStatusBadge(user).variant}>
              {getUserStatusBadge(user).text}
            </Badge>
            <span class="text-sm text-secondary-500">
              ID: {user.id}
            </span>
          </div>
        </div>
      </div>

      <div class="flex items-center space-x-2">
        {#if !user.email_verified && onVerify}
          <Button variant="outline" size="sm" onclick={handleVerify} disabled={isLoading}>
            <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Verify Email
          </Button>
        {/if}
        {#if onEdit}
          <Button variant="outline" size="sm" onclick={handleEdit} disabled={isLoading}>
            <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
            </svg>
            Edit
          </Button>
        {/if}
        {#if onDelete}
          <Button variant="danger" size="sm" onclick={handleDelete} disabled={isLoading}>
            <svg class="h-4 w-4 mr-2" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
            </svg>
            Delete
          </Button>
        {/if}
      </div>
    </div>
  </Card>

  <div class="grid grid-cols-1 lg:grid-cols-2 gap-6">
    <!-- User Information -->
    <Card title="User Information">
      <dl class="space-y-4">
        <div>
          <dt class="text-sm font-medium text-secondary-500">Email</dt>
          <dd class="mt-1 text-sm text-secondary-900">{user.email}</dd>
        </div>

        <div>
          <dt class="text-sm font-medium text-secondary-500">Email Verified</dt>
          <dd class="mt-1">
            <Badge variant={user.email_verified ? 'success' : 'warning'}>
              {user.email_verified ? 'Yes' : 'No'}
            </Badge>
          </dd>
        </div>

        <div>
          <dt class="text-sm font-medium text-secondary-500">User ID</dt>
          <dd class="mt-1 text-sm text-secondary-900 font-mono break-all">{user.id}</dd>
        </div>

        <div>
          <dt class="text-sm font-medium text-secondary-500">Created At</dt>
          <dd class="mt-1 text-sm text-secondary-900">
            {formatDate(user.created_at)}
            <span class="text-secondary-500 ml-2">({formatRelativeTime(user.created_at)})</span>
          </dd>
        </div>

        <div>
          <dt class="text-sm font-medium text-secondary-500">Updated At</dt>
          <dd class="mt-1 text-sm text-secondary-900">
            {formatDate(user.updated_at)}
            <span class="text-secondary-500 ml-2">({formatRelativeTime(user.updated_at)})</span>
          </dd>
        </div>

        <div>
          <dt class="text-sm font-medium text-secondary-500">Last Login</dt>
          <dd class="mt-1 text-sm text-secondary-900">
            {#if user.last_login}
              {formatDate(user.last_login)}
              <span class="text-secondary-500 ml-2">({formatRelativeTime(user.last_login)})</span>
            {:else}
              <span class="text-secondary-500">Never</span>
            {/if}
          </dd>
        </div>
      </dl>
    </Card>

    <!-- User Metadata -->
    <Card title="Metadata">
      {#if user.metadata && Object.keys(user.metadata).length > 0}
        <pre class="bg-secondary-50 p-4 rounded-lg overflow-x-auto text-sm"><code>{formatJSON(user.metadata)}</code></pre>
      {:else}
        <div class="text-center py-8">
          <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M7 21h10a2 2 0 002-2V9.414a1 1 0 00-.293-.707l-5.414-5.414A1 1 0 0012.586 3H7a2 2 0 00-2 2v14a2 2 0 002 2z" />
          </svg>
          <h3 class="mt-2 text-sm font-medium text-secondary-900">No metadata</h3>
          <p class="mt-1 text-sm text-secondary-500">
            No custom metadata has been set for this user
          </p>
        </div>
      {/if}
    </Card>
  </div>
</div>
