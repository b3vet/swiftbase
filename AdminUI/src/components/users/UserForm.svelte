<script lang="ts">
  import type { User } from '@lib/types'
  import { Input, Textarea, Button, Alert } from '@components/common'
  import { validation, parseJSON, formatJSON } from '@lib/utils'
  import { JSONEditor, Mode } from 'svelte-jsoneditor'

  interface Props {
    user?: User | null
    onSubmit: (data: { email: string; password?: string; metadata: Record<string, any> }) => Promise<void>
    onCancel: () => void
    isLoading?: boolean
  }

  let {
    user = null,
    onSubmit,
    onCancel,
    isLoading = false
  }: Props = $props()

  const isEditMode = $derived(user !== null)

  let email = $state(user?.email || '')
  let password = $state('')
  let confirmPassword = $state('')
  let metadataContent = $state({ text: user?.metadata ? formatJSON(user.metadata) : '{}' })
  let error = $state<string | null>(null)

  const isEmailValid = $derived(validation.isEmail(email))
  const isPasswordValid = $derived(
    isEditMode ? (password ? validation.isValidPassword(password) : true) : validation.isValidPassword(password)
  )
  const passwordsMatch = $derived(password === confirmPassword)
  const isMetadataValid = $derived(validation.isValidJSON(metadataContent.text || '{}'))

  const canSubmit = $derived(
    email &&
    isEmailValid &&
    isPasswordValid &&
    passwordsMatch &&
    isMetadataValid &&
    !isLoading
  )

  async function handleSubmit() {
    error = null

    if (!isEmailValid) {
      error = 'Please enter a valid email address'
      return
    }

    if (!isEditMode && !isPasswordValid) {
      error = 'Password must be at least 8 characters'
      return
    }

    if (password && !isPasswordValid) {
      error = 'Password must be at least 8 characters'
      return
    }

    if (password && !passwordsMatch) {
      error = 'Passwords do not match'
      return
    }

    if (!isMetadataValid) {
      error = 'Metadata must be valid JSON'
      return
    }

    try {
      // Parse JSON from editor text mode
      const metadata = metadataContent.text ? JSON.parse(metadataContent.text) : {}

      await onSubmit({
        email,
        password: password || undefined,
        metadata
      })
    } catch (err) {
      error = err instanceof Error ? err.message : 'Failed to save user'
    }
  }
</script>

<form onsubmit={(e) => { e.preventDefault(); handleSubmit() }} class="space-y-4">
  {#if error}
    <Alert type="error" dismissible ondismiss={() => (error = null)}>
      {error}
    </Alert>
  {/if}

  <!-- Email -->
  <Input
    type="email"
    label="Email"
    bind:value={email}
    placeholder="user@example.com"
    required
    disabled={isLoading || isEditMode}
    error={email && !isEmailValid ? 'Invalid email address' : undefined}
  />

  <!-- Password (optional for edit mode) -->
  <Input
    type="password"
    label={isEditMode ? 'New Password (leave blank to keep current)' : 'Password'}
    bind:value={password}
    placeholder="••••••••"
    required={!isEditMode}
    disabled={isLoading}
    error={password && !isPasswordValid ? 'Password must be at least 8 characters' : undefined}
    helptext={isEditMode ? 'Only fill this if you want to change the password' : 'Minimum 8 characters'}
  />

  <!-- Confirm Password -->
  {#if password}
    <Input
      type="password"
      label="Confirm Password"
      bind:value={confirmPassword}
      placeholder="••••••••"
      required
      disabled={isLoading}
      error={confirmPassword && !passwordsMatch ? 'Passwords do not match' : undefined}
    />
  {/if}

  <!-- Metadata -->
  <div>
    <div class="flex items-center justify-between mb-2">
      <label class="block text-sm font-medium text-secondary-700">
        Metadata (JSON)
      </label>
      {#if isMetadataValid}
        <span class="text-xs text-green-600 flex items-center">
          <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M5 13l4 4L19 7" />
          </svg>
          Valid
        </span>
      {:else}
        <span class="text-xs text-red-600 flex items-center">
          <svg class="h-4 w-4 mr-1" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M6 18L18 6M6 6l12 12" />
          </svg>
          Invalid JSON
        </span>
      {/if}
    </div>

    <div class="border border-secondary-300 rounded-lg overflow-hidden" style="height: 200px;">
      <JSONEditor
        bind:content={metadataContent}
        mode={Mode.text}
        mainMenuBar={false}
        statusBar={false}
        readOnly={isLoading}
      />
    </div>

    <p class="mt-2 text-xs text-secondary-500">
      Custom JSON metadata for the user
    </p>
  </div>

  <!-- Actions -->
  <div class="flex justify-end space-x-3 pt-4">
    <Button variant="ghost" onclick={onCancel} disabled={isLoading}>
      Cancel
    </Button>
    <Button variant="primary" type="submit" disabled={!canSubmit} loading={isLoading}>
      {isEditMode ? 'Update User' : 'Create User'}
    </Button>
  </div>
</form>
