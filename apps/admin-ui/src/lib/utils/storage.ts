// LocalStorage utility functions

const PREFIX = 'swiftbase_'

export const storage = {
  // Set item in localStorage
  set<T>(key: string, value: T): void {
    try {
      const serialized = JSON.stringify(value)
      localStorage.setItem(PREFIX + key, serialized)
    } catch (error) {
      console.error('Error saving to localStorage:', error)
    }
  },

  // Get item from localStorage
  get<T>(key: string): T | null {
    try {
      const item = localStorage.getItem(PREFIX + key)
      if (!item) return null
      return JSON.parse(item) as T
    } catch (error) {
      console.error('Error reading from localStorage:', error)
      return null
    }
  },

  // Remove item from localStorage
  remove(key: string): void {
    try {
      localStorage.removeItem(PREFIX + key)
    } catch (error) {
      console.error('Error removing from localStorage:', error)
    }
  },

  // Clear all items with prefix
  clear(): void {
    try {
      const keys = Object.keys(localStorage)
      keys.forEach((key) => {
        if (key.startsWith(PREFIX)) {
          localStorage.removeItem(key)
        }
      })
    } catch (error) {
      console.error('Error clearing localStorage:', error)
    }
  },

  // Check if key exists
  has(key: string): boolean {
    return localStorage.getItem(PREFIX + key) !== null
  }
}
