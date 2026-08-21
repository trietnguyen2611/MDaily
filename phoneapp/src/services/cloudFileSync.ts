import { Capacitor } from '@capacitor/core'
import { AFMPlugin } from './ai'
import { getExpenses, saveExpensesBatch, getDeletedExpenseIds, saveDeletedExpenseIds } from './db'
import { getCategories, saveCategoriesBatch, getDeletedCategoryValues, saveDeletedCategoryValues } from './categories'

export interface SyncFilePayload {
  version: 1
  updatedAt: number
  expenses: any[]
  categories: any[]
  deletedExpenseIds: string[]
  deletedCategoryValues: string[]
}

export async function chooseCloudSyncFile() {
  if (!Capacitor.isNativePlatform()) throw new Error('iCloud file sync requires the iOS app')
  return AFMPlugin.chooseSyncFile()
}

export async function ensureCloudSyncFile() {
  if (!Capacitor.isNativePlatform()) throw new Error('iCloud file sync requires the iOS app')
  return AFMPlugin.ensureSyncFile()
}

export async function readCloudSyncFile(): Promise<SyncFilePayload | null> {
  if (!Capacitor.isNativePlatform()) return null
  const result = await AFMPlugin.readSyncFile()
  if (!result.configured || !result.contents) return null
  try {
    return JSON.parse(result.contents) as SyncFilePayload
  } catch {
    console.warn('[MDaily Cloud Sync] Selected file is not valid JSON. Attempting self-healing with initial payload.')
    const initial: SyncFilePayload = {
      version: 1,
      updatedAt: Date.now(),
      expenses: [],
      categories: [],
      deletedExpenseIds: [],
      deletedCategoryValues: []
    }
    try {
      await writeCloudSyncFile(initial)
    } catch (writeErr) {
      console.error('[MDaily Cloud Sync] Failed to initialize file during self-healing:', writeErr)
    }
    return initial
  }
}

export async function writeCloudSyncFile(payload: SyncFilePayload) {
  if (!Capacitor.isNativePlatform()) throw new Error('iCloud file sync requires the iOS app')
  return AFMPlugin.writeSyncFile({ contents: JSON.stringify(payload) })
}

export async function getCloudSyncFileName(): Promise<string | null> {
  if (!Capacitor.isNativePlatform()) return null
  try {
    const result = await AFMPlugin.readSyncFile()
    return result?.configured && result.name ? result.name : null
  } catch {
    return null
  }
}

export async function syncLocalDataWithCloudFile(): Promise<boolean> {
  const remote = await readCloudSyncFile()
  if (!remote) return false
  
  const [localExpenses, localCategories] = await Promise.all([getExpenses(), getCategories()])
  
  const remoteDeletedExpenseIds = Array.isArray(remote.deletedExpenseIds)
    ? remote.deletedExpenseIds.filter((id): id is string => typeof id === 'string')
    : []
  const remoteDeletedCategoryValues = Array.isArray(remote.deletedCategoryValues)
    ? remote.deletedCategoryValues.filter((val): val is string => typeof val === 'string')
    : []

  const deletedExpenses = new Set([...getDeletedExpenseIds(), ...remoteDeletedExpenseIds])
  const deletedCategories = new Set([...getDeletedCategoryValues(), ...remoteDeletedCategoryValues])
  
  const expenses = new Map<string, any>()
  const rawRemoteExpenses = Array.isArray(remote.expenses) ? remote.expenses : []
  for (const expense of [...localExpenses, ...rawRemoteExpenses]) {
    if (expense && typeof expense.id === 'string' && !deletedExpenses.has(expense.id)) {
      const current = expenses.get(expense.id)
      const currentTime = current?.updatedAt || Date.parse(current?.date || '') || 0
      const incomingTime = expense.updatedAt || Date.parse(expense.date || '') || 0
      if (!current || incomingTime >= currentTime) {
        expenses.set(expense.id, expense)
      }
    }
  }
  
  const categories = new Map<string, any>()
  const rawRemoteCategories = Array.isArray(remote.categories) ? remote.categories : []
  for (const category of [...localCategories, ...rawRemoteCategories]) {
    if (category && typeof category.value === 'string' && !deletedCategories.has(category.value)) {
      categories.set(category.value, category)
    }
  }
  
  const mergedDeletedExpenses = [...deletedExpenses]
  const mergedDeletedCategories = [...deletedCategories]
  
  saveDeletedExpenseIds(mergedDeletedExpenses)
  saveDeletedCategoryValues(mergedDeletedCategories)
  
  const mergedExpenses = [...expenses.values()]
  const mergedCategories = [...categories.values()]
  
  await Promise.all([saveExpensesBatch(mergedExpenses), saveCategoriesBatch(mergedCategories)])
  await writeCloudSyncFile({
    version: 1,
    updatedAt: Date.now(),
    expenses: mergedExpenses,
    categories: mergedCategories,
    deletedExpenseIds: mergedDeletedExpenses,
    deletedCategoryValues: mergedDeletedCategories
  })
  
  window.dispatchEvent(new CustomEvent('mdaily_data_synced'))
  return true
}

let cloudSyncTimer: any = null
let cloudSyncInFlight = false

export function triggerCloudSync(delay = 1000) {
  if (!Capacitor.isNativePlatform()) return

  if (cloudSyncTimer) clearTimeout(cloudSyncTimer)
  cloudSyncTimer = setTimeout(async () => {
    if (cloudSyncInFlight) return
    cloudSyncInFlight = true
    try {
      const synced = await syncLocalDataWithCloudFile()
      if (synced) {
        console.log('[MDaily Cloud Sync] Auto-sync completed successfully')
      }
    } catch (err) {
      console.warn('[MDaily Cloud Sync] Auto-sync failed:', err)
    } finally {
      cloudSyncInFlight = false
    }
  }, delay)
}