import localforage from 'localforage'
import type { Expense } from '../types'

const DB_KEY = 'mdaily_expenses'
const DELETED_IDS_KEY = 'mdaily_deleted_expense_ids'

const notifyExpenseMutation = () => {
  window.dispatchEvent(new CustomEvent('mdaily_expense_changed'))
}

export const getDeletedExpenseIds = (): string[] => {
  try {
    return JSON.parse(localStorage.getItem(DELETED_IDS_KEY) || '[]')
  } catch {
    return []
  }
}

export const saveDeletedExpenseIds = (ids: string[]) => {
  localStorage.setItem(DELETED_IDS_KEY, JSON.stringify([...new Set(ids)]))
}

const removeDeletedExpenseId = (id: string) => {
  saveDeletedExpenseIds(getDeletedExpenseIds().filter(deletedId => deletedId !== id))
}

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
  removeDeletedExpenseId(expense.id)
  notifyExpenseMutation()
  return expenses
}

export const deleteExpense = async (id: string): Promise<Expense[]> => {
  const expenses = await getExpenses()
  const updated = expenses.filter(e => e.id !== id)
  await localforage.setItem(DB_KEY, updated)
  saveDeletedExpenseIds([...getDeletedExpenseIds(), id])
  notifyExpenseMutation()
  return updated
}

export const updateExpense = async (updatedExpense: Expense): Promise<Expense[]> => {
  const expenses = await getExpenses()
  const updatedList = expenses.map(e => e.id === updatedExpense.id ? updatedExpense : e)
  await localforage.setItem(DB_KEY, updatedList)
  removeDeletedExpenseId(updatedExpense.id)
  notifyExpenseMutation()
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
  notifyExpenseMutation()
}
