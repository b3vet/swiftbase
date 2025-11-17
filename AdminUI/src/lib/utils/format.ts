// Formatting utility functions

// Format bytes to human-readable size
export function formatBytes(bytes: number, decimals: number = 2): string {
  if (bytes === 0) return '0 Bytes'

  const k = 1024
  const dm = decimals < 0 ? 0 : decimals
  const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB']

  const i = Math.floor(Math.log(bytes) / Math.log(k))

  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i]
}

// Format date to readable string (handles UTC and converts to local timezone)
export function formatDate(date: string | Date, includeTime: boolean = true): string {
  if (!date) return 'Unknown'

  // Parse the date - if it's a string without timezone info, assume UTC
  let d: Date
  if (typeof date === 'string') {
    // If the string doesn't end with 'Z' or have timezone info, treat as UTC
    if (!date.endsWith('Z') && !date.includes('+') && !date.includes('-', 10)) {
      d = new Date(date + 'Z')
    } else {
      d = new Date(date)
    }
  } else {
    d = date
  }

  if (isNaN(d.getTime())) return 'Invalid Date'

  const dateStr = d.toLocaleDateString('en-US', {
    year: 'numeric',
    month: 'short',
    day: 'numeric'
  })

  if (!includeTime) return dateStr

  const timeStr = d.toLocaleTimeString('en-US', {
    hour: '2-digit',
    minute: '2-digit'
  })

  return `${dateStr} ${timeStr}`
}

// Format relative time (e.g., "2 hours ago") - handles UTC and converts to local timezone
export function formatRelativeTime(date: string | Date | undefined): string {
  if (!date) return 'Unknown'

  // Parse the date - if it's a string without timezone info, assume UTC
  let d: Date
  if (typeof date === 'string') {
    // If the string doesn't end with 'Z' or have timezone info, treat as UTC
    if (!date.endsWith('Z') && !date.includes('+') && !date.includes('-', 10)) {
      d = new Date(date + 'Z')
    } else {
      d = new Date(date)
    }
  } else {
    d = date
  }

  if (isNaN(d.getTime())) return 'Invalid Date'

  const now = new Date()
  const diff = now.getTime() - d.getTime()

  const seconds = Math.floor(diff / 1000)
  const minutes = Math.floor(seconds / 60)
  const hours = Math.floor(minutes / 60)
  const days = Math.floor(hours / 24)
  const weeks = Math.floor(days / 7)
  const months = Math.floor(days / 30)
  const years = Math.floor(days / 365)

  if (seconds < 60) return 'just now'
  if (minutes < 60) return `${minutes} ${minutes === 1 ? 'minute' : 'minutes'} ago`
  if (hours < 24) return `${hours} ${hours === 1 ? 'hour' : 'hours'} ago`
  if (days < 7) return `${days} ${days === 1 ? 'day' : 'days'} ago`
  if (weeks < 4) return `${weeks} ${weeks === 1 ? 'week' : 'weeks'} ago`
  if (months < 12) return `${months} ${months === 1 ? 'month' : 'months'} ago`
  return `${years} ${years === 1 ? 'year' : 'years'} ago`
}

// Format number with thousands separator
export function formatNumber(num: number): string {
  return num.toLocaleString('en-US')
}

// Truncate string with ellipsis
export function truncate(str: string, maxLength: number): string {
  if (str.length <= maxLength) return str
  return str.substring(0, maxLength - 3) + '...'
}

// Format JSON with pretty print
export function formatJSON(obj: any, indent: number = 2): string {
  try {
    return JSON.stringify(obj, null, indent)
  } catch (error) {
    return String(obj)
  }
}

// Parse JSON safely
export function parseJSON<T = any>(str: string): T | null {
  try {
    return JSON.parse(str) as T
  } catch {
    return null
  }
}

// Capitalize first letter
export function capitalize(str: string): string {
  return str.charAt(0).toUpperCase() + str.slice(1)
}

// Convert to title case
export function titleCase(str: string): string {
  return str
    .split(' ')
    .map(word => capitalize(word.toLowerCase()))
    .join(' ')
}

// Generate random ID
export function generateId(): string {
  return Math.random().toString(36).substring(2, 15) +
         Math.random().toString(36).substring(2, 15)
}
