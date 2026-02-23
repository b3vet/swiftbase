import type { Collection, CollectionStats, CreateCollectionRequest } from '@lib/types'
import { collectionsApi } from '@lib/api'

interface CollectionsState {
  collections: Collection[]
  currentCollection: Collection | null
  currentStats: CollectionStats | null
  isLoading: boolean
  error: string | null
}

// Create collections store with Svelte 5 runes
function createCollectionsStore() {
  let state = $state<CollectionsState>({
    collections: [],
    currentCollection: null,
    currentStats: null,
    isLoading: false,
    error: null
  })

  // Derived values
  const collections = $derived(state.collections)
  const currentCollection = $derived(state.currentCollection)
  const currentStats = $derived(state.currentStats)
  const isLoading = $derived(state.isLoading)
  const error = $derived(state.error)
  const collectionCount = $derived(state.collections.length)

  async function fetchAll(): Promise<void> {
    state.isLoading = true
    state.error = null

    try {
      const response = await collectionsApi.getAll()

      if (response.success && response.data) {
        // Handle both array response and object with collections property
        if (Array.isArray(response.data)) {
          state.collections = response.data
        } else if (typeof response.data === 'object' && 'collections' in response.data) {
          state.collections = (response.data as any).collections
        } else {
          state.collections = []
        }
      } else {
        state.error = response.error || 'Failed to fetch collections'
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch collections'
      state.error = message
    } finally {
      state.isLoading = false
    }
  }

  async function fetchByName(name: string): Promise<void> {
    state.isLoading = true
    state.error = null

    try {
      const response = await collectionsApi.getByName(name)

      if (response.success && response.data) {
        state.currentCollection = response.data
      } else {
        state.error = response.error || 'Failed to fetch collection'
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch collection'
      state.error = message
    } finally {
      state.isLoading = false
    }
  }

  async function fetchStats(name: string): Promise<void> {
    state.error = null

    try {
      const response = await collectionsApi.getStats(name)

      if (response.success && response.data) {
        state.currentStats = response.data
      } else {
        state.error = response.error || 'Failed to fetch stats'
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to fetch stats'
      state.error = message
    }
  }

  async function create(data: CreateCollectionRequest): Promise<boolean> {
    state.isLoading = true
    state.error = null

    try {
      const response = await collectionsApi.create(data)

      if (response.success && response.data) {
        // Add to collections list
        state.collections = [...state.collections, response.data]
        return true
      } else {
        state.error = response.error || 'Failed to create collection'
        return false
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to create collection'
      state.error = message
      return false
    } finally {
      state.isLoading = false
    }
  }

  async function update(name: string, data: Partial<Collection>): Promise<boolean> {
    state.isLoading = true
    state.error = null

    try {
      const response = await collectionsApi.update(name, data)

      if (response.success && response.data) {
        // Update in collections list
        state.collections = state.collections.map((c) =>
          c.name === name ? response.data! : c
        )

        // Update current if it's the same
        if (state.currentCollection?.name === name) {
          state.currentCollection = response.data
        }

        return true
      } else {
        state.error = response.error || 'Failed to update collection'
        return false
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to update collection'
      state.error = message
      return false
    } finally {
      state.isLoading = false
    }
  }

  async function remove(name: string): Promise<boolean> {
    state.isLoading = true
    state.error = null

    try {
      const response = await collectionsApi.delete(name)

      if (response.success) {
        // Remove from collections list
        state.collections = state.collections.filter((c) => c.name !== name)

        // Clear current if it's the same
        if (state.currentCollection?.name === name) {
          state.currentCollection = null
          state.currentStats = null
        }

        return true
      } else {
        state.error = response.error || 'Failed to delete collection'
        return false
      }
    } catch (err) {
      const message = err instanceof Error ? err.message : 'Failed to delete collection'
      state.error = message
      return false
    } finally {
      state.isLoading = false
    }
  }

  function setCurrent(collection: Collection | null): void {
    state.currentCollection = collection
    state.currentStats = null
  }

  function clearError(): void {
    state.error = null
  }

  return {
    // Getters (using $derived)
    get collections() {
      return collections
    },
    get currentCollection() {
      return currentCollection
    },
    get currentStats() {
      return currentStats
    },
    get isLoading() {
      return isLoading
    },
    get error() {
      return error
    },
    get collectionCount() {
      return collectionCount
    },

    // Actions
    fetchAll,
    fetchByName,
    fetchStats,
    create,
    update,
    remove,
    setCurrent,
    clearError
  }
}

// Export singleton instance
export const collectionsStore = createCollectionsStore()
