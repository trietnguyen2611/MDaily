import React from 'react'
import { PieChart } from 'lucide-react'
import type { Expense } from '../types'
import './Reports.css'

interface ReportsProps {
  expenses: Expense[]
}

const CategoryLabel = (category: string) => {
  switch (category) {
    case 'bills': return 'Hoá đơn'
    case 'shopping': return 'Mua sắm'
    case 'food': return 'Ăn uống'
    case 'transport': return 'Di chuyển'
    default: return 'Khác'
  }
}

export const Reports: React.FC<ReportsProps> = ({ expenses }) => {
  const total = expenses.reduce((sum, ex) => sum + ex.amount, 0)

  // Group by category
  const categoryTotals = expenses.reduce((acc, ex) => {
    acc[ex.category] = (acc[ex.category] || 0) + ex.amount
    return acc
  }, {} as Record<string, number>)

  const sortedCategories = Object.entries(categoryTotals).sort((a, b) => b[1] - a[1])

  const colors = ['#0066cc', '#34c759', '#ff9500', '#ff3b30', '#af52de', '#5ac8fa']

  return (
    <div className="reports-container">
      <h2>Báo cáo chi tiêu</h2>

      <div className="reports-summary-card">
        <span className="reports-label">Tổng chi tiêu</span>
        <span className="reports-total">{total.toLocaleString('vi-VN')} đ</span>
      </div>

      {sortedCategories.length === 0 ? (
        <div className="reports-empty">
          <PieChart size={48} />
          <p>Chưa có dữ liệu để báo cáo.</p>
        </div>
      ) : (
        <div className="reports-breakdown">
          <h3>Theo danh mục</h3>
          <div className="reports-bars">
            {sortedCategories.map(([cat, amount], index) => {
              const percent = total > 0 ? (amount / total) * 100 : 0
              return (
                <div key={cat} className="reports-bar-item">
                  <div className="reports-bar-label">
                    <span>{CategoryLabel(cat)}</span>
                    <span>{amount.toLocaleString('vi-VN')} đ ({percent.toFixed(1)}%)</span>
                  </div>
                  <div className="reports-bar-track">
                    <div 
                      className="reports-bar-fill" 
                      style={{ 
                        width: `${percent}%`, 
                        backgroundColor: colors[index % colors.length] 
                      }} 
                    />
                  </div>
                </div>
              )
            })}
          </div>
        </div>
      )}
    </div>
  )
}
