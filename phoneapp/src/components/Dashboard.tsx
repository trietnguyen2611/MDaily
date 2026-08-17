import React, { useState } from 'react'
import type { Expense } from '../types'
import { FileText, ShoppingBag, Utensils, Car, Trash2, Tag, Sparkles } from 'lucide-react'
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

const CategoryIcon = ({ category }: { category: string }) => {
  switch (category) {
    case 'bills': return <FileText size={20} />
    case 'shopping': return <ShoppingBag size={20} />
    case 'food': return <Utensils size={20} />
    case 'transport': return <Car size={20} />
    default: return <Tag size={20} />
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
          <p>Chưa có chi tiêu nào. Bấm "Thêm chi tiêu" để thêm mới.</p>
        </div>
      ) : (
        <div className="expense-grid">
          {expenses.map(expense => (
            <div
              key={expense.id}
              className="expense-card"
              onClick={() => setSelectedExpense(expense)}
            >
              <div className="expense-photo">
                <img src={expense.photo} alt="Chi tiêu" />
                {expense.isAiProcessed && (
                  <div className="ai-badge">
                    <Sparkles size={11} />
                    <span>MDaily AI</span>
                  </div>
                )}
              </div>
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
                  if (confirm('Xoá chi tiêu này?')) {
                    onDelete(expense.id)
                  }
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
        onUpdate={(updated) => {
          onUpdate(updated)
          setSelectedExpense(updated)
        }}
        categories={categories}
        categoryOptions={categoryOptions}
      />
    </div>
  )
}
