import React, { useState, useEffect } from 'react'
import { createPortal } from 'react-dom'
import type { Expense } from '../types'
import { FileText, ShoppingBag, Utensils, Car, X, Trash2, Calendar, Tag, Pencil, Check, RotateCcw } from 'lucide-react'
import { CustomSelect } from './CustomSelect'
import type { SelectOption } from './CustomSelect'
import { getCategoryLabel } from '../services/categories'
import type { CategoryItem } from '../services/categories'
import './ExpenseDetailModal.css'

interface ExpenseDetailModalProps {
  expense: Expense | null
  onClose: () => void
  onDelete: (id: string) => void
  onUpdate: (updatedExpense: Expense) => void
  categories: CategoryItem[]
  categoryOptions: SelectOption[]
}

const CategoryIcon = ({ category }: { category: string }) => {
  switch (category) {
    case 'bills': return <FileText size={18} />
    case 'shopping': return <ShoppingBag size={18} />
    case 'food': return <Utensils size={18} />
    case 'transport': return <Car size={18} />
    default: return <Tag size={18} />
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
  return `${day}/${month}/${year} - ${hours}:${minutes}`
}

const formatAmountInput = (val: string) => {
  const clean = val.replace(/\D/g, '')
  if (!clean) return ''
  return parseInt(clean, 10).toLocaleString('en-US')
}

export const ExpenseDetailModal: React.FC<ExpenseDetailModalProps> = ({ expense, onClose, onDelete, onUpdate, categories, categoryOptions }) => {
  if (!expense) return null

  const [isEditing, setIsEditing] = useState(false)
  const [amount, setAmount] = useState('')
  const [category, setCategory] = useState('')
  const [note, setNote] = useState('')
  const [isClosing, setIsClosing] = useState(false)

  useEffect(() => {
    if (expense) {
      setAmount(expense.amount.toLocaleString('en-US'))
      setCategory(expense.category)
      setNote(expense.note || '')
      setIsEditing(false)
      setIsClosing(false)
    }
  }, [expense])

  const handleClose = () => {
    setIsClosing(true)
    setTimeout(() => {
      onClose()
    }, 200)
  }

  const handleSaveEdit = () => {
    const rawNumeric = parseFloat(amount.replace(/,/g, ''))
    if (isNaN(rawNumeric) || rawNumeric <= 0) {
      alert('Hãy nhập số tiền hợp lệ!')
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

  const formattedDate = formatDateWithTime(expense.date)

  return createPortal(
    <div className={`expense-modal-overlay ${isClosing ? 'closing' : ''}`} onClick={handleClose}>
      <div className={`expense-modal-content ${isClosing ? 'closing' : ''}`} onClick={e => e.stopPropagation()}>
        <button className="modal-close-btn" onClick={handleClose} title="Đóng">
          <X size={20} />
        </button>

        <div className="modal-body">
          <div className="modal-image-container">
            <img src={expense.photo} alt="Hoá đơn / Ảnh chi tiêu" />
          </div>

          <div className="modal-details">
            {!isEditing ? (
              <>
                <div className="modal-amount-section">
                  <span className="modal-amount-label">Số tiền chi tiêu</span>
                  <h2 className="modal-amount-value">{expense.amount.toLocaleString('vi-VN')} đ</h2>
                </div>

                <div className="modal-info-group">
                  <div className="modal-info-row">
                    <span className="info-row-label">
                      <Tag size={16} /> Danh mục
                    </span>
                    <span className="info-row-value category-badge">
                      <CategoryIcon category={expense.category} />
                      {getCategoryLabel(categories, expense.category)}
                    </span>
                  </div>

                  <div className="modal-info-row">
                    <span className="info-row-label">
                      <Calendar size={16} /> Thời gian
                    </span>
                    <span className="info-row-value date-text">{formattedDate}</span>
                  </div>

                  {expense.note && expense.note !== 'MDaily AI processed' && (
                    <div className="modal-note-section">
                      <span className="info-row-label">Ghi chú</span>
                      <p className="modal-note-text">{expense.note}</p>
                    </div>
                  )}
                </div>

                <div className="modal-actions-row">
                  <button
                    className="btn-modal-edit"
                    onClick={() => setIsEditing(true)}
                  >
                    <Pencil size={16} /> Chỉnh sửa
                  </button>

                  <button
                    className="btn-modal-delete"
                    onClick={() => {
                      if (confirm('Xoá chi tiêu này?')) {
                        onDelete(expense.id)
                        handleClose()
                      }
                    }}
                  >
                    <Trash2 size={16} /> Xoá
                  </button>
                </div>
              </>
            ) : (
              <div className="modal-edit-form">
                <h3 className="edit-form-title">Chỉnh sửa chi tiêu</h3>

                <div className="modal-form-group">
                  <label>Số tiền (VNĐ)</label>
                  <input
                    type="text"
                    value={amount}
                    onChange={e => setAmount(formatAmountInput(e.target.value))}
                    placeholder="Nhập số tiền..."
                  />
                </div>

                <div className="modal-form-group">
                  <label>Danh mục</label>
                  <CustomSelect
                    options={categoryOptions}
                    value={category}
                    onChange={setCategory}
                  />
                </div>

                <div className="modal-form-group">
                  <label>Ghi chú</label>
                  <input
                    type="text"
                    value={note}
                    onChange={e => setNote(e.target.value)}
                    placeholder="Nhập ghi chú..."
                  />
                </div>

                <div className="modal-actions-row">
                  <button
                    className="btn-modal-save"
                    onClick={handleSaveEdit}
                  >
                    <Check size={16} /> Lưu thay đổi
                  </button>

                  <button
                    className="btn-modal-cancel"
                    onClick={() => setIsEditing(false)}
                  >
                    <RotateCcw size={16} /> Hủy
                  </button>
                </div>
              </div>
            )}
          </div>
        </div>
      </div>
    </div>,
    document.body
  )
}
