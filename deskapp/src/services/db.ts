import localforage from 'localforage'
import type { Expense } from '../types'

const DB_KEY = 'mdaily_expenses'

// Configure localforage to use IndexedDB explicitly
localforage.config({
  name: 'MDailyApp',
  storeName: 'expenses_store'
})

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
  expenses.unshift(expense) // newest first
  await localforage.setItem(DB_KEY, expenses)
  return expenses
}

export const deleteExpense = async (id: string): Promise<Expense[]> => {
  const expenses = await getExpenses()
  const updated = expenses.filter(e => e.id !== id)
  await localforage.setItem(DB_KEY, updated)
  return updated
}

export const clearExpenses = async () => {
  await localforage.removeItem(DB_KEY)
}
