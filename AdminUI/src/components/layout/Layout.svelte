<script lang="ts">
  import type { Snippet } from 'svelte'
  import Navbar from './Navbar.svelte'
  import Sidebar from './Sidebar.svelte'

  interface Props {
    children: Snippet
  }

  let { children }: Props = $props()
</script>

<div class="min-h-screen bg-secondary-50">
  <!-- Navbar -->
  <Navbar />

  <!-- Sidebar -->
  <Sidebar />

  <!-- Main Content -->
  <main class="pt-16 lg:pl-64 transition-all duration-200">
    <div class="p-6 lg:p-8">
      {@render children()}
    </div>
  </main>
</div>
