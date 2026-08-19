import React, { useState, useEffect } from 'react'
import type { Expense } from '../types'
import { FileText, ShoppingBag, Utensils, Car, Trash2, Calendar, Tag, Pencil, X, Maximize2 } from 'lucide-react'
import { CustomSelect } from './CustomSelect'
import type { SelectOption } from './CustomSelect'
import { getCategoryLabel } from '../services/categories'
import type { CategoryItem } from '../services/categories'
import { getCurrencySymbol, t } from '../services/i18n'
import { BottomSheet } from './BottomSheet'
import './ExpenseDetailModal.css'

interface ExpenseDetailModalProps {
  expense: Expense | null
  onClose: () => void
  onDelete: (id: string) => void
  onUpdate: (updatedExpense: Expense) => void
  categories: CategoryItem[]
  categoryOptions: SelectOption[]
}

const CategoryIcon = ({ category, size = 18 }: { category: string; size?: number }) => {
  switch (category) {
    case 'bills': return <FileText size={size} />
    case 'shopping': return <ShoppingBag size={size} />
    case 'food': return <Utensils size={size} />
    case 'transport': return <Car size={size} />
    default: return <Tag size={size} />
  }
}

const formatDateWithTime = (dateStr: string) => {
  const d = new Date(dateStr)
  if (isNaN(d.getTime())) return dateStr
  const day = String(d.getDate()).padStart(2, '0')
  const month = String(d.getMonth() + 1).padStart(2, '0')
  const year = d.getFullYear()
  const hours = String(d.getHours()).padStart(2, '0')
  const minutes = String(d.getMinutes()).padStart(2, '0')
  return `${day}/${month}/${year} · ${hours}:${minutes}`
}

const formatAmountInput = (val: string) => {
  const clean = val.replace(/\D/g, '')
  if (!clean) return ''
  return parseInt(clean, 10).toLocaleString('en-US')
}

export const ExpenseDetailModal: React.FC<ExpenseDetailModalProps> = ({
  expense,
  onClose,
  onDelete,
  onUpdate,
  categories,
  categoryOptions
}) => {
  const [isEditing, setIsEditing] = useState(false)
  const [amount, setAmount] = useState('')
  const [category, setCategory] = useState('')
  const [note, setNote] = useState('')
  const [isFullscreenImage, setIsFullscreenImage] = useState(false)

  useEffect(() => {
    if (expense) {
      setAmount(expense.amount.toLocaleString('en-US'))
      setCategory(expense.category)
      setNote(expense.note || '')
      setIsEditing(false)
      setIsFullscreenImage(false)
    }
  }, [expense])

  const handleSaveEdit = () => {
    if (!expense) return
    const rawNumeric = parseFloat(amount.replace(/,/g, ''))
    if (isNaN(rawNumeric) || rawNumeric <= 0) {
      alert(t('amount_invalid'))
      return
    }

    const updated: Expense = {
      ...expense,
      amount: rawNumeric,
      category: category as any,
      note: note.trim()
    }

    onUpdate(updated)
    setIsEditing(false)
  }

  const handleCancelEdit = () => {
    if (expense) {
      setAmount(expense.amount.toLocaleString('en-US'))
      setCategory(expense.category)
      setNote(expense.note || '')
    }
    setIsEditing(false)
  }

  const handleDelete = () => {
    if (!expense) return
    if (confirm(t('delete_expense_confirm'))) {
      onDelete(expense.id)
      onClose()
    }
  }

  const formattedDate = expense ? formatDateWithTime(expense.date) : ''
  const currSymbol = getCurrencySymbol()

  return (
    <BottomSheet isOpen={!!expense} onClose={onClose}>
      {expense && (
        <div className="expense-sheet-content">
          {/* iOS Modal Navigation Bar */}
          <div className="ios-sheet-navbar">
            {isEditing ? (
              <button className="ios-nav-btn cancel" onClick={handleCancelEdit}>
                {t('cancel')}
              </button>
            ) : (
              <button className="ios-nav-btn close" onClick={onClose}>
                <X size={18} />
              </button>
            )}

            <span className="ios-nav-title">
              {isEditing ? t('edit_expense') : t('expense_details')}
            </span>

            {isEditing ? (
              <button className="ios-nav-btn done" onClick={handleSaveEdit}>
                {t('done')}
              </button>
            ) : (
              <button className="ios-nav-btn edit" onClick={() => setIsEditing(true)}>
                <Pencil size={15} /> {t('edit')}
              </button>
            )}
          </div>

          <div className="modal-scroll-body">
            {/* Full-Height Expense Photo Container with Ambient Blur */}
            {expense.photo && (
              <div
                className="modal-image-hero"
                onClick={() => setIsFullscreenImage(!isFullscreenImage)}
                title={t('expand_photo')}
              >
                {/* Ambient Blurred Background */}
                <img
                  src={expense.photo}
                  alt=""
                  aria-hidden="true"
                  className="modal-image-ambient"
                />

                {/* Sharp Full Uncropped Foreground Image */}
                <img
                  src={expense.photo}
                  alt={t('expense_details')}
                  className="modal-image-main"
                />

                <div className="image-expand-hint">
                  <Maximize2 size={14} />
                  <span>{t('expand_photo')}</span>
                </div>
              </div>
            )}

            <div className="modal-content-stack">
              {/* Large Amount Hero Header */}
              <div className="modal-amount-hero">
                <span className="amount-hero-label">{t('expense_amount')}</span>
                {isEditing ? (
                  <div className="amount-edit-row">
                    <input
                      type="text"
                      className="amount-edit-input"
                      value={amount}
                      onChange={e => setAmount(formatAmountInput(e.target.value))}
                      placeholder="0"
                      autoFocus
                    />
                    <span className="amount-hero-currency">{currSymbol}</span>
                  </div>
                ) : (
                  <div className="amount-display-row">
                    <h2 className="amount-display-val">{expense.amount.toLocaleString('en-US')}</h2>
                    <span className="amount-hero-currency">{currSymbol}</span>
                  </div>
                )}
              </div>

              {/* iOS Inset Grouped List Form */}
              <div className="ios-grouped-section">
                <div className="ios-grouped-card">
                  {/* Category Field */}
                  <div className="ios-form-row">
                    <div className="ios-row-lead">
                      <div className="ios-icon-badge category-badge-icon">
                        <Tag size={16} />
                      </div>
                      <span className="ios-row-label">{t('category_label')}</span>
                    </div>

                    <div className="ios-row-trail">
                      {isEditing ? (
                        <div className="ios-row-select-wrap">
                          <CustomSelect
                            options={categoryOptions}
                            value={category}
                            onChange={setCategory}
                          />
                        </div>
                      ) : (
                        <div className="ios-pill-badge">
                          <CategoryIcon category={expense.category} size={15} />
                          <span>{getCategoryLabel(categories, expense.category)}</span>
                        </div>
                      )}
                    </div>
                  </div>

                  {/* Date / Time Field */}
                  <div className="ios-form-row">
                    <div className="ios-row-lead">
                      <div className="ios-icon-badge date-badge-icon">
                        <Calendar size={16} />
                      </div>
                      <span className="ios-row-label">{t('time')}</span>
                    </div>

                    <div className="ios-row-trail">
                      <span className="ios-row-value-text">{formattedDate}</span>
                    </div>
                  </div>

                  {/* Note Field */}
                  <div className="ios-form-row note-row">
                    <div className="ios-row-lead">
                      <div className="ios-icon-badge note-badge-icon">
                        <FileText size={16} />
                      </div>
                      <span className="ios-row-label">{t('note')}</span>
                    </div>

                    <div className="ios-row-trail note-trail">
                      {isEditing ? (
                        <input
                          type="text"
                          className="ios-inline-text-input"
                          value={note}
                          onChange={e => setNote(e.target.value)}
                          placeholder={t('note_placeholder')}
                        />
                      ) : (
                        <span className="ios-row-value-text note-text">
                          {expense.note && expense.note !== 'MDaily AI processed' ? expense.note : t('no_note')}
                        </span>
                      )}
                    </div>
                  </div>
                </div>
              </div>

              {/* Danger Zone: Delete Button Group */}
              <div className="ios-grouped-section danger-section">
                <button
                  type="button"
                  className="ios-delete-row-btn"
                  onClick={handleDelete}
                >
                  <Trash2 size={18} />
                  <span>{t('delete_this_expense')}</span>
                </button>
              </div>
            </div>
          </div>

          {/* Fullscreen Lightbox Modal when tapped */}
          {isFullscreenImage && expense.photo && (
            <div
              className="fullscreen-image-lightbox"
              onClick={() => setIsFullscreenImage(false)}
            >
              <button
                type="button"
                className="btn-close-lightbox"
                onClick={() => setIsFullscreenImage(false)}
              >
                <X size={22} />
              </button>
              <img
                src={expense.photo}
                alt="Full photo"
                className="lightbox-full-img"
              />
            </div>
          )}
        </div>
      )}
    </BottomSheet>
  )
}
