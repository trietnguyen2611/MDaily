import { getExpenses, saveExpensesBatch, getDeletedExpenseIds, saveDeletedExpenseIds } from './db'
import { getCategories, saveCategoriesBatch, getDeletedCategoryValues, saveDeletedCategoryValues } from './categories'

const LAST_SYNC_KEY = 'mdaily_last_sync_server'

export interface SyncServerConfig {
  ip: string
  allIps?: string[]
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
  if (reconnectTimer) {
    clearTimeout(reconnectTimer)
    reconnectTimer = null
  }
}

// Check connection to Desktop Sync Server with fallback to all candidate IPs
export async function pingSyncServer(
  ip: string,
  port: number,
  candidateIps?: string[]
): Promise<{ app: string; version: string; deviceName: string; activeIp: string; allIps?: string[] }> {
  const ipsToTry = candidateIps && candidateIps.length > 0
    ? [...new Set([ip, ...candidateIps])]
    : [ip]

  for (const candidate of ipsToTry) {
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 3500)

    try {
      const res = await fetch(`http://${candidate}:${port}/api/ping`, {
        method: 'GET',
        signal: controller.signal,
        headers: { 'Accept': 'application/json' }
      })
      clearTimeout(timeout)
      if (res.ok) {
        const data = await res.json()
        return {
          ...data,
          activeIp: candidate,
          allIps: data.allIps || ipsToTry
        }
      }
    } catch {
      clearTimeout(timeout)
      // Continue to next IP
    }
  }

  throw new Error('Không thể kết nối tới máy tính (Vui lòng kiểm tra mạng Wi-Fi hoặc IP)')
}

// 1. Two-Way Smart Merge (Recommended)
export async function performTwoWayMerge(config: SyncServerConfig): Promise<SyncResult> {
  const [localExpenses, localCategories] = await Promise.all([
    getExpenses(),
    getCategories()
  ])

  // Try active IP first, fallback to allIps if needed
  const candidateIps = config.allIps && config.allIps.length > 0
    ? [...new Set([config.ip, ...config.allIps])]
    : [config.ip]

  let lastError: Error | null = null
  let activeWorkingIp = config.ip

  for (const ipToUse of candidateIps) {
    const controller = new AbortController()
    const timeout = setTimeout(() => controller.abort(), 12000)

    try {
      const res = await fetch(`http://${ipToUse}:${config.port}/api/sync/merge`, {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          'x-sync-token': config.token
        },
        body: JSON.stringify({
          token: config.token,
          expenses: localExpenses,
          categories: localCategories,
          deletedExpenseIds: getDeletedExpenseIds(),
          deletedCategoryValues: getDeletedCategoryValues()
        })
      })
      clearTimeout(timeout)

      if (!res.ok) {
        const errBody = await res.json().catch(() => ({}))
        throw new Error(errBody.error || `HTTP error ${res.status}`)
      }

      const data = await res.json()
      if (!data.success) {
        throw new Error(data.error || 'Merge failed')
      }

      activeWorkingIp = ipToUse

      // Update phone's local storage with the merged results
      if (data.expenses) {
        await saveExpensesBatch(data.expenses)
      }
      if (data.deletedExpenseIds) {
        // Bug Fix: Union với local ids để không mất tracking các expense đã xoá offline
        saveDeletedExpenseIds([...new Set([...getDeletedExpenseIds(), ...data.deletedExpenseIds])])
      }
      if (data.categories) {
        await saveCategoriesBatch(data.categories)
      }
      if (data.deletedCategoryValues) {
        saveDeletedCategoryValues([...new Set([...getDeletedCategoryValues(), ...data.deletedCategoryValues])])
      }

      saveLastSyncServer({
        ...config,
        ip: activeWorkingIp
      })

      // Notify phone UI components
      window.dispatchEvent(new CustomEvent('mdaily_data_synced', {
        detail: { expenses: data.expenses, categories: data.categories }
      }))

      return {
        success: true,
        message: `Đã hợp nhất thành công ${data.expenses?.length || 0} chi tiêu!`,
        stats: data.stats
      }
    } catch (err: any) {
      clearTimeout(timeout)
      lastError = err
    }
  }

  throw lastError || new Error('Không thể đồng bộ với máy tính')
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
      deletedExpenseIds: getDeletedExpenseIds(),
      deletedCategoryValues: getDeletedCategoryValues()
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
    // Bug Fix: Union với local ids để không mất tracking các expense đã xoá khi offline
    saveDeletedExpenseIds([...new Set([...getDeletedExpenseIds(), ...data.deletedExpenseIds])])
  }
  if (data.categories) {
    await saveCategoriesBatch(data.categories)
  }
  if (data.deletedCategoryValues) {
    saveDeletedCategoryValues([...new Set([...getDeletedCategoryValues(), ...data.deletedCategoryValues])])
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
// Real-time Automatic 2-Way Sync Engine & Reconnect Manager
// =========================================================
let autoSyncTimer: any = null
let activeEventSource: EventSource | null = null
let reconnectTimer: any = null
let reconnectDelay = 2000

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
  if (reconnectTimer) {
    clearTimeout(reconnectTimer)
    reconnectTimer = null
  }

  let isClosed = false

  const connect = () => {
    if (isClosed) return
    const currentConfig = getLastSyncServer()
    if (!currentConfig) return

    try {
      const url = `http://${currentConfig.ip}:${currentConfig.port}/api/sync/stream?token=${encodeURIComponent(currentConfig.token)}`
      const es = new EventSource(url)
      activeEventSource = es

      es.onopen = () => {
        reconnectDelay = 2000
        console.log('[MDaily SSE] Connected to Desktop Sync Stream')
      }

      es.onmessage = (event) => {
        try {
          const payload = JSON.parse(event.data)
          if (payload.event === 'data_changed') {
            console.log('[MDaily SSE] Change detected on Desktop, merging in background...')
            triggerAutoSync(50)
          }
        } catch (err) {
          console.error('[MDaily SSE Parse Error]', err)
        }
      }

      es.onerror = () => {
        es.close()
        if (activeEventSource === es) activeEventSource = null
        if (!isClosed) {
          reconnectDelay = Math.min(reconnectDelay * 1.5, 30000)
          reconnectTimer = setTimeout(connect, reconnectDelay)
        }
      }
    } catch (err) {
      console.error('Failed to start SSE sync listener', err)
      if (!isClosed) {
        reconnectTimer = setTimeout(connect, 5000)
      }
    }
  }

  connect()

  return () => {
    isClosed = true
    if (activeEventSource) {
      activeEventSource.close()
      activeEventSource = null
    }
    if (reconnectTimer) {
      clearTimeout(reconnectTimer)
      reconnectTimer = null
    }
  }
}

// Listen to browser / app foreground events to immediately sync
export function setupLifecycleSyncTriggers(): () => void {
  const handleForeground = () => {
    if (document.visibilityState === 'visible') {
      console.log('[MDaily] App became visible, triggering fast background sync...')
      triggerAutoSync(50)
    }
  }

  const handleOnline = () => {
    console.log('[MDaily] Network became online, triggering fast background sync...')
    triggerAutoSync(100)
    startRealtimeSyncListener()
  }

  document.addEventListener('visibilitychange', handleForeground)
  window.addEventListener('focus', handleForeground)
  window.addEventListener('online', handleOnline)

  return () => {
    document.removeEventListener('visibilitychange', handleForeground)
    window.removeEventListener('focus', handleForeground)
    window.removeEventListener('online', handleOnline)
  }
}
