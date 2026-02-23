import { generateId } from '@lib/utils'

export type NotificationType = 'success' | 'error' | 'warning' | 'info'

export interface Notification {
  id: string
  type: NotificationType
  message: string
  duration?: number
  dismissible?: boolean
}

interface NotificationsState {
  notifications: Notification[]
}

// Create notifications store with Svelte 5 runes
function createNotificationsStore() {
  let state = $state<NotificationsState>({
    notifications: []
  })

  // Derived values
  const notifications = $derived(state.notifications)
  const count = $derived(state.notifications.length)

  function add(
    type: NotificationType,
    message: string,
    duration: number = 5000,
    dismissible: boolean = true
  ): string {
    const id = generateId()

    const notification: Notification = {
      id,
      type,
      message,
      duration,
      dismissible
    }

    state.notifications = [...state.notifications, notification]

    // Auto dismiss after duration
    if (duration > 0) {
      setTimeout(() => {
        remove(id)
      }, duration)
    }

    return id
  }

  function remove(id: string): void {
    state.notifications = state.notifications.filter((n) => n.id !== id)
  }

  function clear(): void {
    state.notifications = []
  }

  // Convenience methods
  function success(message: string, duration?: number): string {
    return add('success', message, duration)
  }

  function error(message: string, duration?: number): string {
    return add('error', message, duration)
  }

  function warning(message: string, duration?: number): string {
    return add('warning', message, duration)
  }

  function info(message: string, duration?: number): string {
    return add('info', message, duration)
  }

  return {
    // Getters (using $derived)
    get notifications() {
      return notifications
    },
    get count() {
      return count
    },

    // Actions
    add,
    remove,
    clear,
    success,
    error,
    warning,
    info
  }
}

// Export singleton instance
export const notificationsStore = createNotificationsStore()
