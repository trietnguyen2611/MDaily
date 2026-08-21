import React, { useState } from 'react'
import { FileText, ShoppingBag, Utensils, Car, Tag, Plus, Pencil, Trash2, Check, X, PieChart as PieIcon } from 'lucide-react'
import type { Expense } from '../types'
import type { CategoryItem } from '../services/categories'
import { formatCurrency, getCurrencySymbol, t, getLanguage } from '../services/i18n'
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
  '#0a84ff', '#30d158', '#ff9f0a', '#ff453a', '#bf5af2',
  '#64d2ff', '#ff375f', '#ffd60a', '#ac8e68', '#5e5ce6'
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

  const currSymbol = getCurrencySymbol()

  return (
    <div className="donut-chart-wrapper">
      <svg width={size} height={size} viewBox={`0 0 ${size} ${size}`} className="donut-svg">
        {slices}
      </svg>
      <div className="donut-center-info">
        <span className="donut-center-amount">{total.toLocaleString('en-US')}</span>
        <span className="donut-center-currency">{currSymbol}</span>
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
  const lang = getLanguage()

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
    <div className="categories-page">
      {/* 1. Overview Donut Chart Card */}
      <div className="categories-chart-section">
        <div className="chart-card">
          {chartData.length > 0 ? (
            <div className="chart-content-row">
              <DonutChart data={chartData.map(d => ({ label: d.label, value: d.amount, color: d.color }))} />
              <div className="chart-quick-stats">
                <span className="quick-stats-title">{t('chart_overview', lang)}</span>
                <span className="quick-stats-total">{formatCurrency(total)}</span>
                <span className="quick-stats-count">{expenses.length} {t('transactions', lang)} · {chartData.length} {t('categories_count', lang)}</span>
              </div>
            </div>
          ) : (
            <div className="chart-empty">
              <PieIcon size={36} />
              <p>{t('no_data_period', lang)}</p>
            </div>
          )}
        </div>
      </div>

      {/* 2. Category Management Section */}
      <div className="categories-manage-section">
        <div className="manage-header">
          <h3>{t('category_breakdown', lang)}</h3>
          {!isAdding && (
            <button className="btn-add-cat" onClick={() => setIsAdding(true)}>
              <Plus size={16} /> {t('add_category', lang)}
            </button>
          )}
        </div>

        {isAdding && (
          <div className="category-add-row">
            <input
              type="text"
              value={newLabel}
              onChange={e => setNewLabel(e.target.value)}
              placeholder={t('cat_placeholder', lang)}
              autoFocus
              onKeyDown={e => {
                if (e.key === 'Enter') handleAdd()
                if (e.key === 'Escape') { setIsAdding(false); setNewLabel('') }
              }}
            />
            <button className="btn-save-cat" onClick={handleAdd} title={t('save', lang)}>
              <Check size={14} />
            </button>
            <button className="btn-cancel-cat" onClick={() => { setIsAdding(false); setNewLabel('') }} title={t('cancel', lang)}>
              <X size={14} />
            </button>
          </div>
        )}

        <div className="category-list-wrapper">
          <div className="category-list">
            {categories.map((cat, index) => {
              const amount = categoryTotals[cat.value] || 0
              const count = expenses.filter(e => e.category === cat.value).length
              const percent = total > 0 ? (amount / total) * 100 : 0
              const isEditing = editingValue === cat.value
              const color = COLORS[index % COLORS.length]

              return (
                <div key={cat.value} className="category-item">
                  <div className="category-item-left">
                    <span className="category-icon-circle" style={{ backgroundColor: color + '22', color }}>
                      <CategoryIcon category={cat.value} />
                    </span>
                    {isEditing ? (
                      <input
                        className="category-edit-input"
                        value={editLabel}
                        onChange={e => setEditLabel(e.target.value)}
                        autoFocus
                        onKeyDown={e => {
                          if (e.key === 'Enter') handleUpdate(cat.value)
                          if (e.key === 'Escape') { setEditingValue(null); setEditLabel('') }
                        }}
                      />
                    ) : (
                      <div className="category-item-info">
                        <span className="category-item-name">{cat.label}</span>
                        <span className="category-item-stats">
                          {count > 0 ? `${count} ${t('transactions', lang)} · ${formatCurrency(amount)} (${percent.toFixed(1)}%)` : 'Chưa có chi tiêu'}
                        </span>
                      </div>
                    )}
                  </div>
                  <div className="category-item-actions">
                    {isEditing ? (
                      <>
                        <button className="btn-cat-action save" onClick={() => handleUpdate(cat.value)} title={t('save', lang)}>
                          <Check size={14} />
                        </button>
                        <button className="btn-cat-action cancel" onClick={() => { setEditingValue(null); setEditLabel('') }} title={t('cancel', lang)}>
                          <X size={14} />
                        </button>
                      </>
                    ) : (
                      <>
                        <button
                          className="btn-cat-action edit"
                          onClick={() => { setEditingValue(cat.value); setEditLabel(cat.label) }}
                          title={t('edit', lang)}
                        >
                          <Pencil size={14} />
                        </button>
                        <button
                          className="btn-cat-action delete"
                          onClick={() => {
                            if (count > 0) {
                              if (confirm(`${t('delete_category_confirm', lang)} (${cat.label} - ${count} ${t('transactions', lang)})`)) {
                                onDeleteCategory(cat.value)
                              }
                            } else {
                              onDeleteCategory(cat.value)
                            }
                          }}
                          title={t('delete', lang)}
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
