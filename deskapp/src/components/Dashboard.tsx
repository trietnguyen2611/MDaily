import React, { useState } from 'react'
import type { Expense } from '../types'
import { FileText, ShoppingBag, Utensils, Car, Trash2, Tag, Sparkles } from 'lucide-react'
import { ExpenseDetailModal } from './ExpenseDetailModal'
import { getCategoryLabel } from '../services/categories'
import type { CategoryItem } from '../services/categories'
import type { SelectOption } from './CustomSelect'
import { formatCurrency, t, getLanguage } from '../services/i18n'
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

const DELETE_ANIMATION_DURATION = 240

export const Dashboard: React.FC<DashboardProps> = ({
  expenses,
  onDelete,
  onUpdate,
  categories,
  categoryOptions
}) => {
  const [selectedExpense, setSelectedExpense] = useState<Expense | null>(null)
  const [deletingExpenseIds, setDeletingExpenseIds] = useState<Set<string>>(new Set())
  const lang = getLanguage()

  const handleDelete = (id: string) => {
    if (deletingExpenseIds.has(id)) return

    setDeletingExpenseIds(previous => new Set(previous).add(id))
    window.setTimeout(() => onDelete(id), DELETE_ANIMATION_DURATION)
  }

  return (
    <div className="dashboard">
      {expenses.length === 0 ? (
        <div className="empty-state">
          <p>{t('no_expenses', lang)}</p>
        </div>
      ) : (
        <div className="expense-grid">
          {expenses.map(expense => (
            <div
              key={expense.id}
              className={`expense-card ${deletingExpenseIds.has(expense.id) ? 'deleting' : ''}`}
              onClick={() => setSelectedExpense(expense)}
            >
              <div className="expense-photo">
                {expense.photo ? (
                  <img src={expense.photo} alt="Chi tiêu" />
                ) : (
                  <div className="expense-photo-placeholder">
                    <FileText size={32} />
                    <span>{lang === 'vi' ? 'Không có hình ảnh' : 'No photo'}</span>
                  </div>
                )}
                {expense.isAiProcessed && (
                  <div className="ai-badge" style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
                    <Sparkles size={11} />
                    <span>{t('ai_badge', lang)}</span>
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
                <h3>{formatCurrency(expense.amount)}</h3>
                {expense.note && expense.note !== 'MDaily AI processed' && <p className="note">{expense.note}</p>}
              </div>
              <button
                className="btn-icon delete-btn"
                onClick={(e) => {
                  e.stopPropagation()
                  if (confirm(t('delete_expense_confirm', lang))) {
                    handleDelete(expense.id)
                  }
                }}
                title={t('delete', lang)}
                disabled={deletingExpenseIds.has(expense.id)}
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
        onDelete={handleDelete}
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
