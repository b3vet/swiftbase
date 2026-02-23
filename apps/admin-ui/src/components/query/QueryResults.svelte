<script lang="ts">
  import { Badge, JsonViewer } from '@components/common'

  interface Props {
    result: any
    executionTime?: number
  }

  let {
    result,
    executionTime
  }: Props = $props()

  let viewMode = $state<'table' | 'json'>('table')

  const hasData = $derived(result?.data !== undefined && result?.data !== null)
  const isArray = $derived(Array.isArray(result?.data))
  const count = $derived(result?.count ?? (isArray ? result.data.length : null))

  // Extract column headers from array data - collect all unique keys from all results
  const columns = $derived<string[]>(
    (!isArray || !result.data || result.data.length === 0)
      ? []
      : (Array.from(
          new Set(
            result.data.flatMap((item: any) => Object.keys(item))
          )
        ) as string[]).slice(0, 20) // Limit to first 20 columns
  )

  function formatValue(value: any): string {
    if (value === null || value === undefined) return '-'
    if (typeof value === 'object') return JSON.stringify(value)
    if (typeof value === 'boolean') return value ? 'true' : 'false'
    return String(value)
  }

  function truncateString(str: string, maxLength: number = 50): string {
    if (str.length <= maxLength) return str
    return str.substring(0, maxLength - 3) + '...'
  }
</script>

<div class="bg-white rounded-lg shadow-sm border border-secondary-200">
  <!-- Results Header -->
  <div class="px-6 py-4 border-b border-secondary-200">
    <div class="flex items-center justify-between">
      <div class="flex items-center space-x-4">
        <h3 class="text-lg font-semibold text-secondary-900">Query Results</h3>
        {#if count !== null}
          <Badge variant="info">{count} {count === 1 ? 'result' : 'results'}</Badge>
        {/if}
        {#if executionTime !== undefined}
          <span class="text-sm text-secondary-500">
            Executed in {executionTime.toFixed(2)}ms
          </span>
        {/if}
      </div>

      <!-- View Mode Toggle -->
      {#if hasData && isArray}
        <div class="inline-flex rounded-lg border border-secondary-200 p-1">
          <button
            type="button"
            class="px-3 py-1.5 rounded-md text-sm font-medium transition-colors {viewMode === 'table'
              ? 'bg-primary-600 text-white'
              : 'text-secondary-600 hover:text-secondary-900'}"
            onclick={() => (viewMode = 'table')}
          >
            Table
          </button>
          <button
            type="button"
            class="px-3 py-1.5 rounded-md text-sm font-medium transition-colors {viewMode === 'json'
              ? 'bg-primary-600 text-white'
              : 'text-secondary-600 hover:text-secondary-900'}"
            onclick={() => (viewMode = 'json')}
          >
            JSON
          </button>
        </div>
      {/if}
    </div>
  </div>

  <!-- Results Body -->
  <div class="p-6">
    {#if !hasData}
      <!-- No Results -->
      <div class="text-center py-12">
        <svg class="mx-auto h-12 w-12 text-secondary-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
          <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M20 13V6a2 2 0 00-2-2H6a2 2 0 00-2 2v7m16 0v5a2 2 0 01-2 2H6a2 2 0 01-2-2v-5m16 0h-2.586a1 1 0 00-.707.293l-2.414 2.414a1 1 0 01-.707.293h-3.172a1 1 0 01-.707-.293l-2.414-2.414A1 1 0 006.586 13H4" />
        </svg>
        <h3 class="mt-2 text-sm font-medium text-secondary-900">No results</h3>
        <p class="mt-1 text-sm text-secondary-500">
          The query returned no data
        </p>
      </div>

    {:else if isArray && viewMode === 'table' && columns.length > 0}
      <!-- Table View -->
      <div class="overflow-x-auto">
        <table class="min-w-full divide-y divide-secondary-200">
          <thead class="bg-secondary-50">
            <tr>
              {#each columns as column}
                <th class="px-6 py-3 text-left text-xs font-medium text-secondary-500 uppercase tracking-wider">
                  {column}
                </th>
              {/each}
            </tr>
          </thead>
          <tbody class="bg-white divide-y divide-secondary-200">
            {#each result.data as row, index}
              <tr class="hover:bg-secondary-50">
                {#each columns as column}
                  <td class="px-6 py-4 whitespace-nowrap text-sm text-secondary-900">
                    {truncateString(formatValue(row[column]))}
                  </td>
                {/each}
              </tr>
            {/each}
          </tbody>
        </table>
      </div>

    {:else}
      <!-- JSON View -->
      <JsonViewer data={result.data} />
    {/if}
  </div>
</div>