import { getExpenses, saveExpensesBatch, removeExpensesByIds, getDeletedExpenseIds, saveDeletedExpenseIds } from './db'
import { getCategories, saveCategoriesBatch, getDeletedCategoryValues, saveDeletedCategoryValues } from './categories'
import type { Expense } from '../types'
import type { CategoryItem } from './categories'
import { syncLocalDataWithCloudFile } from './cloudFileSync'

export function requestDeskappSync() {
  window.ipcRenderer?.send('request-sync-now')
  void syncLocalDataWithCloudFile().catch(error => console.warn('[MDaily Cloud Sync]', error))
}

export interface SyncStats {
  added: number
  updated: number
  total: number
}

// 2-Way Smart Merge Algorithm
export async function mergeExpensesAndCategories(
  incomingExpenses: Expense[],
  incomingCategories: CategoryItem[],
  incomingDeletedExpenseIds: string[] = [],
  incomingDeletedCategoryValues: string[] = []
): Promise<{
  mergedExpenses: Expense[]
  mergedCategories: CategoryItem[]
  deletedExpenseIds: string[]
  deletedCategoryValues: string[]
  stats: SyncStats
}> {
  const [localExpenses, localCategories] = await Promise.all([
    getExpenses(),
    getCategories()
  ])

  // 1. Merge Categories
  const deletedCategoryValues = new Set([
    ...getDeletedCategoryValues(),
    ...incomingDeletedCategoryValues
  ])
  const categoryMap = new Map<string, CategoryItem>()
  
  // Add local categories first if not deleted
  for (const cat of localCategories) {
    if (!deletedCategoryValues.has(cat.value)) {
      categoryMap.set(cat.value, { ...cat })
    }
  }
  // Add / merge incoming categories if not deleted
  for (const inCat of incomingCategories) {
    if (!deletedCategoryValues.has(inCat.value)) {
      if (!categoryMap.has(inCat.value)) {
        categoryMap.set(inCat.value, { ...inCat })
      }
    }
  }
  const mergedCategories = Array.from(categoryMap.values())

  // 2. Merge Expenses
  const expenseMap = new Map<string, Expense>()
  const deletedExpenseIds = new Set([...getDeletedExpenseIds(), ...incomingDeletedExpenseIds])
  let added = 0
  let updated = 0

  for (const ex of localExpenses) {
    if (!deletedExpenseIds.has(ex.id)) expenseMap.set(ex.id, { ...ex })
  }

  for (const inEx of incomingExpenses) {
    if (deletedExpenseIds.has(inEx.id)) continue
    if (expenseMap.has(inEx.id)) {
      const existing = expenseMap.get(inEx.id)!
      const existingTime = existing.updatedAt || new Date(existing.date).getTime() || 0
      const incomingTime = inEx.updatedAt || new Date(inEx.date).getTime() || 0

      // Choose the newer version as primary
      const newer = incomingTime >= existingTime ? inEx : existing
      const older = incomingTime >= existingTime ? existing : inEx

      const mergedItem: Expense = {
        ...older,
        ...newer,
        photo: newer.photo || older.photo,
        note: (newer.note && newer.note !== 'MDaily AI processed') ? newer.note : (older.note || newer.note),
        isAiProcessed: newer.isAiProcessed ?? older.isAiProcessed,
        updatedAt: Math.max(existingTime, incomingTime)
      }
      expenseMap.set(inEx.id, mergedItem)
      updated++
    } else {
      // Check if there is an exact duplicate by date + amount + category to prevent dups with different random IDs
      const duplicate = Array.from(expenseMap.values()).find(e => 
        e.id !== inEx.id && e.date === inEx.date && Math.abs(e.amount - inEx.amount) < 0.001 && e.category === inEx.category
      )
      if (duplicate) {
        if (!duplicate.photo && inEx.photo) {
          duplicate.photo = inEx.photo
        }
        if (!duplicate.note && inEx.note) {
          duplicate.note = inEx.note
        }
        updated++
      } else {
        expenseMap.set(inEx.id, { ...inEx })
        added++
      }
    }
  }

  // Sort descending by date
  const mergedExpenses = Array.from(expenseMap.values()).sort((a, b) => {
    return new Date(b.date).getTime() - new Date(a.date).getTime()
  })

  const mergedDeletedExpenseIds = [...new Set([...getDeletedExpenseIds(), ...Array.from(deletedExpenseIds)])]
  const mergedDeletedCategoryValues = [...new Set([...getDeletedCategoryValues(), ...Array.from(deletedCategoryValues)])]

  // Persist tombstones before the batch write so deleted records cannot be restored by a concurrent merge.
  saveDeletedExpenseIds(mergedDeletedExpenseIds)
  saveDeletedCategoryValues(mergedDeletedCategoryValues)

  // Persist merged data
  await Promise.all([
    saveExpensesBatch(mergedExpenses),
    saveCategoriesBatch(mergedCategories)
  ])
  await removeExpensesByIds(Array.from(deletedExpenseIds))

  // Dispatch event so UI instantly updates
  window.dispatchEvent(new CustomEvent('mdaily_data_synced', {
    detail: { expenses: mergedExpenses, categories: mergedCategories }
  }))

  return {
    mergedExpenses,
    mergedCategories,
    deletedExpenseIds: mergedDeletedExpenseIds,
    deletedCategoryValues: mergedDeletedCategoryValues,
    stats: {
      added,
      updated,
      total: mergedExpenses.length
    }
  }
}

// Setup IPC Listener for HTTP Server Bridge (Runs in Renderer)
export function initDeskappSyncBridge() {
  if (typeof window === 'undefined' || !window.ipcRenderer) return

  window.ipcRenderer.on('sync-bridge-request', async (_event: any, payload: any) => {
    // Handle both arguments format (event, { requestId, type, payload }) or direct object
    const req = payload && payload.requestId ? payload : _event
    const { requestId, type, payload: reqData } = req || {}
    if (!requestId) return

    try {
      if (type === 'export') {
        const [expenses, categories] = await Promise.all([getExpenses(), getCategories()])
        window.ipcRenderer?.send('sync-bridge-response', {
          requestId,
          data: {
            expenses,
            categories,
            deletedExpenseIds: getDeletedExpenseIds(),
            deletedCategoryValues: getDeletedCategoryValues()
          }
        })
      } else if (type === 'import') {
        const { expenses = [], categories = [], deletedExpenseIds = [], deletedCategoryValues = [] } = reqData || {}
        if (categories.length > 0) {
          await saveCategoriesBatch(categories)
        }
        await saveExpensesBatch(expenses)
        // Bug Fix: Union thay vì replace — giữ lại deletedIds của Deskapp (có thể có ids mà phone chưa biết)
        saveDeletedExpenseIds([...new Set([...getDeletedExpenseIds(), ...deletedExpenseIds])])
        saveDeletedCategoryValues([...new Set([...getDeletedCategoryValues(), ...deletedCategoryValues])])
        window.dispatchEvent(new CustomEvent('mdaily_data_synced', {
          detail: { expenses, categories }
        }))
        window.ipcRenderer?.send('sync-bridge-response', {
          requestId,
          data: { success: true, count: expenses.length }
        })
      } else if (type === 'merge') {
        const {
          expenses = [],
          categories = [],
          deletedExpenseIds = [],
          deletedCategoryValues = []
        } = reqData || {}
        const result = await mergeExpensesAndCategories(expenses, categories, deletedExpenseIds, deletedCategoryValues)
        window.ipcRenderer?.send('sync-bridge-response', {
          requestId,
          data: {
            success: true,
            expenses: result.mergedExpenses,
            categories: result.mergedCategories,
            deletedExpenseIds: result.deletedExpenseIds,
            deletedCategoryValues: result.deletedCategoryValues,
            stats: result.stats
          }
        })
      }
    } catch (err: any) {
      window.ipcRenderer?.send('sync-bridge-response', {
        requestId,
        error: err?.message || 'Sync operation failed'
      })
    }
  })
}
