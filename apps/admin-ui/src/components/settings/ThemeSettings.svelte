<script lang="ts">
  import { themeStore, settingsStore } from '@lib/stores'

  function handleModeChange(e: Event) {
    const target = e.target as HTMLSelectElement
    themeStore.setMode(target.value as 'light' | 'dark')
  }

  function handleSidebarPositionChange(e: Event) {
    const target = e.target as HTMLSelectElement
    themeStore.setSidebarPosition(target.value as 'left' | 'right')
  }

  function handleDensityChange(e: Event) {
    const target = e.target as HTMLSelectElement
    themeStore.setDensity(target.value as 'comfortable' | 'compact')
  }

  function handleFontSizeChange(e: Event) {
    const target = e.target as HTMLInputElement
    settingsStore.setFontSize(parseInt(target.value))
  }

  function handleReset() {
    themeStore.reset()
    settingsStore.setFontSize(16)
  }
</script>

<div class="space-y-6">
  <!-- Section Header -->
  <div>
    <h3 class="text-lg font-semibold text-secondary-900">Appearance</h3>
    <p class="mt-1 text-sm text-secondary-600">
      Customize how SwiftBase Admin looks and feels
    </p>
  </div>

  <!-- Theme Mode -->
  <div>
    <label for="themeMode" class="block text-sm font-medium text-secondary-700 mb-2">
      Theme Mode
    </label>
    <select
      id="themeMode"
      value={themeStore.mode}
      onchange={handleModeChange}
      class="w-full px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
    >
      <option value="light">Light</option>
      <option value="dark">Dark</option>
    </select>
    <p class="mt-1 text-xs text-secondary-500">
      Choose between light and dark color schemes
    </p>
  </div>

  <!-- Sidebar Position -->
  <div>
    <label for="sidebarPosition" class="block text-sm font-medium text-secondary-700 mb-2">
      Sidebar Position
    </label>
    <select
      id="sidebarPosition"
      value={themeStore.sidebarPosition}
      onchange={handleSidebarPositionChange}
      class="w-full px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
    >
      <option value="left">Left</option>
      <option value="right">Right</option>
    </select>
    <p class="mt-1 text-xs text-secondary-500">
      Position the navigation sidebar on the left or right
    </p>
  </div>

  <!-- Density -->
  <div>
    <label for="density" class="block text-sm font-medium text-secondary-700 mb-2">
      Display Density
    </label>
    <select
      id="density"
      value={themeStore.density}
      onchange={handleDensityChange}
      class="w-full px-3 py-2 border border-secondary-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-primary-500"
    >
      <option value="comfortable">Comfortable</option>
      <option value="compact">Compact</option>
    </select>
    <p class="mt-1 text-xs text-secondary-500">
      Adjust spacing and padding throughout the interface
    </p>
  </div>

  <!-- Font Size -->
  <div>
    <div class="flex items-center justify-between mb-2">
      <label for="fontSize" class="block text-sm font-medium text-secondary-700">
        Font Size
      </label>
      <span class="text-sm text-secondary-600">{settingsStore.fontSize}px</span>
    </div>
    <input
      type="range"
      id="fontSize"
      min="12"
      max="20"
      step="1"
      value={settingsStore.fontSize}
      oninput={handleFontSizeChange}
      class="w-full h-2 bg-secondary-200 rounded-lg appearance-none cursor-pointer accent-primary-600"
    />
    <div class="flex justify-between text-xs text-secondary-500 mt-1">
      <span>Small (12px)</span>
      <span>Default (16px)</span>
      <span>Large (20px)</span>
    </div>
  </div>

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
