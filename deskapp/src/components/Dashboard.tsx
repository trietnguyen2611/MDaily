import React from 'react'
import type { Expense } from '../types'
import { FileText, ShoppingBag, Utensils, Car, Trash2 } from 'lucide-react'
import './Dashboard.css'

interface DashboardProps {
  expenses: Expense[]
  onDelete: (id: string) => void
}

const CategoryIcon = ({ category }: { category: string }) => {
  switch (category) {
    case 'bills': return <FileText size={20} />
    case 'shopping': return <ShoppingBag size={20} />
    case 'food': return <Utensils size={20} />
    case 'transport': return <Car size={20} />
    default: return <FileText size={20} />
  }
}

const CategoryLabel = ({ category }: { category: string }) => {
  switch (category) {
    case 'bills': return 'Hoá đơn'
    case 'shopping': return 'Mua sắm'
    case 'food': return 'Ăn uống'
    case 'transport': return 'Di chuyển'
    default: return 'Khác'
  }
}

export const Dashboard: React.FC<DashboardProps> = ({ expenses, onDelete }) => {
  return (
    <div className="dashboard">

      {expenses.length === 0 ? (
        <div className="empty-state">
          <p>Chưa có chi tiêu nào. Bấm "Thêm chi tiêu" để thêm mới.</p>
        </div>
      ) : (
        <div className="expense-grid">
          {expenses.map(expense => (
            <div key={expense.id} className="expense-card">
              <div className="expense-photo">
                <img src={expense.photo} alt="Chi tiêu" />
                {expense.isAiProcessed && (
                  <div className="ai-badge">MDaily AI</div>
                )}
              </div>
              <div className="expense-info">
                <div className="expense-meta">
                  <span className="category">
                    <CategoryIcon category={expense.category} />
                    <CategoryLabel category={expense.category} />
                  </span>
                  <span className="date">{new Date(expense.date).toLocaleDateString()}</span>
                </div>
                <h3>{expense.amount.toLocaleString('vi-VN')} đ</h3>
                {expense.note && expense.note !== 'MDaily AI processed' && <p className="note">{expense.note}</p>}
              </div>
              <button 
                className="btn-icon delete-btn" 
                onClick={() => {
                  if (confirm('Bạn có chắc muốn xoá chi tiêu này?')) {
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
    </div>
  )
}
