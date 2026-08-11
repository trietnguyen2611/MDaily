import React, { useState, useEffect } from 'react'
import { Plus, MessageCircle } from 'lucide-react'
import { Dashboard } from './components/Dashboard'
import { AddExpense } from './components/AddExpense'
import { Reports } from './components/Reports'
import { SettingsPage } from './components/SettingsPage'
import { Chatbot } from './components/Chatbot'
import { Sidebar } from './components/Sidebar'
import { SearchBar } from './components/SearchBar'
import { getExpenses, saveExpense, deleteExpense } from './services/db'
import type { Expense } from './types'
import './App.css'

function App() {
  const [expenses, setExpenses] = useState<Expense[]>([])
  const [activeTab, setActiveTab] = useState<string>('dashboard')
  const [isChatOpen, setIsChatOpen] = useState(false)
  const [searchQuery, setSearchQuery] = useState('')

  useEffect(() => {
    // Load data from async DB
    const loadData = async () => {
      const data = await getExpenses()
      setExpenses(data)
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

  // Filter expenses based on search query
  const filteredExpenses = expenses.filter(ex => 
    ex.category.toLowerCase().includes(searchQuery.toLowerCase()) ||
    ex.note?.toLowerCase().includes(searchQuery.toLowerCase())
  )

  return (
    <div className="app-layout">
      <div className="titlebar-drag-region"></div>
      
      <Sidebar activeTab={activeTab} onTabChange={setActiveTab} />

      <main className="main-content">
        <div className="top-bar">
          <SearchBar value={searchQuery} onChange={setSearchQuery} />
          
          <div className="top-actions">
            <button className="circular-btn" onClick={() => setIsChatOpen(!isChatOpen)} title="Mở MDaily AI">
              <MessageCircle size={20} />
            </button>
          </div>
        </div>
        
        {activeTab === 'dashboard' && (
          <div className="scroll-container">
            <Dashboard expenses={filteredExpenses} onDelete={handleDeleteExpense} />
          </div>
        )}
        
        {activeTab === 'add-expense' && (
          <div className="non-scroll-container">
            <AddExpense 
              onSave={handleSaveExpense} 
              onCancel={() => setActiveTab('dashboard')} 
            />
          </div>
        )}

        {activeTab === 'reports' && (
          <div className="scroll-container">
            <Reports expenses={expenses} />
          </div>
        )}

        {activeTab === 'settings' && (
          <div className="scroll-container">
            <SettingsPage />
          </div>
        )}
      </main>

      <Chatbot 
        expenses={expenses} 
        isOpen={isChatOpen} 
        onClose={() => setIsChatOpen(false)} 
      />
    </div>
  )
}

export default App
