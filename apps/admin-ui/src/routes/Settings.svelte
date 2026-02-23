<script lang="ts">
  import { ThemeSettings, UserPreferences, SystemInfo } from '@components/settings'

  let activeTab = $state<'appearance' | 'preferences' | 'system'>('appearance')
</script>

<div class="space-y-6">
  <!-- Header -->
  <div>
    <h1 class="text-3xl font-bold text-secondary-900">Settings</h1>
    <p class="mt-2 text-secondary-600">
      Manage your preferences and view system information
    </p>
  </div>

  <!-- Tabs -->
  <div class="border-b border-secondary-200">
    <nav class="-mb-px flex space-x-8">
      <button
        type="button"
        class="py-4 px-1 border-b-2 font-medium text-sm {activeTab === 'appearance'
          ? 'border-primary-600 text-primary-600'
          : 'border-transparent text-secondary-500 hover:text-secondary-700 hover:border-secondary-300'}"
        onclick={() => (activeTab = 'appearance')}
      >
        <svg
          class="h-5 w-5 inline-block mr-2 -mt-1"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M7 21a4 4 0 01-4-4V5a2 2 0 012-2h4a2 2 0 012 2v12a4 4 0 01-4 4zm0 0h12a2 2 0 002-2v-4a2 2 0 00-2-2h-2.343M11 7.343l1.657-1.657a2 2 0 012.828 0l2.829 2.829a2 2 0 010 2.828l-8.486 8.485M7 17h.01"
          />
        </svg>
        Appearance
      </button>

      <button
        type="button"
        class="py-4 px-1 border-b-2 font-medium text-sm {activeTab === 'preferences'
          ? 'border-primary-600 text-primary-600'
          : 'border-transparent text-secondary-500 hover:text-secondary-700 hover:border-secondary-300'}"
        onclick={() => (activeTab = 'preferences')}
      >
        <svg
          class="h-5 w-5 inline-block mr-2 -mt-1"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z"
          />
        </svg>
        Preferences
      </button>

      <button
        type="button"
        class="py-4 px-1 border-b-2 font-medium text-sm {activeTab === 'system'
          ? 'border-primary-600 text-primary-600'
          : 'border-transparent text-secondary-500 hover:text-secondary-700 hover:border-secondary-300'}"
        onclick={() => (activeTab = 'system')}
      >
        <svg
          class="h-5 w-5 inline-block mr-2 -mt-1"
          fill="none"
          viewBox="0 0 24 24"
          stroke="currentColor"
        >
          <path
            stroke-linecap="round"
            stroke-linejoin="round"
            stroke-width="2"
            d="M9 3v2m6-2v2M9 19v2m6-2v2M5 9H3m2 6H3m18-6h-2m2 6h-2M7 19h10a2 2 0 002-2V7a2 2 0 00-2-2H7a2 2 0 00-2 2v10a2 2 0 002 2zM9 9h6v6H9V9z"
          />
        </svg>
        System
      </button>
    </nav>
  </div>

  <!-- Tab Content -->
  <div class="bg-white border border-secondary-200 rounded-lg p-6">
    {#if activeTab === 'appearance'}
      <ThemeSettings />
    {:else if activeTab === 'preferences'}
      <UserPreferences />
    {:else if activeTab === 'system'}
      <SystemInfo />
    {/if}
  </div>
</div>
