<script lang="ts">
  import { Badge } from '@components/common'
  import { formatRelativeTime, truncate } from '@lib/utils'

  interface Props {
    documents: any[]
    onView?: (document: any) => void
    onEdit?: (document: any) => void
    onDelete?: (document: any) => void
  }

  let {
    documents,
    onView,
    onEdit,
    onDelete
  }: Props = $props()

  let searchTerm = $state('')
  let currentPage = $state(1)
  let itemsPerPage = $state(10)

  const filteredDocuments = $derived(
    documents.filter((doc) => {
      if (!searchTerm) return true
      const searchStr = JSON.stringify(doc.data).toLowerCase()
      return searchStr.includes(searchTerm.toLowerCase())
    })
  )

  const totalPages = $derived(Math.ceil(filteredDocuments.length / itemsPerPage))
  const paginatedDocuments = $derived(
    filteredDocuments.slice(
      (currentPage - 1) * itemsPerPage,
      currentPage * itemsPerPage
    )
  )

  function handleViewClick(event: MouseEvent, document: any) {
    event.stopPropagation()
    onView?.(document)
  }

  function handleEditClick(event: MouseEvent, document: any) {
    event.stopPropagation()
    onEdit?.(document)
  }

  function handleDeleteClick(event: MouseEvent, document: any) {
    event.stopPropagation()
    onDelete?.(document)
  }

  function goToPage(page: number) {
    if (page >= 1 && page <= totalPages) {
      currentPage = page
    }
  }

  function getDocumentPreview(doc: any): string {
    const data = doc.data || {}
    // Remove internal fields like _id for cleaner preview
    const cleanData = Object.keys(data)
      .filter(k => !k.startsWith('_'))
      .reduce((obj, key) => {
        obj[key] = data[key]
        return obj
      }, {} as any)

    if (Object.keys(cleanData).length === 0) return 'Empty document'

    // Format as pretty JSON with 2-space indentation
    return JSON.stringify(cleanData, null, 2)
  }
</script>

<div class="space-y-4">
  <!-- Search and Filters -->
  <div class="flex items-center justify-between">
    <div class="flex-1 max-w-lg">
      <input
        type="search"
        bind:value={searchTerm}
        placeholder="Search documents..."
        class="block w-full rounded-lg border border-secondary-300 px-4 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500 focus:border-primary-500"
      />
    </div>
    <div class="ml-4">
      <select
        bind:value={itemsPerPage}
        class="rounded-lg border border-secondary-300 px-3 py-2 text-sm focus:outline-none focus:ring-2 focus:ring-primary-500"
        onchange={() => (currentPage = 1)}
      >
        <option value={10}>10 per page</option>
        <option value={25}>25 per page</option>
        <option value={50}>50 per page</option>
        <option value={100}>100 per page</option>
      </select>
    </div>
  </div>

  <!-- Results Count -->
  <div class="text-sm text-secondary-600">
    Showing {paginatedDocuments.length} of {filteredDocuments.length} documents
  </div>

  <!-- Documents Table -->
  <div class="bg-white rounded-lg shadow-sm border border-secondary-200 overflow-hidden">
    <div class="overflow-x-auto">
      <table class="min-w-full divide-y divide-secondary-200">
        <thead class="bg-secondary-50">
          <tr>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              ID
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Preview
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Version
            </th>
            <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Updated
            </th>
            <th class="px-6 py-3 text-right text-xs font-medium text-secondary-500 uppercase tracking-wider">
              Actions
            </th>
          </tr>
        </thead>
        <tbody class="bg-white divide-y divide-secondary-200">
          {#each paginatedDocuments as document (document.id)}
            <tr class="hover:bg-secondary-50 cursor-pointer" onclick={() => onView?.(document)}>
              <td class="px-6 py-4 whitespace-nowrap">
                <code class="text-xs text-secondary-900 bg-secondary-100 px-2 py-1 rounded">
                  {truncate(document.id, 12)}
                </code>
              </td>
              <td class="px-6 py-4">
                <pre class="text-xs font-mono text-secondary-900 bg-secondary-100 px-3 py-2 rounded max-w-md overflow-hidden" style="display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; line-height: 1.4;">{getDocumentPreview(document)}</pre>
              </td>
              <td class="px-6 py-4 whitespace-nowrap">
                <Badge variant="default" size="sm">v{document.version}</Badge>
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-sm text-secondary-500">
                {formatRelativeTime(document.updated_at)}
              </td>
              <td class="px-6 py-4 whitespace-nowrap text-right text-sm font-medium space-x-2">
                <button
                  type="button"
                  class="text-primary-600 hover:text-primary-900"
                  onclick={(e) => handleViewClick(e, document)}
                >
                  View
                </button>
                <button
                  type="button"
                  class="text-blue-600 hover:text-blue-900"
                  onclick={(e) => handleEditClick(e, document)}
                >
                  Edit
                </button>
                <button
                  type="button"
                  class="text-red-600 hover:text-red-900"
                  onclick={(e) => handleDeleteClick(e, document)}
                >
                  Delete
                </button>
              </td>
            </tr>
          {/each}

          {#if paginatedDocuments.length === 0}
            <tr>
              <td colspan="5" class="px-6 py-12 text-center">
                <div class="text-secondary-500">
                  {searchTerm ? 'No documents match your search' : 'No documents found'}
                </div>
              </td>
            </tr>
          {/if}
        </tbody>
      </table>
    </div>
  </div>

  <!-- Pagination -->
  {#if totalPages > 1}
    <div class="flex items-center justify-between">
      <div class="text-sm text-secondary-600">
        Page {currentPage} of {totalPages}
      </div>
      <div class="flex space-x-2">
        <button
          type="button"
          class="px-3 py-1 rounded-md border border-secondary-300 text-sm text-secondary-700 hover:bg-secondary-50 disabled:opacity-50 disabled:cursor-not-allowed"
          onclick={() => goToPage(currentPage - 1)}
          disabled={currentPage === 1}
        >
          Previous
        </button>

        {#each Array.from({ length: Math.min(5, totalPages) }, (_, i) => {
          let pageNum = currentPage - 2 + i
          if (pageNum < 1) pageNum = i + 1
          if (pageNum > totalPages) pageNum = totalPages - (4 - i)
          return pageNum
        }) as page}
          {#if page >= 1 && page <= totalPages}
            <button
              type="button"
              class="px-3 py-1 rounded-md border text-sm {page === currentPage
                ? 'bg-primary-600 text-white border-primary-600'
                : 'border-secondary-300 text-secondary-700 hover:bg-secondary-50'}"
              onclick={() => goToPage(page)}
            >
              {page}
            </button>
          {/if}
        {/each}

        <button
          type="button"
          class="px-3 py-1 rounded-md border border-secondary-300 text-sm text-secondary-700 hover:bg-secondary-50 disabled:opacity-50 disabled:cursor-not-allowed"
          onclick={() => goToPage(currentPage + 1)}
          disabled={currentPage === totalPages}
        >
          Next
        </button>
      </div>
    </div>
  {/if}
</div>
