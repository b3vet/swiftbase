<script lang="ts">
  import { authStore, themeStore } from '@lib/stores'
  import { Button } from '@components/common'

  let showProfileMenu = $state(false)

  function toggleProfileMenu() {
    showProfileMenu = !showProfileMenu
  }

  function closeProfileMenu() {
    showProfileMenu = false
  }

  function handleLogout() {
    closeProfileMenu()
    authStore.logout()
  }

  function handleClickOutside(event: MouseEvent) {
    const target = event.target as HTMLElement
    if (!target.closest('.profile-menu-container')) {
      closeProfileMenu()
    }
  }

  $effect(() => {
    if (showProfileMenu) {
      document.addEventListener('click', handleClickOutside)
      return () => {
        document.removeEventListener('click', handleClickOutside)
      }
    }
  })
</script>

<nav class="bg-white border-b border-secondary-200 fixed w-full top-0 z-40">
  <div class="px-4 sm:px-6 lg:px-8">
    <div class="flex justify-between h-16">
      <!-- Left side: Logo and Menu Button -->
      <div class="flex items-center">
        <!-- Mobile menu button -->
        <button
          type="button"
          class="inline-flex items-center justify-center p-2 rounded-md text-secondary-600 hover:text-secondary-900 hover:bg-secondary-100 focus:outline-none focus:ring-2 focus:ring-inset focus:ring-primary-500 lg:hidden"
          onclick={() => themeStore.toggleSidebar()}
          aria-label="Toggle navigation menu"
        >
          <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M4 6h16M4 12h16M4 18h16" />
          </svg>
        </button>

        <!-- Logo -->
        <div class="flex-shrink-0 flex items-center ml-4 lg:ml-0">
          <div class="h-8 w-8 flex items-center justify-center bg-primary-600 rounded-lg">
            <svg class="h-5 w-5 text-white" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M13 10V3L4 14h7v7l9-11h-7z" />
            </svg>
          </div>
          <span class="ml-2 text-xl font-bold text-secondary-900">SwiftBase</span>
        </div>
      </div>

      <!-- Right side: Theme Toggle and User Menu -->
      <div class="flex items-center space-x-4">
        <!-- Theme Toggle -->
        <button
          type="button"
          class="p-2 rounded-md text-secondary-600 hover:text-secondary-900 hover:bg-secondary-100 focus:outline-none focus:ring-2 focus:ring-primary-500"
          onclick={() => themeStore.toggleMode()}
        >
          {#if themeStore.isDark}
            <!-- Sun icon -->
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 3v1m0 16v1m9-9h-1M4 12H3m15.364 6.364l-.707-.707M6.343 6.343l-.707-.707m12.728 0l-.707.707M6.343 17.657l-.707.707M16 12a4 4 0 11-8 0 4 4 0 018 0z" />
            </svg>
          {:else}
            <!-- Moon icon -->
            <svg class="h-5 w-5" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20.354 15.354A9 9 0 018.646 3.646 9.003 9.003 0 0012 21a9.003 9.003 0 008.354-5.646z" />
            </svg>
          {/if}
        </button>

        <!-- Profile Dropdown -->
        <div class="relative profile-menu-container">
          <button
            type="button"
            class="flex items-center space-x-3 p-2 rounded-md hover:bg-secondary-100 focus:outline-none focus:ring-2 focus:ring-primary-500"
            onclick={toggleProfileMenu}
          >
            <div class="h-8 w-8 rounded-full bg-primary-600 flex items-center justify-center">
              <span class="text-sm font-medium text-white">
                {authStore.admin?.username?.charAt(0).toUpperCase() || 'A'}
              </span>
            </div>
            <div class="hidden md:block text-left">
              <p class="text-sm font-medium text-secondary-900">
                {authStore.admin?.username || 'Admin'}
              </p>
              <p class="text-xs text-secondary-500">Administrator</p>
            </div>
            <svg class="h-4 w-4 text-secondary-600" fill="none" viewBox="0 0 24 24" stroke="currentColor">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M19 9l-7 7-7-7" />
            </svg>
          </button>

          {#if showProfileMenu}
            <div class="absolute right-0 mt-2 w-48 rounded-md shadow-lg bg-white ring-1 ring-black ring-opacity-5">
              <div class="py-1" role="menu">
                <div class="px-4 py-2 border-b border-secondary-200">
                  <p class="text-sm font-medium text-secondary-900">
                    {authStore.admin?.username}
                  </p>
                  <p class="text-xs text-secondary-500 mt-0.5">Administrator</p>
                </div>

                <button
                  type="button"
                  class="w-full text-left px-4 py-2 text-sm text-secondary-700 hover:bg-secondary-100 flex items-center"
                  onclick={closeProfileMenu}
                >
                  <svg class="h-4 w-4 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M10.325 4.317c.426-1.756 2.924-1.756 3.35 0a1.724 1.724 0 002.573 1.066c1.543-.94 3.31.826 2.37 2.37a1.724 1.724 0 001.065 2.572c1.756.426 1.756 2.924 0 3.35a1.724 1.724 0 00-1.066 2.573c.94 1.543-.826 3.31-2.37 2.37a1.724 1.724 0 00-2.572 1.065c-.426 1.756-2.924 1.756-3.35 0a1.724 1.724 0 00-2.573-1.066c-1.543.94-3.31-.826-2.37-2.37a1.724 1.724 0 00-1.065-2.572c-1.756-.426-1.756-2.924 0-3.35a1.724 1.724 0 001.066-2.573c-.94-1.543.826-3.31 2.37-2.37.996.608 2.296.07 2.572-1.065z" />
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  Settings
                </button>

                <button
                  type="button"
                  class="w-full text-left px-4 py-2 text-sm text-red-700 hover:bg-red-50 flex items-center border-t border-secondary-200"
                  onclick={handleLogout}
                >
                  <svg class="h-4 w-4 mr-3" fill="none" viewBox="0 0 24 24" stroke="currentColor">
                    <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M17 16l4-4m0 0l-4-4m4 4H7m6 4v1a3 3 0 01-3 3H6a3 3 0 01-3-3V7a3 3 0 013-3h4a3 3 0 013 3v1" />
                  </svg>
                  Sign Out
                </button>
              </div>
            </div>
          {/if}
        </div>
      </div>
    </div>
  </div>
</nav>
