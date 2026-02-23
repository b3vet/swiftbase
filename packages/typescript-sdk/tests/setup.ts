// Test setup file
// This file runs before all tests

// Mock fetch if not available
if (typeof globalThis.fetch === 'undefined') {
  globalThis.fetch = async () => {
    throw new Error('fetch not mocked')
  }
}
