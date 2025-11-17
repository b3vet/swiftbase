<script lang="ts">
  import { settingsStore } from '@lib/stores'

  const pages = [
    { value: '/', label: 'Dashboard' },
    { value: '/collections', label: 'Collections' },
    { value: '/query', label: 'Query Explorer' },
    { value: '/users', label: 'Users' },
    { value: '/files', label: 'Files' },
    { value: '/realtime', label: 'Realtime Monitor' },
    { value: '/api-tester', label: 'API Tester' }
  ]

  const itemsPerPageOptions = [10, 20, 50, 100]
  const queryFormats = [
    { value: 'table', label: 'Table View' },
    { value: 'json', label: 'JSON View' },
    { value: 'raw', label: 'Raw Data' }
  ]

  function handleDefaultPageChange(e: Event) {
    const target = e.target as HTMLSelectElement
    settingsStore.setDefaultPage(target.value as any)
  }

  function handleItemsPerPageChange(e: Event) {
    const target = e.target as HTMLSelectElement
    settingsStore.setItemsPerPage(parseInt(target.value))
  }

  function handleQueryFormatChange(e: Event) {
    const target = e.target as HTMLSelectElement
    settingsStore.setQueryResultFormat(target.value as any)
  }

  function handleNotificationsToggle(e: Event) {
    const target = e.target as HTMLInputElement
    settingsStore.setNotificationsEnabled(target.checked)
  }

  function handleNotificationDurationChange(e: Event) {
    const target = e.target as HTMLInputElement
    settingsStore.setNotificationDuration(parseInt(target.value))
  }

  function handleReset() {
    settingsStore.reset()
  }
</script>

<div class="space-y-6">
  <!-- Section Header -->
  <div>
    <h3 class="text-lg font-semibold text-secondary-900">User Preferences</h3>
    <p class="mt-1 text-sm text-secondary-600">
      Configure your personal settings and defaults
    </p>
  </div>

  <!-- Default Page -->
  <div>
    <label for="defaultPage" class="block text-sm font-medium text-secondary-700 mb-2">
      Default Page on Login
    </label>
    <select
      id="defaultPage"
      value={settingsStore.defaultPage}
      onchange={handleDefaultPageChange}
      class="w-full px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
    >
      {#each pages as page}
        <option value={page.value}>{page.label}</option>
      {/each}
    </select>
    <p class="mt-1 text-xs text-secondary-500">
      The page you'll see first after logging in
    </p>
  </div>

  <!-- Items Per Page -->
  <div>
    <label for="itemsPerPage" class="block text-sm font-medium text-secondary-700 mb-2">
      Items Per Page
    </label>
    <select
      id="itemsPerPage"
      value={settingsStore.itemsPerPage.toString()}
      onchange={handleItemsPerPageChange}
      class="w-full px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
    >
      {#each itemsPerPageOptions as option}
        <option value={option.toString()}>{option}</option>
      {/each}
    </select>
    <p class="mt-1 text-xs text-secondary-500">
      Number of items to display in lists and tables
    </p>
  </div>

  <!-- Query Result Format -->
  <div>
    <label for="queryFormat" class="block text-sm font-medium text-secondary-700 mb-2">
      Query Result Format
    </label>
    <select
      id="queryFormat"
      value={settingsStore.queryResultFormat}
      onchange={handleQueryFormatChange}
      class="w-full px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
    >
      {#each queryFormats as format}
        <option value={format.value}>{format.label}</option>
      {/each}
    </select>
    <p class="mt-1 text-xs text-secondary-500">
      Default format for displaying query results
    </p>
  </div>

  <!-- Notifications -->
  <div>
    <div class="flex items-center justify-between">
      <div>
        <label for="notifications" class="text-sm font-medium text-secondary-700">
          Enable Notifications
        </label>
        <p class="text-xs text-secondary-500 mt-1">
          Show toast notifications for actions and events
        </p>
      </div>
      <input
        type="checkbox"
        id="notifications"
        checked={settingsStore.notificationsEnabled}
        onchange={handleNotificationsToggle}
        class="h-4 w-4 text-primary-600 focus:ring-primary-500 border-secondary-300 rounded"
      />
    </div>
  </div>

  <!-- Notification Duration -->
  {#if settingsStore.notificationsEnabled}
    <div>
      <div class="flex items-center justify-between mb-2">
        <label for="notificationDuration" class="block text-sm font-medium text-secondary-700">
          Notification Duration
        </label>
        <span class="text-sm text-secondary-600">
          {settingsStore.notificationDuration / 1000}s
        </span>
      </div>
      <input
        type="range"
        id="notificationDuration"
        min="1000"
        max="10000"
        step="1000"
        value={settingsStore.notificationDuration}
        oninput={handleNotificationDurationChange}
        class="w-full h-2 bg-secondary-200 rounded-lg appearance-none cursor-pointer accent-primary-600"
      />
      <div class="flex justify-between text-xs text-secondary-500 mt-1">
        <span>1s</span>
        <span>5s</span>
        <span>10s</span>
      </div>
    </div>
  {/if}

  <!-- Reset Button -->
  <div class="pt-4 border-t border-secondary-200">
    <button
      type="button"
      onclick={handleReset}
      class="px-4 py-2 text-sm font-medium text-secondary-700 bg-white border border-secondary-300 rounded-lg hover:bg-secondary-50 focus:outline-none focus:ring-2 focus:ring-primary-500"
    >
      Reset to Defaults
    </button>
  </div>
</div>
