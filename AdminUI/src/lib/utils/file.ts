import { apiClient } from '@lib/api/client'

// Maximum file size for preview (10MB)
export const MAX_PREVIEW_SIZE = 10 * 1024 * 1024

/**
 * Check if a file can be previewed based on size
 */
export function canPreviewFile(fileSize: number): boolean {
  return fileSize <= MAX_PREVIEW_SIZE
}

/**
 * Fetch file data and create a blob URL for preview
 * Requires authentication
 */
export async function createBlobUrl(fileId: string): Promise<string> {
  const accessToken = apiClient.getAccessToken()

  if (!accessToken) {
    throw new Error('Authentication required')
  }

  const apiUrl = import.meta.env.VITE_API_URL || 'http://localhost:8090'
  const response = await fetch(`${apiUrl}/api/storage/files/${fileId}`, {
    headers: {
      'Authorization': `Bearer ${accessToken}`
    }
  })

  if (!response.ok) {
    throw new Error(`Failed to fetch file: ${response.statusText}`)
  }

  const blob = await response.blob()
  return URL.createObjectURL(blob)
}

/**
 * Cleanup blob URL to free memory
 */
export function revokeBlobUrl(url: string): void {
  if (url.startsWith('blob:')) {
    URL.revokeObjectURL(url)
  }
}
