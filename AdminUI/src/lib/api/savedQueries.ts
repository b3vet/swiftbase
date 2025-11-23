import { apiClient } from './client'
import type { SavedQuery } from '@lib/types'

// Re-export SavedQuery to ensure type consistency
export type { SavedQuery }

export interface CreateSavedQueryRequest {
	name: string
	description?: string
	collection_id: string
	action: string
	query: Record<string, any>
	data?: Record<string, any>
}

export interface UpdateSavedQueryRequest {
	description?: string
	query?: Record<string, any>
	data?: Record<string, any>
}

export interface SavedQueriesListResponse {
	saved_queries: SavedQuery[]
	count: number
}

/**
 * Get all saved queries
 */
export async function getSavedQueries(): Promise<SavedQuery[]> {
	const response = await apiClient.get<SavedQueriesListResponse>('/api/admin/saved-queries')
	if (!response.success || !response.data) {
		throw new Error(response.error || 'Failed to fetch saved queries')
	}
	return response.data.saved_queries
}

/**
 * Get a saved query by name
 */
export async function getSavedQuery(name: string): Promise<SavedQuery> {
	const response = await apiClient.get<SavedQuery>(
		`/api/admin/saved-queries/${encodeURIComponent(name)}`
	)
	if (!response.success || !response.data) {
		throw new Error(response.error || 'Failed to fetch saved query')
	}
	return response.data
}

/**
 * Create a new saved query
 */
export async function createSavedQuery(data: CreateSavedQueryRequest): Promise<SavedQuery> {
	const response = await apiClient.post<SavedQuery>('/api/admin/saved-queries', data)
	if (!response.success || !response.data) {
		throw new Error(response.error || 'Failed to create saved query')
	}
	return response.data
}

/**
 * Update an existing saved query
 */
export async function updateSavedQuery(
	name: string,
	data: UpdateSavedQueryRequest
): Promise<SavedQuery> {
	const response = await apiClient.put<SavedQuery>(
		`/api/admin/saved-queries/${encodeURIComponent(name)}`,
		data
	)
	if (!response.success || !response.data) {
		throw new Error(response.error || 'Failed to update saved query')
	}
	return response.data
}

/**
 * Delete a saved query
 */
export async function deleteSavedQuery(name: string): Promise<void> {
	const response = await apiClient.delete<{ message: string }>(
		`/api/admin/saved-queries/${encodeURIComponent(name)}`
	)
	if (!response.success) {
		throw new Error(response.error || 'Failed to delete saved query')
	}
}

/**
 * Execute a saved query by name
 */
export async function executeSavedQuery(name: string): Promise<any> {
	const response = await apiClient.post<any>(`/api/query/execute/${encodeURIComponent(name)}`)
	if (!response.success) {
		throw new Error(response.error || 'Failed to execute saved query')
	}
	return response.data
}
