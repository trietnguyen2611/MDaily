import localforage from 'localforage'
import type { Expense } from '../types'

const DB_KEY = 'mdaily_expenses'
const DELETED_IDS_KEY = 'mdaily_deleted_expense_ids'

// Configure localforage to use IndexedDB explicitly
localforage.config({
  name: 'MDailyApp',
  storeName: 'expenses_store'
})

const notifyDeskappMutation = () => {
  if (typeof window !== 'undefined') {
    const ipc = (window as any).ipcRenderer || (window as any).require?.('electron')?.ipcRenderer
    if (ipc) {
      ipc.send('broadcast-sync-event', { type: 'expense_changed', timestamp: Date.now() })
    }
  }
}

export const getDeletedExpenseIds = (): string[] => {
  try {
    return JSON.parse(localStorage.getItem(DELETED_IDS_KEY) || '[]')
  } catch {
    return []
  }
}

export const saveDeletedExpenseIds = (ids: string[]) => {
  const unique = [...new Set(ids)]
  // Keep latest 1000 items
  const trimmed = unique.slice(-1000)
  localStorage.setItem(DELETED_IDS_KEY, JSON.stringify(trimmed))
}

const removeDeletedExpenseId = (id: string) => {
  saveDeletedExpenseIds(getDeletedExpenseIds().filter(deletedId => deletedId !== id))
}

export const getExpenses = async (): Promise<Expense[]> => {
  try {
    const data = await localforage.getItem<Expense[]>(DB_KEY)
    return data || []
  } catch (error) {
    console.error('Failed to read expenses', error)
    return []
  }
}

export const saveExpense = async (expense: Expense): Promise<Expense[]> => {
  const expenses = await getExpenses()
  const toSave: Expense = {
    ...expense,
    updatedAt: expense.updatedAt || Date.now()
  }
  expenses.unshift(toSave) // newest first
  await localforage.setItem(DB_KEY, expenses)
  removeDeletedExpenseId(toSave.id)
  notifyDeskappMutation()
  return expenses
}

export const deleteExpense = async (id: string): Promise<Expense[]> => {
  const expenses = await getExpenses()
  const updated = expenses.filter(e => e.id !== id)
  await localforage.setItem(DB_KEY, updated)
  saveDeletedExpenseIds([...getDeletedExpenseIds(), id])
  notifyDeskappMutation()
  return updated
}

export const updateExpense = async (updatedExpense: Expense): Promise<Expense[]> => {
  const expenses = await getExpenses()
  const toUpdate: Expense = {
    ...updatedExpense,
    updatedAt: Date.now()
  }
  const updatedList = expenses.map(e => e.id === toUpdate.id ? toUpdate : e)
  await localforage.setItem(DB_KEY, updatedList)
  removeDeletedExpenseId(toUpdate.id)
  notifyDeskappMutation()
  return updatedList
}

export const saveExpensesBatch = async (newExpenses: Expense[]): Promise<Expense[]> => {
  await localforage.setItem(DB_KEY, newExpenses)
  return newExpenses
}

export const clearExpenses = async () => {
  const expenses = await getExpenses()
  saveDeletedExpenseIds([...getDeletedExpenseIds(), ...expenses.map(expense => expense.id)])
  await localforage.removeItem(DB_KEY)
  notifyDeskappMutation()
}
