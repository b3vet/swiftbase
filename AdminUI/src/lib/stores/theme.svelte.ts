import { storage } from '@lib/utils'

type ThemeMode = 'light' | 'dark'
type SidebarPosition = 'left' | 'right'
type Density = 'comfortable' | 'compact'

interface ThemeState {
  mode: ThemeMode
  sidebarPosition: SidebarPosition
  density: Density
  sidebarCollapsed: boolean
}

const THEME_STORAGE_KEY = 'theme'

// Create theme store with Svelte 5 runes
function createThemeStore() {
  // Load from localStorage or use defaults
  const savedTheme = storage.get<ThemeState>(THEME_STORAGE_KEY)

  let state = $state<ThemeState>(
    savedTheme || {
      mode: 'light',
      sidebarPosition: 'left',
      density: 'comfortable',
      sidebarCollapsed: false
    }
  )

  // Derived values
  const mode = $derived(state.mode)
  const isDark = $derived(state.mode === 'dark')
  const sidebarPosition = $derived(state.sidebarPosition)
  const density = $derived(state.density)
  const sidebarCollapsed = $derived(state.sidebarCollapsed)

  // Track if initialized
  let initialized = false

  function init(): void {
    if (initialized) return
    initialized = true
    applyTheme()
  }

  function applyTheme(): void {
    const root = document.documentElement

    // Apply dark mode
    if (state.mode === 'dark') {
      root.classList.add('dark')
    } else {
      root.classList.remove('dark')
    }

    // Apply density
    root.setAttribute('data-density', state.density)

    // Apply sidebar position
    root.setAttribute('data-sidebar', state.sidebarPosition)
  }

  function saveTheme(): void {
    storage.set(THEME_STORAGE_KEY, state)
  }

  function toggleMode(): void {
    state.mode = state.mode === 'light' ? 'dark' : 'light'
    applyTheme()
    saveTheme()
  }

  function setMode(mode: ThemeMode): void {
    state.mode = mode
    applyTheme()
    saveTheme()
  }

  function setSidebarPosition(position: SidebarPosition): void {
    state.sidebarPosition = position
    applyTheme()
    saveTheme()
  }

  function setDensity(density: Density): void {
    state.density = density
    applyTheme()
    saveTheme()
  }

  function toggleSidebar(): void {
    state.sidebarCollapsed = !state.sidebarCollapsed
    saveTheme()
  }

  function setSidebarCollapsed(collapsed: boolean): void {
    state.sidebarCollapsed = collapsed
    saveTheme()
  }

  function reset(): void {
    state.mode = 'light'
    state.sidebarPosition = 'left'
    state.density = 'comfortable'
    state.sidebarCollapsed = false
    applyTheme()
    saveTheme()
  }

  return {
    // Initialization
    init,
    // Getters (using $derived)
    get mode() {
      return mode
    },
    get isDark() {
      return isDark
    },
    get sidebarPosition() {
      return sidebarPosition
    },
    get density() {
      return density
    },
    get sidebarCollapsed() {
      return sidebarCollapsed
    },

    // Actions
    toggleMode,
    setMode,
    setSidebarPosition,
    setDensity,
    toggleSidebar,
    setSidebarCollapsed,
    reset
  }
}

// Export singleton instance
export const themeStore = createThemeStore()
