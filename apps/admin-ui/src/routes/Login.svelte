<script lang="ts">
  import { authStore } from '@lib/stores'
  import { router } from '@lib/router.svelte'
  import { Button, Input, Alert } from '@components/common'
  import { validation } from '@lib/utils'

  let username = $state('')
  let password = $state('')
  let errors = $state<{ username?: string; password?: string }>({})
  let isLoading = $state(false)

  // Watch for successful login
  $effect(() => {
    if (authStore.isAuthenticated) {
      router.navigate('/')
    }
  })

  function validateForm(): boolean {
    const newErrors: typeof errors = {}

    if (!validation.isRequired(username)) {
      newErrors.username = 'Username is required'
    }

    if (!validation.isRequired(password)) {
      newErrors.password = 'Password is required'
    } else if (!validation.minLength(password, 8)) {
      newErrors.password = 'Password must be at least 8 characters'
    }

    errors = newErrors
    return Object.keys(newErrors).length === 0
  }

  async function handleSubmit(event: Event) {
    event.preventDefault()

    if (!validateForm()) {
      return
    }

    isLoading = true
    authStore.clearError()

    const success = await authStore.login(username, password)

    if (success) {
      // Router will handle navigation via $effect above
    }

    isLoading = false
  }

  function handleUsernameInput() {
    if (errors.username) {
      errors = { ...errors, username: undefined }
    }
  }

  function handlePasswordInput() {
    if (errors.password) {
      errors = { ...errors, password: undefined }
    }
  }
</script>

<div class="min-h-screen flex items-center justify-center bg-gradient-to-br from-primary-500 to-primary-700 py-12 px-4 sm:px-6 lg:px-8">
  <div class="max-w-md w-full space-y-8">
    <!-- Logo and Title -->
    <div>
      <div class="mx-auto h-16 w-16 flex items-center justify-center bg-white rounded-xl shadow-lg">
        <svg class="h-10 w-10 text-primary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
        </svg>
      </div>
      <h2 class="mt-6 text-center text-3xl font-extrabold text-white">
        SwiftBase Admin
      </h2>
      <p class="mt-2 text-center text-sm text-primary-100">
        Sign in to manage your backend
      </p>
    </div>

    <!-- Login Form -->
    <div class="bg-white rounded-lg shadow-xl p-8">
      <form class="space-y-6" onsubmit={handleSubmit}>
        {#if authStore.error}
          <Alert type="error" dismissible ondismiss={() => authStore.clearError()}>
            {authStore.error}
          </Alert>
        {/if}

        <Input
          type="text"
          label="Username"
          bind:value={username}
          placeholder="Enter your username"
          error={errors.username}
          required
          autocomplete="username"
          disabled={isLoading}
          oninput={handleUsernameInput}
        />

        <Input
          type="password"
          label="Password"
          bind:value={password}
          placeholder="Enter your password"
          error={errors.password}
          required
          autocomplete="current-password"
          disabled={isLoading}
          oninput={handlePasswordInput}
        />

        <Button
          type="submit"
          variant="primary"
          size="lg"
          fullWidth
          loading={isLoading}
          disabled={isLoading}
        >
          Sign In
        </Button>
      </form>

      <!-- Help Text -->
      <div class="mt-6 text-center">
        <p class="text-xs text-secondary-500">
          Default credentials: <span class="font-mono font-semibold">admin / admin123</span>
        </p>
      </div>
    </div>

    <!-- Footer -->
    <div class="text-center text-sm text-primary-100">
      <p>SwiftBase v1.0.0</p>
      <p class="mt-1">Built with Swift & Svelte</p>
    </div>
  </div>
</div>
