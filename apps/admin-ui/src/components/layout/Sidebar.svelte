<script lang="ts">
  import { router } from '@lib/router.svelte'
  import { themeStore } from '@lib/stores'

  interface NavItem {
    name: string
    path: string
    icon: string
  }

  const navItems: NavItem[] = [
    {
      name: 'Dashboard',
      path: '/',
      icon: 'M3 12l2-2m0 0l7-7 7 7M5 10v10a1 1 0 001 1h3m10-11l2 2m-2-2v10a1 1 0 01-1 1h-3m-6 0a1 1 0 001-1v-4a1 1 0 011-1h2a1 1 0 011 1v4a1 1 0 001 1m-6 0h6'
    },
    {
      name: 'Collections',
      path: '/collections',
      icon: 'M19 11H5m14 0a2 2 0 012 2v6a2 2 0 01-2 2H5a2 2 0 01-2-2v-6a2 2 0 012-2m14 0V9a2 2 0 00-2-2M5 11V9a2 2 0 012-2m0 0V5a2 2 0 012-2h6a2 2 0 012 2v2M7 7h10'
    },
    {
      name: 'Query Explorer',
      path: '/query',
      icon: 'M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z'
    },
    {
      name: 'Users',
      path: '/users',
      icon: 'M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z'
    },
    {
      name: 'Files',
      path: '/files',
      icon: 'M3 7v10a2 2 0 002 2h14a2 2 0 002-2V9a2 2 0 00-2-2h-6l-2-2H5a2 2 0 00-2 2z'
    },
    {
      name: 'Realtime',
      path: '/realtime',
      icon: 'M13 10V3L4 14h7v7l9-11h-7z'
    },
    {
      name: 'API Tester',
      path: '/api-tester',
      icon: 'M10 20l4-16m4 4l4 4-4 4M6 16l-4-4 4-4'
    }
  ]

  function isActive(path: string): boolean {
    if (path === '/') {
      return router.currentPath === '/'
    }
    return router.currentPath.startsWith(path)
  }

  function handleNavClick(path: string) {
    router.navigate(path)
    // Close sidebar on mobile after navigation
    if (window.innerWidth < 1024) {
      themeStore.setSidebarCollapsed(true)
    }
  }
</script>

<!-- Mobile sidebar backdrop -->
{#if !themeStore.sidebarCollapsed}
  <div
    class="fixed inset-0 bg-black bg-opacity-50 z-30 lg:hidden"
    onclick={() => themeStore.setSidebarCollapsed(true)}
    onkeydown={(e) => e.key === 'Escape' && themeStore.setSidebarCollapsed(true)}
    role="button"
    tabindex="0"
    aria-label="Close navigation menu"
  ></div>
{/if}

<!-- Sidebar -->
<aside
  class="fixed top-16 left-0 z-30 w-64 h-[calc(100vh-4rem)] bg-white border-r border-secondary-200 overflow-y-auto transition-transform duration-200 ease-in-out {themeStore.sidebarCollapsed ? '-translate-x-full lg:translate-x-0' : 'translate-x-0'}"
>
  <nav class="p-4 space-y-1">
    {#each navItems as item}
      <button
        type="button"
        class="w-full flex items-center px-4 py-3 text-sm font-medium rounded-lg transition-colors {isActive(item.path)
          ? 'bg-primary-50 text-primary-700'
          : 'text-secondary-700 hover:bg-secondary-100'}"
        onclick={() => handleNavClick(item.path)}
      >
        <svg class="h-5 w-5 mr-3 flex-shrink-0" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d={item.icon} />
        </svg>
        <span>{item.name}</span>
      </button>
    {/each}
  </nav>

  <!-- Sidebar Footer -->
  <div class="absolute bottom-0 left-0 right-0 p-4 border-t border-secondary-200">
    <div class="text-xs text-secondary-500 text-center">
      <p>SwiftBase v1.0.0</p>
      <p class="mt-1">Built with Swift & Svelte</p>
    </div>
  </div>
</aside>
