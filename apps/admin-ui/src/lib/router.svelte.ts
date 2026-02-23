import type { Component } from 'svelte'
import { authStore } from '@lib/stores'

export interface Route {
  path: string
  component: Component
  requiresAuth?: boolean
  title?: string
}

export interface RouteMatch {
  route: Route
  params: Record<string, string>
}

interface RouterState {
  currentPath: string
  currentRoute: Route | null
  params: Record<string, string>
}

// Create router store with Svelte 5 runes
function createRouter() {
  let state = $state<RouterState>({
    currentPath: '',
    currentRoute: null,
    params: {}
  })

  const routes: Route[] = []

  // Derived values
  const currentPath = $derived(state.currentPath)
  const currentRoute = $derived(state.currentRoute)
  const params = $derived(state.params)

  // Initialize router
  function init(): void {
    // Listen to hash changes
    window.addEventListener('hashchange', handleHashChange)

    // Handle initial route
    handleHashChange()
  }

  // Register a route
  function register(route: Route): void {
    routes.push(route)
  }

  // Register multiple routes
  function registerRoutes(routeList: Route[]): void {
    routes.push(...routeList)
  }

  // Handle hash change
  function handleHashChange(): void {
    const hash = window.location.hash.slice(1) || '/'
    navigate(hash, false)
  }

  // Navigate to a path
  function navigate(path: string, updateHash: boolean = true): void {
    // Update hash if needed
    if (updateHash) {
      window.location.hash = '#' + path
      return // hashchange event will handle the rest
    }

    // Find matching route
    const match = matchRoute(path)

    if (!match) {
      // Route not found, redirect to dashboard or login
      if (authStore.isAuthenticated) {
        navigate('/', true)
      } else {
        navigate('/login', true)
      }
      return
    }

    // Check authentication
    if (match.route.requiresAuth && !authStore.isAuthenticated) {
      navigate('/login', true)
      return
    }

    // Redirect to dashboard if already logged in and trying to access login
    if (path === '/login' && authStore.isAuthenticated) {
      navigate('/', true)
      return
    }

    // Update state
    state.currentPath = path
    state.currentRoute = match.route
    state.params = match.params

    // Update document title
    if (match.route.title) {
      document.title = `${match.route.title} - SwiftBase Admin`
    } else {
      document.title = 'SwiftBase Admin'
    }
  }

  // Match route with path
  function matchRoute(path: string): RouteMatch | null {
    for (const route of routes) {
      const params = matchPath(route.path, path)
      if (params !== null) {
        return { route, params }
      }
    }
    return null
  }

  // Match path pattern with actual path
  function matchPath(pattern: string, path: string): Record<string, string> | null {
    const patternParts = pattern.split('/').filter(Boolean)
    const pathParts = path.split('/').filter(Boolean)

    if (patternParts.length !== pathParts.length) {
      return null
    }

    const params: Record<string, string> = {}

    for (let i = 0; i < patternParts.length; i++) {
      const patternPart = patternParts[i]
      const pathPart = pathParts[i]

      if (patternPart.startsWith(':')) {
        // Dynamic segment
        const paramName = patternPart.slice(1)
        params[paramName] = decodeURIComponent(pathPart)
      } else if (patternPart !== pathPart) {
        // Static segment doesn't match
        return null
      }
    }

    return params
  }

  // Get param value
  function getParam(name: string): string | undefined {
    return state.params[name]
  }

  // Go back
  function back(): void {
    window.history.back()
  }

  // Go forward
  function forward(): void {
    window.history.forward()
  }

  return {
    // Getters
    get currentPath() {
      return currentPath
    },
    get currentRoute() {
      return currentRoute
    },
    get params() {
      return params
    },

    // Actions
    init,
    register,
    registerRoutes,
    navigate,
    getParam,
    back,
    forward
  }
}

// Export singleton instance
export const router = createRouter()
