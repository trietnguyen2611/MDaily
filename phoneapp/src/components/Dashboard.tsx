import React, { useState } from 'react'
import type { Expense } from '../types'
import { FileText, ShoppingBag, Utensils, Car, Trash2, Tag, Sparkles, Receipt } from 'lucide-react'
import { ExpenseDetailModal } from './ExpenseDetailModal'
import { getCategoryLabel } from '../services/categories'
import type { CategoryItem } from '../services/categories'
import type { SelectOption } from './CustomSelect'
import './Dashboard.css'

interface DashboardProps {
  expenses: Expense[]
  onDelete: (id: string) => void
  onUpdate: (updatedExpense: Expense) => void
  categories: CategoryItem[]
  categoryOptions: SelectOption[]
}

const CategoryIcon = ({ category, size = 20 }: { category: string; size?: number }) => {
  switch (category) {
    case 'bills': return <FileText size={size} />
    case 'shopping': return <ShoppingBag size={size} />
    case 'food': return <Utensils size={size} />
    case 'transport': return <Car size={size} />
    default: return <Tag size={size} />
  }
}

const formatDate = (dateStr: string) => {
  const d = new Date(dateStr)
  if (isNaN(d.getTime())) return dateStr
  const day = String(d.getDate()).padStart(2, '0')
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const year = d.getFullYear()
  return `${day}/${month}/${year}`
}

export const Dashboard: React.FC<DashboardProps> = ({ expenses, onDelete, onUpdate, categories, categoryOptions }) => {
  const [selectedExpense, setSelectedExpense] = useState<Expense | null>(null)

  return (
    <div className="dashboard">
      {expenses.length === 0 ? (
        <div className="empty-state">
          <Receipt size={48} />
          <p>Chưa có chi tiêu nào. Bấm "Thêm" để thêm mới.</p>
        </div>
      ) : (
        <div className="expense-grid">
          {expenses.map(expense => (
            <div
              key={expense.id}
              className={`expense-card ${!expense.photo ? 'no-photo' : ''}`}
              onClick={() => setSelectedExpense(expense)}
            >
              {expense.photo ? (
                <div className="expense-photo">
                  <img src={expense.photo} alt="Chi tiêu" />
                  {expense.isAiProcessed && (
                    <div className="ai-badge">
                      <Sparkles size={11} />
                      <span>AI</span>
                    </div>
                  )}
                </div>
              ) : (
                <div className="expense-icon-placeholder">
                  <CategoryIcon category={expense.category} size={32} />
                </div>
              )}
              <div className="expense-info">
                <div className="expense-meta">
                  <span className="category">
                    <CategoryIcon category={expense.category} />
                    {getCategoryLabel(categories, expense.category)}
                  </span>
                  <span className="date">{formatDate(expense.date)}</span>
                </div>
                <h3>{expense.amount.toLocaleString('vi-VN')} đ</h3>
                {expense.note && expense.note !== 'MDaily AI processed' && <p className="note">{expense.note}</p>}
              </div>
              <button
                className="btn-icon delete-btn"
                onClick={(e) => {
                  e.stopPropagation()
                  if (confirm('Xoá chi tiêu này?')) onDelete(expense.id)
                }}
                title="Xoá chi tiêu"
              >
                <Trash2 size={16} />
              </button>
            </div>
          ))}
        </div>
      )}

      <ExpenseDetailModal
        expense={selectedExpense}
        onClose={() => setSelectedExpense(null)}
        onDelete={onDelete}
        onUpdate={(updated) => { onUpdate(updated); setSelectedExpense(updated) }}
        categories={categories}
        categoryOptions={categoryOptions}
      />
    </div>
  )
}
