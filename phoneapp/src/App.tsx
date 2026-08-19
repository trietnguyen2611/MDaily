import { useState, useEffect, useMemo, useCallback } from 'react'
import { Sparkles } from 'lucide-react'
import { Dashboard } from './components/Dashboard'
import { AddExpense } from './components/AddExpense'
import { Reports } from './components/Reports'
import { SettingsPage } from './components/SettingsPage'
import { BottomTabBar } from './components/BottomTabBar'
import { Chatbot } from './components/Chatbot'
import { CustomSelect } from './components/CustomSelect'
import { SplashScreen } from './components/SplashScreen'
import { getExpenses, saveExpense, deleteExpense, updateExpense } from './services/db'
import { getCategories, addCategory, deleteCategory, updateCategory, categoriesToSelectOptions } from './services/categories'
import { checkAFMStatus, getAutoExtractEnabled, getAiChatEnabled } from './services/ai'
import type { CategoryItem } from './services/categories'
import type { Expense } from './types'
import './App.css'

function App() {
  const [expenses, setExpenses] = useState<Expense[]>([])
  const [categories, setCategories] = useState<CategoryItem[]>([])
  const [activeTab, setActiveTab] = useState<string>('dashboard')
  const [isChatOpen, setIsChatOpen] = useState(false)
  const [timeFilter, setTimeFilter] = useState('all')
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [isKeyboardOpen, setIsKeyboardOpen] = useState(false)
  const [isScrolled, setIsScrolled] = useState(false)
  const [quickPhoto, setQuickPhoto] = useState<string | null>(null)

  // AI state
  const [isAFMAvailable, setIsAFMAvailable] = useState(false)
  const [autoExtractEnabled, setAutoExtractEnabledState] = useState(getAutoExtractEnabled())
  const [aiChatEnabled, setAiChatEnabledState] = useState(getAiChatEnabled())

  const refreshAiSettings = useCallback(() => {
    setAutoExtractEnabledState(getAutoExtractEnabled())
    setAiChatEnabledState(getAiChatEnabled())
  }, [])

  // Check AFM on mount
  useEffect(() => {
    checkAFMStatus().then(status => setIsAFMAvailable(status.available))
  }, [])

  // Listen to keyboard show/hide events
  useEffect(() => {
    const handleFocusIn = (e: FocusEvent) => {
      const target = e.target as HTMLElement | null
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) {
        const inputType = (target as HTMLInputElement).type
        if (inputType !== 'file' && inputType !== 'checkbox' && inputType !== 'radio') {
          setIsKeyboardOpen(true)
        }
      }
    }
    const handleFocusOut = () => setIsKeyboardOpen(false)
    const handleViewportResize = () => {
      if (window.visualViewport) {
        const isShrunk = window.innerHeight - window.visualViewport.height > 140
        setIsKeyboardOpen(isShrunk)
      }
    }

    window.addEventListener('focusin', handleFocusIn)
    window.addEventListener('focusout', handleFocusOut)
    window.visualViewport?.addEventListener('resize', handleViewportResize)
    return () => {
      window.removeEventListener('focusin', handleFocusIn)
      window.removeEventListener('focusout', handleFocusOut)
      window.visualViewport?.removeEventListener('resize', handleViewportResize)
    }
  }, [])

  const handleScroll = (e: React.UIEvent<HTMLDivElement>) => {
    const nextScrolled = e.currentTarget.scrollTop > 8
    setIsScrolled(prev => prev !== nextScrolled ? nextScrolled : prev)
  }

  const handleTabChange = (newTab: string) => {
    setActiveTab(newTab)
    setIsScrolled(false)
  }

  const handleQuickPhotoCaptured = (photoBase64: string) => {
    setQuickPhoto(photoBase64)
    handleTabChange('add-expense')
  }

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
    setQuickPhoto(null)
    handleTabChange('dashboard')
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

  const getLocalYYYYMMDD = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-${String(d.getDate()).padStart(2, '0')}`
  const getLocalYYYYMM = (d: Date) => `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`

  const filteredExpenses = useMemo(() => {
    return expenses.filter(ex => {
      if (categoryFilter !== 'all' && ex.category !== categoryFilter) return false
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
  }, [expenses, categoryFilter, timeFilter, customDate, customMonth, customYear, customStartDate, customEndDate])

  const getPageTitle = (tab: string) => {
    switch (tab) {
      case 'dashboard': return 'Tổng quan'
      case 'add-expense': return 'Thêm chi tiêu'
      case 'reports': return 'Phân loại'
      case 'settings': return 'Cài đặt'
      default: return ''
    }
  }

  // Show AI chat button only when AFM available AND AI chat enabled
  const showAiChat = isAFMAvailable && aiChatEnabled

  return (
    <div className="app-layout">
      <SplashScreen />

      <main className="main-content">
        <div className="top-bar">
          <h2 className="page-header-title">{getPageTitle(activeTab)}</h2>
          <div className="top-bar-right">
            {showAiChat && (
              <button
                className="ai-chat-trigger-btn"
                onClick={() => setIsChatOpen(true)}
                title="Mở MDaily AI"
              >
                <Sparkles size={16} className="ai-btn-sparkle" />
                <span>MDaily AI</span>
              </button>
            )}
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
          <div className={`scroll-container ${isScrolled ? 'is-scrolled' : ''}`} onScroll={handleScroll}>
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
          <div className={`scroll-container ${isScrolled ? 'is-scrolled' : ''}`} onScroll={handleScroll}>
            <AddExpense
              onSave={handleSaveExpense}
              onCancel={() => { setQuickPhoto(null); handleTabChange('dashboard') }}
              categoryOptions={categoryOptions}
              onAddCategory={handleAddCategory}
              initialPhoto={quickPhoto}
              isAFMAvailable={isAFMAvailable}
              autoExtractEnabled={autoExtractEnabled}
            />
          </div>
        )}

        {activeTab === 'reports' && (
          <div className={`scroll-container ${isScrolled ? 'is-scrolled' : ''}`} onScroll={handleScroll}>
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
          <div className={`scroll-container ${isScrolled ? 'is-scrolled' : ''}`} onScroll={handleScroll}>
            <SettingsPage
              onDataCleared={() => setExpenses([])}
              onAiSettingsChanged={refreshAiSettings}
            />
          </div>
        )}
      </main>

      <BottomTabBar
        activeTab={activeTab}
        onTabChange={handleTabChange}
        onQuickPhotoCaptured={handleQuickPhotoCaptured}
        isKeyboardOpen={isKeyboardOpen}
      />

      {showAiChat && (
        <Chatbot
          expenses={expenses}
          categories={categories}
          isOpen={isChatOpen}
          onClose={() => setIsChatOpen(false)}
        />
      )}
    </div>
  )
}

export default App
