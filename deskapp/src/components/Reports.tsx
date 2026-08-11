import React, { useState } from 'react'
import { FileText, ShoppingBag, Utensils, Car, Tag, Plus, Pencil, Trash2, Check, X } from 'lucide-react'
import type { Expense } from '../types'
import { getCategoryLabel } from '../services/categories'
import type { CategoryItem } from '../services/categories'
import './Reports.css'

interface ReportsProps {
  expenses: Expense[]
  categories: CategoryItem[]
  onAddCategory: (label: string) => void
  onDeleteCategory: (value: string) => void
  onUpdateCategory: (oldValue: string, newLabel: string) => void
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

const COLORS = ['#0a84ff', '#30d158', '#ff9f0a', '#ff453a', '#bf5af2', '#64d2ff', '#ff375f', '#ffd60a', '#ac8e68', '#5e5ce6']

const PieChart: React.FC<{ data: { label: string; value: number; color: string }[] }> = ({ data }) => {
  const total = data.reduce((sum, d) => sum + d.value, 0)
  if (total === 0) return null

  const size = 150
  const center = size / 2
  const radius = 65
  const innerRadius = 42

  let currentAngle = -Math.PI / 2

  const slices = data.map((d, i) => {
    const angle = (d.value / total) * Math.PI * 2

    // If a single slice takes 100%, render a full donut ring to avoid SVG arc collapse
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
          className="pie-slice"
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
        className="pie-slice"
      />
    )
  })

  return (
    <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="pie-svg">
      {slices}
      <text x={center} y={center - 4} textAnchor="middle" className="pie-center-amount">
        {total.toLocaleString('vi-VN')}
      </text>
      <text x={center} y={center + 14} textAnchor="middle" className="pie-center-label">
        VNĐ
      </text>
    </svg>
  )
}

export const Reports: React.FC<ReportsProps> = ({ expenses, categories, onAddCategory, onDeleteCategory, onUpdateCategory }) => {
  const [isAdding, setIsAdding] = useState(false)
  const [newLabel, setNewLabel] = useState('')
  const [editingValue, setEditingValue] = useState<string | null>(null)
  const [editLabel, setEditLabel] = useState('')

  // Category expense totals
  const categoryTotals = expenses.reduce((acc, ex) => {
    acc[ex.category] = (acc[ex.category] || 0) + ex.amount
    return acc
  }, {} as Record<string, number>)

  const total = expenses.reduce((sum, ex) => sum + ex.amount, 0)

  const pieData = categories.map((cat, i) => ({
    label: cat.label,
    value: categoryTotals[cat.value] || 0,
    color: COLORS[i % COLORS.length]
  })).filter(d => d.value > 0)

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
    <div className="categories-page">
      {/* Pie Chart Section */}
      <div className="categories-chart-section">
        <div className="chart-card">
          {pieData.length > 0 ? (
            <>
              <PieChart data={pieData} />
              <div className="chart-legend">
                {pieData.map((d, i) => {
                  const percent = total > 0 ? ((d.value / total) * 100).toFixed(1) : '0'
                  return (
                    <div key={i} className="legend-item">
                      <span className="legend-dot" style={{ backgroundColor: d.color }} />
                      <span className="legend-label">{d.label}</span>
                      <span className="legend-value">{d.value.toLocaleString('vi-VN')} đ</span>
                      <span className="legend-percent">{percent}%</span>
                    </div>
                  )
                })}
              </div>
            </>
          ) : (
            <div className="chart-empty">
              <Tag size={36} />
              <p>Chưa có dữ liệu chi tiêu</p>
            </div>
          )}
        </div>
      </div>

      {/* Category Management Section */}
      <div className="categories-manage-section">
        <div className="manage-header">
          <h3>Quản lý danh mục</h3>
          <button className="btn-add-cat" onClick={() => setIsAdding(true)}>
            <Plus size={16} /> Thêm
          </button>
        </div>

        {isAdding && (
          <div className="category-add-row">
            <input
              type="text"
              value={newLabel}
              onChange={e => setNewLabel(e.target.value)}
              placeholder="Tên danh mục mới..."
              autoFocus
              onKeyDown={e => { if (e.key === 'Enter') handleAdd() }}
            />
            <button className="btn-save-cat" onClick={handleAdd}>
              <Check size={14} />
            </button>
            <button className="btn-cancel-cat" onClick={() => { setIsAdding(false); setNewLabel('') }}>
              <X size={14} />
            </button>
          </div>
        )}

        <div className="category-list-wrapper">
          <div className="category-list">
            {categories.map((cat, index) => {
            const amount = categoryTotals[cat.value] || 0
            const count = expenses.filter(e => e.category === cat.value).length
            const isEditing = editingValue === cat.value

            return (
              <div key={cat.value} className="category-item">
                <div className="category-item-left">
                  <span className="category-icon-circle" style={{ backgroundColor: COLORS[index % COLORS.length] + '22', color: COLORS[index % COLORS.length] }}>
                    <CategoryIcon category={cat.value} />
                  </span>
                  {isEditing ? (
                    <input
                      className="category-edit-input"
                      value={editLabel}
                      onChange={e => setEditLabel(e.target.value)}
                      autoFocus
                      onKeyDown={e => { if (e.key === 'Enter') handleUpdate(cat.value) }}
                    />
                  ) : (
                    <div className="category-item-info">
                      <span className="category-item-name">{cat.label}</span>
                      <span className="category-item-stats">
                        {count > 0 ? `${count} chi tiêu · ${amount.toLocaleString('vi-VN')} đ` : 'Chưa có chi tiêu'}
                      </span>
                    </div>
                  )}
                </div>
                <div className="category-item-actions">
                  {isEditing ? (
                    <>
                      <button className="btn-cat-action save" onClick={() => handleUpdate(cat.value)} title="Lưu">
                        <Check size={14} />
                      </button>
                      <button className="btn-cat-action cancel" onClick={() => { setEditingValue(null); setEditLabel('') }} title="Hủy">
                        <X size={14} />
                      </button>
                    </>
                  ) : (
                    <>
                      <button
                        className="btn-cat-action edit"
                        onClick={() => { setEditingValue(cat.value); setEditLabel(cat.label) }}
                        title="Sửa"
                      >
                        <Pencil size={14} />
                      </button>
                      <button
                        className="btn-cat-action delete"
                        onClick={() => {
                          if (count > 0) {
                            if (confirm(`Danh mục "${cat.label}" đang có ${count} chi tiêu. Bạn vẫn muốn xoá?`)) {
                              onDeleteCategory(cat.value)
                            }
                          } else {
                            onDeleteCategory(cat.value)
                          }
                        }}
                        title="Xoá"
                      >
                        <Trash2 size={14} />
                      </button>
                    </>
                  )}
                </div>
              </div>
            )
          })}
          </div>
        </div>
      </div>
    </div>
  )
}
