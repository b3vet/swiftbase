<script lang="ts">
  import { onMount } from 'svelte'
  import { router } from '@lib/router.svelte'
  import { authStore, notificationsStore, themeStore, settingsStore } from '@lib/stores'
  import { Layout } from '@components/layout'
  import { Spinner, Alert } from '@components/common'

  // Import route components
  import Login from '@routes/Login.svelte'
  import Dashboard from '@routes/Dashboard.svelte'
  import Collections from '@routes/Collections.svelte'
  import CollectionDetail from '@routes/CollectionDetail.svelte'
  import Documents from '@routes/Documents.svelte'
  import QueryExplorer from '@routes/QueryExplorer.svelte'
  import Users from '@routes/Users.svelte'
  import Files from '@routes/Files.svelte'
  import Realtime from '@routes/Realtime.svelte'
  import APITester from '@routes/APITester.svelte'
  import Settings from '@routes/Settings.svelte'

  // Register routes
  router.registerRoutes([
    { path: '/login', component: Login, title: 'Login' },
    { path: '/', component: Dashboard, requiresAuth: true, title: 'Dashboard' },
    { path: '/collections', component: Collections, requiresAuth: true, title: 'Collections' },
    { path: '/collections/:name/documents', component: Documents, requiresAuth: true, title: 'Documents' },
    { path: '/collections/:name', component: CollectionDetail, requiresAuth: true, title: 'Collection Detail' },
    { path: '/query', component: QueryExplorer, requiresAuth: true, title: 'Query Explorer' },
    { path: '/users', component: Users, requiresAuth: true, title: 'Users' },
    { path: '/files', component: Files, requiresAuth: true, title: 'Files' },
    { path: '/realtime', component: Realtime, requiresAuth: true, title: 'Realtime Monitor' },
    { path: '/api-tester', component: APITester, requiresAuth: true, title: 'API Tester' },
    { path: '/settings', component: Settings, requiresAuth: true, title: 'Settings' },
  ])

  // Initialize stores and router on mount
  onMount(() => {
    themeStore.init()
    settingsStore.init()
    authStore.initAuth()
    router.init()
  })

  // Get current route component
  const currentComponent = $derived(router.currentRoute?.component)
  const requiresAuth = $derived(router.currentRoute?.requiresAuth ?? false)
</script>

<!-- Notification Container -->
{#if notificationsStore.count > 0}
  <div class="fixed top-4 right-4 z-50 space-y-2 max-w-md">
    {#each notificationsStore.notifications as notification (notification.id)}
      <Alert
        type={notification.type}
        dismissible={notification.dismissible}
        ondismiss={() => notificationsStore.remove(notification.id)}
      >
        {notification.message}
      </Alert>
    {/each}
  </div>
{/if}

<!-- Main App -->
{#if authStore.isLoading}
  <!-- Loading State -->
  <div class="min-h-screen flex items-center justify-center bg-secondary-50">
    <div class="text-center">
      <Spinner size="xl" />
      <p class="mt-4 text-secondary-600">Loading SwiftBase...</p>
    </div>
  </div>
{:else if currentComponent}
  <!-- Render Route Component -->
  {@const Component = currentComponent}
  {#if requiresAuth}
    <!-- Authenticated Routes with Layout -->
    <Layout>
      <Component />
    </Layout>
  {:else}
    <!-- Public Routes without Layout -->
    <Component />
  {/if}
{:else}
  <!-- 404 Not Found -->
  <div class="min-h-screen flex items-center justify-center bg-secondary-50">
    <div class="text-center">
      <h1 class="text-6xl font-bold text-secondary-900">404</h1>
      <p class="mt-4 text-xl text-secondary-600">Page not found</p>
      <button
        type="button"
        class="mt-6 px-4 py-2 bg-primary-600 text-white rounded-lg hover:bg-primary-700"
        onclick={() => router.navigate('/')}
      >
        Go Home
      </button>
    </div>
  </div>
{/if}
