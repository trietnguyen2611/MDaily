import { useState, useEffect, useMemo, useCallback } from 'react'
import { Sparkles, Wifi } from 'lucide-react'
import { Dashboard } from './components/Dashboard'
import { AddExpense } from './components/AddExpense'
import { Reports } from './components/Reports'
import { SettingsPage } from './components/SettingsPage'
import { BottomTabBar } from './components/BottomTabBar'
import { Chatbot } from './components/Chatbot'
import { CustomSelect } from './components/CustomSelect'
import { SplashScreen } from './components/SplashScreen'
import { WifiSyncModal } from './components/WifiSyncModal'
import { getExpenses, saveExpense, deleteExpense, updateExpense } from './services/db'
import { getCategories, addCategory, deleteCategory, updateCategory, categoriesToSelectOptions } from './services/categories'
import { checkAFMStatus, getAutoExtractEnabled, getAiChatEnabled } from './services/ai'
import { getLanguage, getCurrency, t } from './services/i18n'
import type { Language, Currency } from './services/i18n'
import { triggerAutoSync, startRealtimeSyncListener } from './services/sync'
import type { CategoryItem } from './services/categories'
import type { Expense } from './types'
import './App.css'

function App() {
  const [expenses, setExpenses] = useState<Expense[]>([])
  const [categories, setCategories] = useState<CategoryItem[]>([])
  const [activeTab, setActiveTab] = useState<string>('dashboard')
  const [isChatOpen, setIsChatOpen] = useState(false)
  const [isSyncModalOpen, setIsSyncModalOpen] = useState(false)
  const [timeFilter, setTimeFilter] = useState('all')
  const [categoryFilter, setCategoryFilter] = useState('all')
  const [isKeyboardOpen, setIsKeyboardOpen] = useState(false)
  const [isScrolled, setIsScrolled] = useState(false)
  const [quickPhoto, setQuickPhoto] = useState<string | null>(null)

  // Language & Currency settings state
  const [lang, setLang] = useState<Language>(getLanguage())
  const [, setCurr] = useState<Currency>(getCurrency())

  const handleSettingsChanged = useCallback(() => {
    setLang(getLanguage())
    setCurr(getCurrency())
  }, [])

  const reloadData = useCallback(async () => {
    const [expData, catData] = await Promise.all([getExpenses(), getCategories()])
    setExpenses(expData)
    setCategories(catData)
  }, [])

  // Listen to cross-window or internal settings events & sync events
  useEffect(() => {
    const handleSettingEvent = () => {
      setLang(getLanguage())
      setCurr(getCurrency())
    }
    window.addEventListener('mdaily_settings_change', handleSettingEvent)
    window.addEventListener('mdaily_data_synced', reloadData)

    let stopListener = startRealtimeSyncListener()
    const restartSyncListener = () => {
      stopListener()
      stopListener = startRealtimeSyncListener()
      triggerAutoSync(0)
    }
    const handleLocalExpenseChange = () => triggerAutoSync()
    window.addEventListener('mdaily_sync_server_changed', restartSyncListener)
    window.addEventListener('mdaily_expense_changed', handleLocalExpenseChange)

    return () => {
      window.removeEventListener('mdaily_settings_change', handleSettingEvent)
      window.removeEventListener('mdaily_data_synced', reloadData)
      window.removeEventListener('mdaily_sync_server_changed', restartSyncListener)
      window.removeEventListener('mdaily_expense_changed', handleLocalExpenseChange)
      stopListener()
    }
  }, [reloadData])

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
    const handleSettingsChange = () => {
      refreshAiSettings()
      checkAFMStatus().then(status => setIsAFMAvailable(status.available))
    }
    window.addEventListener('mdaily_settings_change', handleSettingsChange)
    return () => window.removeEventListener('mdaily_settings_change', handleSettingsChange)
  }, [refreshAiSettings])

  // Listen to keyboard show/hide events
  useEffect(() => {
    const handleFocusIn = (e: FocusEvent) => {
      const target = e.target as HTMLElement | null
      if (target && (target.tagName === 'INPUT' || target.tagName === 'TEXTAREA' || target.isContentEditable)) {
        const inputType = (target as HTMLInputElement).type
        if (inputType !== 'file' && inputType !== 'checkbox' && inputType !== 'radio' && inputType !== 'submit' && inputType !== 'button') {
          setIsKeyboardOpen(true)
        }
      }
    }
    const handleFocusOut = () => {
      setTimeout(() => {
        const active = document.activeElement as HTMLElement | null
        const isStillInput = active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA' || active.isContentEditable)
        const isShrunk = window.visualViewport ? (window.innerHeight - window.visualViewport.height > 120) : false
        if (!isStillInput && !isShrunk) {
          setIsKeyboardOpen(false)
        }
      }, 50)
    }
    const handleViewportResize = () => {
      if (window.visualViewport) {
        const isShrunk = window.innerHeight - window.visualViewport.height > 120
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
    triggerAutoSync()
  }

  const handleDeleteCategory = async (value: string) => {
    const updated = await deleteCategory(value)
    setCategories([...updated])
    triggerAutoSync()
  }

  const handleUpdateCategory = async (oldValue: string, newLabel: string) => {
    const updated = await updateCategory(oldValue, newLabel)
    setCategories([...updated])
    triggerAutoSync()
  }

  const categoryOptions = categoriesToSelectOptions(categories)
  const allCategoryOptions = [{ value: 'all', label: t('all_categories', lang) }, ...categoryOptions]

  const timeOptions = [
    { value: 'all', label: t('all_time', lang) },
    { value: 'today', label: t('today', lang) },
    { value: 'this_week', label: t('this_week', lang) },
    { value: 'this_month', label: t('this_month', lang) },
    { value: 'this_year', label: t('this_year', lang) },
    { value: 'custom_day', label: t('custom_day', lang) },
    { value: 'custom_month', label: t('custom_month', lang) },
    { value: 'custom_year', label: t('custom_year', lang) },
    { value: 'custom_range', label: t('custom_range', lang) }
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
      case 'dashboard': return t('tab_dashboard', lang)
      case 'add-expense': return t('tab_add_expense', lang)
      case 'reports': return t('tab_reports', lang)
      case 'settings': return t('tab_settings', lang)
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
            <button
              className="wifi-sync-trigger-btn"
              onClick={() => setIsSyncModalOpen(true)}
              title={t('wifi_sync', lang)}
            >
              <Wifi size={16} />
              <span>{t('wifi_sync', lang)}</span>
            </button>
            {showAiChat && (
              <button
                className="ai-chat-trigger-btn"
                onClick={() => setIsChatOpen(true)}
                title={t('mdaily_ai', lang)}
              >
                <Sparkles size={16} className="ai-btn-sparkle" />
                <span>{t('mdaily_ai', lang)}</span>
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
                <input type="number" min="2000" max="2100" className="custom-filter-input" value={customYear} onChange={e => setCustomYear(e.target.value)} placeholder={t('year_placeholder', lang)} />
              )}
              {timeFilter === 'custom_range' && (
                <div className="custom-range-group">
                  <input type="date" className="custom-filter-input" value={customStartDate} onChange={e => setCustomStartDate(e.target.value)} title={t('from_date', lang)} />
                  <span className="range-separator">-</span>
                  <input type="date" className="custom-filter-input" value={customEndDate} onChange={e => setCustomEndDate(e.target.value)} title={t('to_date', lang)} />
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
              onSettingsChanged={handleSettingsChanged}
              onOpenWifiSync={() => setIsSyncModalOpen(true)}
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

      <WifiSyncModal
        isOpen={isSyncModalOpen}
        onClose={() => setIsSyncModalOpen(false)}
        onSyncCompleted={reloadData}
      />
    </div>
  )
}

export default App
