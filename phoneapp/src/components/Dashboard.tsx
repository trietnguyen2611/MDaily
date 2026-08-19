import React, { useState } from 'react'
import type { Expense } from '../types'
import { Trash2, Sparkles, Receipt } from 'lucide-react'
import { ExpenseDetailModal } from './ExpenseDetailModal'
import { getCategoryLabel } from '../services/categories'
import type { CategoryItem } from '../services/categories'
import type { SelectOption } from './CustomSelect'
import { formatCurrency, t } from '../services/i18n'
import './Dashboard.css'

interface DashboardProps {
  expenses: Expense[]
  onDelete: (id: string) => void
  onUpdate: (updatedExpense: Expense) => void
  categories: CategoryItem[]
  categoryOptions: SelectOption[]
}

const formatCardTime = (dateStr: string) => {
  const d = new Date(dateStr)
  if (isNaN(d.getTime())) return dateStr
  const hours = d.getHours()
  const minutes = String(d.getMinutes()).padStart(2, '0')
  const ampm = hours >= 12 ? 'PM' : 'AM'
  const h = hours % 12 || 12
  return `${h}:${minutes} ${ampm}`
}

export const Dashboard: React.FC<DashboardProps> = ({
  expenses,
  onDelete,
  onUpdate,
  categories,
  categoryOptions
}) => {
  const [selectedExpense, setSelectedExpense] = useState<Expense | null>(null)

  return (
    <div className="dashboard">
      {expenses.length === 0 ? (
        <div className="empty-state">
          <Receipt size={48} />
          <p>{t('no_expenses')}</p>
        </div>
      ) : (
        <div className="expense-masonry-grid">
          {expenses.map(expense => {
            const hasPhoto = !!expense.photo
            const categoryName = getCategoryLabel(categories, expense.category)
            const hasValidNote = !!expense.note && expense.note !== 'MDaily AI processed'
            const timeFormatted = formatCardTime(expense.date)

            if (hasPhoto) {
              return (
                <div
                  key={expense.id}
                  className="journal-card photo-card"
                  onClick={() => setSelectedExpense(expense)}
                >
                  <img src={expense.photo} alt={categoryName} className="journal-card-bg-img" />
                  <div className="journal-card-overlay" />

                  {expense.isAiProcessed && (
                    <div className="journal-ai-badge">
                      <Sparkles size={10} />
                      <span>{t('ai_badge')}</span>
                    </div>
                  )}

                  {/* Top Content: 1. Time -> 2. Category -> 3. Note (smaller below) */}
                  <div className="journal-card-top">
                    <span className="journal-time-pill">{timeFormatted}</span>
                    <h4 className="journal-title-photo">{categoryName}</h4>
                    {hasValidNote && (
                      <p className="journal-note-photo">{expense.note}</p>
                    )}
                  </div>

                  {/* Bottom Content: Amount & Delete Button */}
                  <div className="journal-card-bottom">
                    <div className="journal-amount-pill">
                      <span>{formatCurrency(expense.amount)}</span>
                    </div>

                    <button
                      className="journal-delete-btn on-photo"
                      onClick={(e) => {
                        e.stopPropagation()
                        if (confirm(t('delete_expense_confirm'))) onDelete(expense.id)
                      }}
                      title={t('delete')}
                      aria-label={t('delete')}
                    >
                      <Trash2 size={15} />
                    </button>
                  </div>
                </div>
              )
            }

            return (
              <div
                key={expense.id}
                className="journal-card text-card"
                onClick={() => setSelectedExpense(expense)}
              >
                {/* Top Content: 1. Time -> 2. Category -> 3. Note (smaller below) */}
                <div className="journal-card-top">
                  <div className="journal-text-time-row">
                    <span className="journal-time-text">{timeFormatted}</span>
                  </div>

                  <h4 className="journal-title-text">{categoryName}</h4>

                  {hasValidNote && (
                    <p className="journal-note-desc">{expense.note}</p>
                  )}
                </div>

                {/* Bottom Content: Amount & Delete Button */}
                <div className="journal-card-bottom">
                  <span className="journal-amount-text">{formatCurrency(expense.amount)}</span>

                  <button
                    className="journal-delete-btn on-text"
                    onClick={(e) => {
                      e.stopPropagation()
                      if (confirm(t('delete_expense_confirm'))) onDelete(expense.id)
                    }}
                    title={t('delete')}
                    aria-label={t('delete')}
                  >
                    <Trash2 size={15} />
                  </button>
                </div>
              </div>
            )
          })}
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
