import React, { useState, useEffect } from 'react'
import { Plus, MessageCircle } from 'lucide-react'
import { Dashboard } from './components/Dashboard'
import { AddExpense } from './components/AddExpense'
import { Reports } from './components/Reports'
import { SettingsPage } from './components/SettingsPage'
import { Chatbot } from './components/Chatbot'
import { Sidebar } from './components/Sidebar'
import { SearchBar } from './components/SearchBar'
import { CustomSelect } from './components/CustomSelect'
import { getExpenses, saveExpense, deleteExpense, updateExpense } from './services/db'
import { getCategories, addCategory, deleteCategory, updateCategory, categoriesToSelectOptions } from './services/categories'
import type { CategoryItem } from './services/categories'
import type { Expense } from './types'
import './App.css'

function App() {
  const [expenses, setExpenses] = useState<Expense[]>([])
  const [categories, setCategories] = useState<CategoryItem[]>([])
  const [activeTab, setActiveTab] = useState<string>('dashboard')
  const [isChatOpen, setIsChatOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')
  const [timeFilter, setTimeFilter] = useState('all')
  const [categoryFilter, setCategoryFilter] = useState('all')
  
  const [customDate, setCustomDate] = useState('')
  const [customMonth, setCustomMonth] = useState('')
  const [customYear, setCustomYear] = useState(new Date().getFullYear().toString())
  const [customStartDate, setCustomStartDate] = useState('')
  const [customEndDate, setCustomEndDate] = useState('')

  useEffect(() => {
    const loadData = async () => {
      const [expData, catData] = await Promise.all([getExpenses(), getCategories()])
      setExpenses(expData)
      setCategories(catData)
    }
    loadData()
  }, [])

  const handleSaveExpense = async (newExpenseData: Omit<Expense, 'id' | 'date'>) => {
    const expense: Expense = {
      ...newExpenseData,
      id: Date.now().toString(),
      date: new Date().toISOString()
    }
    const updated = await saveExpense(expense)
    setExpenses([...updated])
    setActiveTab('dashboard')
  }

  const handleDeleteExpense = async (id: string) => {
    const updated = await deleteExpense(id)
    setExpenses([...updated])
  }

  const handleUpdateExpense = async (updatedExpense: Expense) => {
    const updated = await updateExpense(updatedExpense)
    setExpenses([...updated])
  }

  const handleAddCategory = async (label: string) => {
    const updated = await addCategory(label)
    setCategories([...updated])
  }

  const handleDeleteCategory = async (value: string) => {
    const updated = await deleteCategory(value)
    setCategories([...updated])
  }

  const handleUpdateCategory = async (oldValue: string, newLabel: string) => {
    const updated = await updateCategory(oldValue, newLabel)
    setCategories([...updated])
  }

  const categoryOptions = categoriesToSelectOptions(categories)
  const allCategoryOptions = [{ value: 'all', label: 'Tất cả danh mục' }, ...categoryOptions]

  const timeOptions = [
    { value: 'all', label: 'Tất cả thời gian' },
    { value: 'today', label: 'Hôm nay' },
    { value: 'this_week', label: 'Tuần này' },
    { value: 'this_month', label: 'Tháng này' },
    { value: 'this_year', label: 'Năm nay' },
    { value: 'custom_day', label: 'Chọn ngày cụ thể...' },
    { value: 'custom_month', label: 'Chọn tháng cụ thể...' },
    { value: 'custom_year', label: 'Chọn năm cụ thể...' },
    { value: 'custom_range', label: 'Khoảng thời gian...' }
  ]

  const getLocalYYYYMMDD = (d: Date) => {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    const date = String(d.getDate()).padStart(2, '0')
    return `${y}-${m}-${date}`
  }
  const getLocalYYYYMM = (d: Date) => {
    const y = d.getFullYear()
    const m = String(d.getMonth() + 1).padStart(2, '0')
    return `${y}-${m}`
  }

  // Filter expenses based on search query, time, and category
  const filteredExpenses = expenses.filter(ex => {
    // 1. Search
    const matchesSearch = ex.category.toLowerCase().includes(searchQuery.toLowerCase()) || 
                          (ex.note && ex.note.toLowerCase().includes(searchQuery.toLowerCase()))
    if (!matchesSearch) return false

    // 2. Category Filter
    if (categoryFilter !== 'all' && ex.category !== categoryFilter) return false

    // 3. Time Filter
    if (timeFilter !== 'all') {
      const exDate = new Date(ex.date)
      const now = new Date()
      
      if (timeFilter === 'today') {
        if (exDate.toDateString() !== now.toDateString()) return false
      } else if (timeFilter === 'this_week') {
        const today = new Date()
        const firstDayOfWeek = new Date(today.setDate(today.getDate() - today.getDay() + (today.getDay() === 0 ? -6 : 1)))
        firstDayOfWeek.setHours(0, 0, 0, 0)
        if (exDate < firstDayOfWeek) return false
      } else if (timeFilter === 'this_month') {
        if (exDate.getMonth() !== now.getMonth() || exDate.getFullYear() !== now.getFullYear()) return false
      } else if (timeFilter === 'this_year') {
        if (exDate.getFullYear() !== now.getFullYear()) return false
      } else if (timeFilter === 'custom_day' && customDate) {
        if (getLocalYYYYMMDD(exDate) !== customDate) return false
      } else if (timeFilter === 'custom_month' && customMonth) {
        if (getLocalYYYYMM(exDate) !== customMonth) return false
      } else if (timeFilter === 'custom_year' && customYear) {
        if (exDate.getFullYear().toString() !== customYear) return false
      } else if (timeFilter === 'custom_range') {
        const exDateStr = getLocalYYYYMMDD(exDate)
        if (customStartDate && exDateStr < customStartDate) return false
        if (customEndDate && exDateStr > customEndDate) return false
      }
    }

    return true
  })

  const getPageTitle = (tab: string) => {
    switch (tab) {
      case 'dashboard': return 'Tổng quan'
      case 'add-expense': return 'Thêm chi tiêu'
      case 'reports': return 'Phân loại'
      case 'settings': return 'Cài đặt'
      default: return ''
    }
  }

  return (
    <div className="app-layout">
      <div className="titlebar-drag-region"></div>

      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />

      <main className="main-content">
        <div className="top-bar">
          <h2 className="page-header-title">{getPageTitle(activeTab)}</h2>
          <div className="top-bar-right">
            <SearchBar value={searchQuery} onChange={setSearchQuery} />
            <div className="top-actions">
              <button className="circular-btn" onClick={() => setIsChatOpen(!isChatOpen)} title="Mở MDaily AI">
                <MessageCircle size={20} />
              </button>
            </div>
          </div>
        </div>

        <div className="content-header">
          {(activeTab === 'dashboard' || activeTab === 'reports') && (
            <div className="filter-group">
              <CustomSelect
                options={timeOptions}
                value={timeFilter}
                onChange={setTimeFilter}
              />
              
              {timeFilter === 'custom_day' && (
                <input type="date" className="custom-filter-input" value={customDate} onChange={e => setCustomDate(e.target.value)} />
              )}
              {timeFilter === 'custom_month' && (
                <input type="month" className="custom-filter-input" value={customMonth} onChange={e => setCustomMonth(e.target.value)} />
              )}
              {timeFilter === 'custom_year' && (
                <input type="number" min="2000" max="2100" className="custom-filter-input" value={customYear} onChange={e => setCustomYear(e.target.value)} placeholder="Năm" />
              )}
              {timeFilter === 'custom_range' && (
                <div className="custom-range-group">
                  <input type="date" className="custom-filter-input" value={customStartDate} onChange={e => setCustomStartDate(e.target.value)} title="Từ ngày" />
                  <span className="range-separator">-</span>
                  <input type="date" className="custom-filter-input" value={customEndDate} onChange={e => setCustomEndDate(e.target.value)} title="Đến ngày" />
                </div>
              )}

              <CustomSelect
                options={allCategoryOptions}
                value={categoryFilter}
                onChange={setCategoryFilter}
              />
            </div>
          )}
        </div>

        {activeTab === 'dashboard' && (
          <div className="scroll-container">
            <Dashboard
              expenses={filteredExpenses}
              onDelete={handleDeleteExpense}
              onUpdate={handleUpdateExpense}
              categories={categories}
              categoryOptions={categoryOptions}
            />
          </div>
        )}

        {activeTab === 'add-expense' && (
          <div className="non-scroll-container">
            <AddExpense
              onSave={handleSaveExpense}
              onCancel={() => setActiveTab('dashboard')}
              categoryOptions={categoryOptions}
              onAddCategory={handleAddCategory}
            />
          </div>
        )}

        {activeTab === 'reports' && (
          <div className="non-scroll-container">
            <Reports
              expenses={filteredExpenses}
              categories={categories}
              onAddCategory={handleAddCategory}
              onDeleteCategory={handleDeleteCategory}
              onUpdateCategory={handleUpdateCategory}
            />
          </div>
        )}

        {activeTab === 'settings' && (
          <div className="scroll-container">
            <SettingsPage onDataCleared={() => setExpenses([])} />
          </div>
        )}
      </main>

      <Chatbot
        expenses={expenses}
        categories={categories}
        isOpen={isChatOpen}
        onClose={() => setIsChatOpen(false)}
      />
    </div>
  )
}

export default App
