import React, { useState } from 'react'
import { FileText, ShoppingBag, Utensils, Car, Tag, Plus, Pencil, Trash2, Check, X, PieChart as PieIcon } from 'lucide-react'
import type { Expense } from '../types'
import type { CategoryItem } from '../services/categories'
import './Reports.css'

interface ReportsProps {
  expenses: Expense[]
  categories: CategoryItem[]
  onAddCategory: (label: string) => void
  onDeleteCategory: (value: string) => void
  onUpdateCategory: (oldValue: string, newLabel: string) => void
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

const COLORS = [
  '#007aff', '#34c759', '#ff9500', '#ff3b30', '#af52de',
  '#5ac8fa', '#ff2d55', '#ffcc00', '#a2845e', '#5856d6'
]

const DonutChart: React.FC<{ data: { label: string; value: number; color: string }[] }> = ({ data }) => {
  const total = data.reduce((sum, d) => sum + d.value, 0)
  if (total === 0) return null

  const size = 160
  const center = size / 2
  const radius = 68
  const innerRadius = 46

  let currentAngle = -Math.PI / 2

  const slices = data.map((d, i) => {
    const angle = (d.value / total) * Math.PI * 2

    if (data.length === 1 || angle >= Math.PI * 1.999) {
      return (
        <path
          key={i}
          d={`M ${center} ${center - radius}
             A ${radius} ${radius} 0 1 1 ${center} ${center + radius}
             A ${radius} ${radius} 0 1 1 ${center} ${center - radius}
             M ${center} ${center - innerRadius}
             A ${innerRadius} ${innerRadius} 0 1 0 ${center} ${center + innerRadius}
             A ${innerRadius} ${innerRadius} 0 1 0 ${center} ${center - innerRadius} Z`}
          fill={d.color}
          className="donut-slice"
        />
      )
    }

    const startAngle = currentAngle
    const endAngle = currentAngle + angle
    currentAngle = endAngle

    const largeArc = angle > Math.PI ? 1 : 0

    const x1 = center + radius * Math.cos(startAngle)
    const y1 = center + radius * Math.sin(startAngle)
    const x2 = center + radius * Math.cos(endAngle)
    const y2 = center + radius * Math.sin(endAngle)

    const ix1 = center + innerRadius * Math.cos(endAngle)
    const iy1 = center + innerRadius * Math.sin(endAngle)
    const ix2 = center + innerRadius * Math.cos(startAngle)
    const iy2 = center + innerRadius * Math.sin(startAngle)

    const path = [
      `M ${x1} ${y1}`,
      `A ${radius} ${radius} 0 ${largeArc} 1 ${x2} ${y2}`,
      `L ${ix1} ${iy1}`,
      `A ${innerRadius} ${innerRadius} 0 ${largeArc} 0 ${ix2} ${iy2}`,
      `Z`
    ].join(' ')

    return (
      <path
        key={i}
        d={path}
        fill={d.color}
        className="donut-slice"
      />
    )
  })

  return (
    <div className="donut-chart-wrapper">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="donut-svg">
        {slices}
      </svg>
      <div className="donut-center-info">
        <span className="donut-center-amount">{total.toLocaleString('vi-VN')}</span>
        <span className="donut-center-currency">VNĐ</span>
      </div>
    </div>
  )
}

export const Reports: React.FC<ReportsProps> = ({
  expenses,
  categories,
  onAddCategory,
  onDeleteCategory,
  onUpdateCategory
}) => {
  const [isAdding, setIsAdding] = useState(false)
  const [newLabel, setNewLabel] = useState('')
  const [editingValue, setEditingValue] = useState<string | null>(null)
  const [editLabel, setEditLabel] = useState('')

  // Calculate totals per category
  const categoryTotals = expenses.reduce((acc, ex) => {
    acc[ex.category] = (acc[ex.category] || 0) + ex.amount
    return acc
  }, {} as Record<string, number>)

  const total = expenses.reduce((sum, ex) => sum + ex.amount, 0)

  // Chart data sorted by amount
  const chartData = categories
    .map((cat, i) => ({
      value: cat.value,
      label: cat.label,
      amount: categoryTotals[cat.value] || 0,
      color: COLORS[i % COLORS.length]
    }))
    .filter(d => d.amount > 0)
    .sort((a, b) => b.amount - a.amount)

  const handleAdd = () => {
    if (newLabel.trim()) {
      onAddCategory(newLabel.trim())
      setNewLabel('')
      setIsAdding(false)
    }
  }

  const handleUpdate = (oldValue: string) => {
    if (editLabel.trim()) {
      onUpdateCategory(oldValue, editLabel.trim())
      setEditingValue(null)
      setEditLabel('')
    }
  }

  return (
    <div className="reports-container">
      {/* 1. Overview Donut Chart Card */}
      <div className="reports-card chart-overview-card">
        {chartData.length > 0 ? (
          <div className="chart-content-row">
            <DonutChart data={chartData.map(d => ({ label: d.label, value: d.amount, color: d.color }))} />
            <div className="chart-quick-stats">
              <span className="quick-stats-title">Tổng phân bổ</span>
              <span className="quick-stats-total">{total.toLocaleString('vi-VN')} đ</span>
              <span className="quick-stats-count">{expenses.length} khoản chi · {chartData.length} danh mục</span>
            </div>
          </div>
        ) : (
          <div className="chart-empty-state">
            <PieIcon size={42} className="chart-empty-icon" />
            <p>Chưa có dữ liệu chi tiêu trong khoảng thời gian này</p>
          </div>
        )}
      </div>

      {/* 2. Vertical Category Breakdown List with Progress Bars */}
      <div className="reports-section-header">
        <h3>Chi tiết theo danh mục</h3>
        <button
          className="btn-add-category-pill"
          onClick={() => setIsAdding(true)}
        >
          <Plus size={14} /> Thêm danh mục
        </button>
      </div>

      {isAdding && (
        <div className="add-category-inline-card">
          <input
            type="text"
            value={newLabel}
            onChange={e => setNewLabel(e.target.value)}
            placeholder="Nhập tên danh mục mới..."
            autoFocus
            onKeyDown={e => { if (e.key === 'Enter') handleAdd() }}
          />
          <div className="add-cat-actions">
            <button className="btn-cat-save" onClick={handleAdd} title="Lưu danh mục">
              <Check size={16} />
            </button>
            <button className="btn-cat-cancel" onClick={() => { setIsAdding(false); setNewLabel('') }} title="Huỷ">
              <X size={16} />
            </button>
          </div>
        </div>
      )}

      {/* Vertical list of category cards — no horizontal scroll needed! */}
      <div className="category-breakdown-list">
        {categories.map((cat, index) => {
          const amount = categoryTotals[cat.value] || 0
          const count = expenses.filter(e => e.category === cat.value).length
          const percent = total > 0 ? (amount / total) * 100 : 0
          const isEditing = editingValue === cat.value
          const color = COLORS[index % COLORS.length]

          return (
            <div key={cat.value} className="category-breakdown-card">
              <div className="cat-card-top-row">
                <div className="cat-card-left">
                  <div className="cat-icon-badge" style={{ backgroundColor: `${color}18`, color: color }}>
                    <CategoryIcon category={cat.value} size={18} />
                  </div>

                  {isEditing ? (
                    <input
                      className="cat-inline-edit-input"
                      value={editLabel}
                      onChange={e => setEditLabel(e.target.value)}
                      autoFocus
                      onKeyDown={e => { if (e.key === 'Enter') handleUpdate(cat.value) }}
                    />
                  ) : (
                    <div className="cat-meta-info">
                      <span className="cat-title">{cat.label}</span>
                      <span className="cat-sub-stats">{count} giao dịch</span>
                    </div>
                  )}
                </div>

                <div className="cat-card-right">
                  {isEditing ? (
                    <div className="cat-edit-btn-group">
                      <button className="btn-cat-save" onClick={() => handleUpdate(cat.value)}>
                        <Check size={14} />
                      </button>
                      <button className="btn-cat-cancel" onClick={() => { setEditingValue(null); setEditLabel('') }}>
                        <X size={14} />
                      </button>
                    </div>
                  ) : (
                    <div className="cat-amount-badge-group">
                      <div className="cat-amount-col">
                        <span className="cat-amount-val">{amount.toLocaleString('vi-VN')} đ</span>
                        <span className="cat-percent-val">{percent.toFixed(1)}%</span>
                      </div>

                      <div className="cat-actions-trigger">
                        <button
                          className="btn-cat-mini edit"
                          onClick={() => { setEditingValue(cat.value); setEditLabel(cat.label) }}
                          title="Sửa tên"
                        >
                          <Pencil size={13} />
                        </button>
                        <button
                          className="btn-cat-mini delete"
                          onClick={() => {
                            if (count > 0) {
                              if (confirm(`Danh mục "${cat.label}" có ${count} chi tiêu. Bạn chắc chắn muốn xoá?`)) {
                                onDeleteCategory(cat.value)
                              }
                            } else {
                              onDeleteCategory(cat.value)
                            }
                          }}
                          title="Xoá danh mục"
                        >
                          <Trash2 size={13} />
                        </button>
                      </div>
                    </div>
                  )}
                </div>
              </div>

              {/* Smooth Progress Bar */}
              <div className="cat-progress-track">
                <div
                  className="cat-progress-bar"
                  style={{
                    width: `${Math.min(100, Math.max(percent, amount > 0 ? 3 : 0))}%`,
                    backgroundColor: color
                  }}
                />
              </div>
            </div>
          )
        })}
      </div>
    </div>
  )
}
