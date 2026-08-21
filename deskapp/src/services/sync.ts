import { getExpenses, saveExpensesBatch, getDeletedExpenseIds, saveDeletedExpenseIds } from './db'
import { getCategories, saveCategoriesBatch, addCategory } from './categories'
import type { Expense } from '../types'
import type { CategoryItem } from './categories'

export interface SyncStats {
  added: number
  updated: number
  total: number
}

// 2-Way Smart Merge Algorithm
export async function mergeExpensesAndCategories(
  incomingExpenses: Expense[],
  incomingCategories: CategoryItem[],
  incomingDeletedExpenseIds: string[] = []
): Promise<{
  mergedExpenses: Expense[]
  mergedCategories: CategoryItem[]
  deletedExpenseIds: string[]
  stats: SyncStats
}> {
  const [localExpenses, localCategories] = await Promise.all([
    getExpenses(),
    getCategories()
  ])

  // 1. Merge Categories
  const categoryMap = new Map<string, CategoryItem>()
  // Add local categories first
  for (const cat of localCategories) {
    categoryMap.set(cat.value, { ...cat })
  }
  // Add / merge incoming categories
  for (const inCat of incomingCategories) {
    if (!categoryMap.has(inCat.value)) {
      categoryMap.set(inCat.value, { ...inCat })
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
      // Merge properties: keep photo if existing doesn't have it or incoming has it
      const mergedItem: Expense = {
        ...existing,
        ...inEx,
        photo: inEx.photo || existing.photo,
        note: (inEx.note && inEx.note !== 'MDaily AI processed') ? inEx.note : (existing.note || inEx.note),
        isAiProcessed: existing.isAiProcessed || inEx.isAiProcessed
      }
      expenseMap.set(inEx.id, mergedItem)
      updated++
    } else {
      // Check if there is an exact duplicate by date + amount + category to prevent dups with different random IDs
      const duplicate = Array.from(expenseMap.values()).find(e => 
        e.date === inEx.date && e.amount === inEx.amount && e.category === inEx.category
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

  // Persist merged data
  await Promise.all([
    saveExpensesBatch(mergedExpenses),
    saveCategoriesBatch(mergedCategories)
  ])
  saveDeletedExpenseIds(Array.from(deletedExpenseIds))

  // Dispatch event so UI instantly updates
  window.dispatchEvent(new CustomEvent('mdaily_data_synced', {
    detail: { expenses: mergedExpenses, categories: mergedCategories }
  }))

  return {
    mergedExpenses,
    mergedCategories,
    deletedExpenseIds: Array.from(deletedExpenseIds),
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
          data: { expenses, categories, deletedExpenseIds: getDeletedExpenseIds() }
        })
      } else if (type === 'import') {
        const { expenses = [], categories = [], deletedExpenseIds = [] } = reqData || {}
        if (categories.length > 0) {
          await saveCategoriesBatch(categories)
        }
        await saveExpensesBatch(expenses)
        saveDeletedExpenseIds(deletedExpenseIds)
        window.dispatchEvent(new CustomEvent('mdaily_data_synced', {
          detail: { expenses, categories }
        }))
        window.ipcRenderer?.send('sync-bridge-response', {
          requestId,
          data: { success: true, count: expenses.length }
        })
      } else if (type === 'merge') {
        const { expenses = [], categories = [], deletedExpenseIds = [] } = reqData || {}
        const result = await mergeExpensesAndCategories(expenses, categories, deletedExpenseIds)
        window.ipcRenderer?.send('sync-bridge-response', {
          requestId,
          data: {
            success: true,
            expenses: result.mergedExpenses,
            categories: result.mergedCategories,
            deletedExpenseIds: result.deletedExpenseIds,
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
