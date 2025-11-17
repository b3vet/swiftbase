import { storage } from '@lib/utils'

type DefaultPage = '/' | '/collections' | '/query' | '/users' | '/files' | '/realtime' | '/api-tester'
type QueryFormat = 'table' | 'json' | 'raw'

interface SettingsState {
  defaultPage: DefaultPage
  itemsPerPage: number
  queryResultFormat: QueryFormat
  notificationsEnabled: boolean
  notificationDuration: number
  fontSize: number
}

const SETTINGS_STORAGE_KEY = 'user_settings'

// Create settings store with Svelte 5 runes
function createSettingsStore() {
  // Load from localStorage or use defaults
  const savedSettings = storage.get<SettingsState>(SETTINGS_STORAGE_KEY)

  let state = $state<SettingsState>(
    savedSettings || {
      defaultPage: '/',
      itemsPerPage: 20,
      queryResultFormat: 'table',
      notificationsEnabled: true,
      notificationDuration: 5000,
      fontSize: 16
    }
  )

  // Derived values
  const defaultPage = $derived(state.defaultPage)
  const itemsPerPage = $derived(state.itemsPerPage)
  const queryResultFormat = $derived(state.queryResultFormat)
  const notificationsEnabled = $derived(state.notificationsEnabled)
  const notificationDuration = $derived(state.notificationDuration)
  const fontSize = $derived(state.fontSize)

  // Track if initialized
  let initialized = false

  function init(): void {
    if (initialized) return
    initialized = true
    applySettings()
  }

  function applySettings(): void {
    const root = document.documentElement

    // Apply font size
    root.style.fontSize = `${state.fontSize}px`
  }

  function saveSettings(): void {
    storage.set(SETTINGS_STORAGE_KEY, state)
  }

  function setDefaultPage(page: DefaultPage): void {
    state.defaultPage = page
    saveSettings()
  }

  function setItemsPerPage(items: number): void {
    state.itemsPerPage = Math.max(5, Math.min(100, items))
    saveSettings()
  }

  function setQueryResultFormat(format: QueryFormat): void {
    state.queryResultFormat = format
    saveSettings()
  }

  function setNotificationsEnabled(enabled: boolean): void {
    state.notificationsEnabled = enabled
    saveSettings()
  }

  function setNotificationDuration(duration: number): void {
    state.notificationDuration = Math.max(1000, Math.min(10000, duration))
    saveSettings()
  }

  function setFontSize(size: number): void {
    state.fontSize = Math.max(12, Math.min(20, size))
    applySettings()
    saveSettings()
  }

  function reset(): void {
    state.defaultPage = '/'
    state.itemsPerPage = 20
    state.queryResultFormat = 'table'
    state.notificationsEnabled = true
    state.notificationDuration = 5000
    state.fontSize = 16
    applySettings()
    saveSettings()
  }

  return {
    // Initialization
    init,
    // Getters
    get defaultPage() {
      return defaultPage
    },
    get itemsPerPage() {
      return itemsPerPage
    },
    get queryResultFormat() {
      return queryResultFormat
    },
    get notificationsEnabled() {
      return notificationsEnabled
    },
    get notificationDuration() {
      return notificationDuration
    },
    get fontSize() {
      return fontSize
    },

    // Actions
    setDefaultPage,
    setItemsPerPage,
    setQueryResultFormat,
    setNotificationsEnabled,
    setNotificationDuration,
    setFontSize,
    reset
  }
}

// Export singleton instance
export const settingsStore = createSettingsStore()
