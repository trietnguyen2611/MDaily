import localforage from 'localforage'
import type { SelectOption } from '../components/CustomSelect'

const CATEGORIES_KEY = 'mdaily_categories'

export interface CategoryItem {
  value: string
  label: string
}

const DEFAULT_CATEGORIES: CategoryItem[] = [
  { value: 'bills', label: 'Hoá đơn' },
  { value: 'shopping', label: 'Mua sắm' },
  { value: 'food', label: 'Ăn uống' },
  { value: 'transport', label: 'Di chuyển' },
]

export const getCategories = async (): Promise<CategoryItem[]> => {
  try {
    const data = await localforage.getItem<CategoryItem[]>(CATEGORIES_KEY)
    return data && data.length > 0 ? data : DEFAULT_CATEGORIES
  } catch {
    return DEFAULT_CATEGORIES
  }
}

export const saveCategories = async (categories: CategoryItem[]): Promise<CategoryItem[]> => {
  await localforage.setItem(CATEGORIES_KEY, categories)
  return categories
}

export const addCategory = async (label: string): Promise<CategoryItem[]> => {
  const categories = await getCategories()
  const value = label
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '')
    .replace(/đ/g, 'd')
    .replace(/Đ/g, 'D')
    .replace(/\s+/g, '-')
    .replace(/[^a-z0-9-]/g, '')
  
  if (categories.some(c => c.value === value)) {
    return categories
  }

  const updated = [...categories, { value, label }]
  await localforage.setItem(CATEGORIES_KEY, updated)
  return updated
}

export const deleteCategory = async (value: string): Promise<CategoryItem[]> => {
  const categories = await getCategories()
  const updated = categories.filter(c => c.value !== value)
  await localforage.setItem(CATEGORIES_KEY, updated)
  return updated
}

export const updateCategory = async (oldValue: string, newLabel: string): Promise<CategoryItem[]> => {
  const categories = await getCategories()
  const updated = categories.map(c => {
    if (c.value === oldValue) {
      return { ...c, label: newLabel }
    }
    return c
  })
  await localforage.setItem(CATEGORIES_KEY, updated)
  return updated
}

export const categoriesToSelectOptions = (categories: CategoryItem[]): SelectOption[] => {
  return categories.map(c => ({ value: c.value, label: c.label }))
}

export const getCategoryLabel = (categories: CategoryItem[], value: string): string => {
  const found = categories.find(c => c.value === value)
  return found ? found.label : value
}
