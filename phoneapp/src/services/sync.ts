import { getExpenses, saveExpensesBatch, getDeletedExpenseIds, saveDeletedExpenseIds } from './db'
import { getCategories, saveCategoriesBatch } from './categories'

const LAST_SYNC_KEY = 'mdaily_last_sync_server'

export interface SyncServerConfig {
  ip: string
  port: number
  token: string
  name?: string
  lastSyncTime?: number
}

export interface SyncResult {
  success: boolean
  message: string
  stats?: {
    added: number
    updated: number
    total: number
  }
}

export function getLastSyncServer(): SyncServerConfig | null {
  try {
    const raw = localStorage.getItem(LAST_SYNC_KEY)
    return raw ? JSON.parse(raw) : null
  } catch {
    return null
  }
}

export function saveLastSyncServer(config: SyncServerConfig) {
  localStorage.setItem(LAST_SYNC_KEY, JSON.stringify({
    ...config,
    lastSyncTime: Date.now()
  }))
  window.dispatchEvent(new CustomEvent('mdaily_sync_server_changed'))
}

export function clearLastSyncServer() {
  localStorage.removeItem(LAST_SYNC_KEY)
  if (activeEventSource) {
    activeEventSource.close()
    activeEventSource = null
  }
}

// Check connection to Desktop Sync Server with 4s timeout
export async function pingSyncServer(ip: string, port: number): Promise<{ app: string; version: string; deviceName: string }> {
  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), 4000)

  try {
    const res = await fetch(`http://${ip}:${port}/api/ping`, {
      method: 'GET',
      signal: controller.signal,
      headers: { 'Accept': 'application/json' }
    })
    clearTimeout(timeout)
    if (!res.ok) {
      throw new Error(`Server returned ${res.status}`)
    }
    return await res.json()
  } catch (err: any) {
    clearTimeout(timeout)
    throw new Error(err?.name === 'AbortError' ? 'Timeout connecting to Desktop' : (err?.message || 'Connection failed'))
  }
}

// 1. Two-Way Smart Merge (Recommended)
export async function performTwoWayMerge(config: SyncServerConfig): Promise<SyncResult> {
  const [localExpenses, localCategories] = await Promise.all([
    getExpenses(),
    getCategories()
  ])

  const res = await fetch(`http://${config.ip}:${config.port}/api/sync/merge`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-sync-token': config.token
    },
    body: JSON.stringify({
      token: config.token,
      expenses: localExpenses,
      categories: localCategories,
      deletedExpenseIds: getDeletedExpenseIds()
    })
  })

  if (!res.ok) {
    const errBody = await res.json().catch(() => ({}))
    throw new Error(errBody.error || `HTTP error ${res.status}`)
  }

  const data = await res.json()
  if (!data.success) {
    throw new Error(data.error || 'Merge failed')
  }

  // Update phone's local storage with the merged results
  if (data.expenses) {
    await saveExpensesBatch(data.expenses)
  }
  if (data.deletedExpenseIds) {
    saveDeletedExpenseIds(data.deletedExpenseIds)
  }
  if (data.categories) {
    await saveCategoriesBatch(data.categories)
  }

  saveLastSyncServer(config)

  // Notify phone UI components
  window.dispatchEvent(new CustomEvent('mdaily_data_synced', {
    detail: { expenses: data.expenses, categories: data.categories }
  }))

  return {
    success: true,
    message: `Đã hợp nhất thành công ${data.expenses?.length || 0} chi tiêu!`,
    stats: data.stats
  }
}

// 2. Push from Phone -> Desktop (Upload)
export async function performPushToDesktop(config: SyncServerConfig): Promise<SyncResult> {
  const [localExpenses, localCategories] = await Promise.all([
    getExpenses(),
    getCategories()
  ])

  const res = await fetch(`http://${config.ip}:${config.port}/api/sync/push`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-sync-token': config.token
    },
    body: JSON.stringify({
      token: config.token,
      expenses: localExpenses,
      categories: localCategories,
      deletedExpenseIds: getDeletedExpenseIds()
    })
  })

  if (!res.ok) {
    const errBody = await res.json().catch(() => ({}))
    throw new Error(errBody.error || `HTTP error ${res.status}`)
  }

  const data = await res.json()
  if (!data.success) {
    throw new Error(data.error || 'Push failed')
  }

  saveLastSyncServer(config)

  return {
    success: true,
    message: `Đã tải ${localExpenses.length} chi tiêu lên máy tính thành công!`
  }
}

// 3. Pull from Desktop -> Phone (Download)
export async function performPullFromDesktop(config: SyncServerConfig): Promise<SyncResult> {
  const res = await fetch(`http://${config.ip}:${config.port}/api/sync/pull`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'x-sync-token': config.token
    },
    body: JSON.stringify({
      token: config.token
    })
  })

  if (!res.ok) {
    const errBody = await res.json().catch(() => ({}))
    throw new Error(errBody.error || `HTTP error ${res.status}`)
  }

  const data = await res.json()
  if (!data.success) {
    throw new Error(data.error || 'Pull failed')
  }

  if (data.expenses) {
    await saveExpensesBatch(data.expenses)
  }
  if (data.deletedExpenseIds) {
    saveDeletedExpenseIds(data.deletedExpenseIds)
  }
  if (data.categories) {
    await saveCategoriesBatch(data.categories)
  }

  saveLastSyncServer(config)

  window.dispatchEvent(new CustomEvent('mdaily_data_synced', {
    detail: { expenses: data.expenses, categories: data.categories }
  }))

  return {
    success: true,
    message: `Đã tải về ${data.expenses?.length || 0} chi tiêu từ máy tính thành công!`
  }
}

// =========================================================
// Real-time Automatic 2-Way Sync Engine
// =========================================================
let autoSyncTimer: any = null
let activeEventSource: EventSource | null = null

export function triggerAutoSync(delay = 250) {
  const config = getLastSyncServer()
  if (!config) return

  if (autoSyncTimer) clearTimeout(autoSyncTimer)
  autoSyncTimer = setTimeout(async () => {
    try {
      await performTwoWayMerge(config)
      console.log('[MDaily Auto-Sync] Background 2-way sync completed')
    } catch (err) {
      console.warn('[MDaily Auto-Sync] Skipped (Desktop may be offline):', err)
    }
  }, delay)
}

export function startRealtimeSyncListener(): () => void {
  const config = getLastSyncServer()
  if (!config) return () => {}

  if (activeEventSource) {
    activeEventSource.close()
    activeEventSource = null
  }

  try {
    const url = `http://${config.ip}:${config.port}/api/sync/stream?token=${encodeURIComponent(config.token)}`
    const es = new EventSource(url)
    activeEventSource = es

    es.onmessage = (event) => {
      try {
        const payload = JSON.parse(event.data)
        if (payload.event === 'data_changed') {
          console.log('[MDaily SSE] Change detected on Desktop, merging in background...')
          triggerAutoSync(100)
        }
      } catch (err) {
        console.error('[MDaily SSE Parse Error]', err)
      }
    }

    es.onerror = () => {
      // EventSource reconnects automatically
    }

    return () => {
      es.close()
      if (activeEventSource === es) activeEventSource = null
    }
  } catch (err) {
    console.error('Failed to start SSE sync listener', err)
    return () => {}
  }
}
