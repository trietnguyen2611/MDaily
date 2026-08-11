import React from 'react';
import { Sparkles, Trash2, Calendar, Store, Tag } from 'lucide-react';

export const ExpenseCard = ({ expense, onDelete }) => {
  return (
    <div className="expense-card-apple">
      <div className="expense-card-image-wrap">
        <img
          src={expense.imageUrl}
          alt={expense.title}
          className="expense-card-image"
          loading="lazy"
        />
        <span className="category-badge">{expense.category}</span>
        {expense.type === 'ai_receipt' && (
          <span className="ai-indicator-badge">
            <Sparkles size={12} />
            <span>AI Receipt</span>
          </span>
        )}
      </div>

      <div className="expense-card-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
          <h4 className="expense-card-title">{expense.title}</h4>
          <button
            onClick={(e) => {
              e.stopPropagation();
              onDelete(expense.id);
            }}
            title="Xóa khoản chi"
            style={{
              background: 'none',
              border: 'none',
              color: 'var(--color-ink-muted-48)',
              cursor: 'pointer',
              padding: '4px'
            }}
          >
            <Trash2 size={16} />
          </button>
        </div>

        <div className="expense-card-meta">
          <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Store size={13} />
            {expense.merchant || 'Cửa hàng'}
          </span>
          <span style={{ display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Calendar size={13} />
            {expense.date}
          </span>
        </div>

        <div className="expense-card-amount">
          {expense.amount.toLocaleString('vi-VN')} đ
        </div>

        {expense.notes && (
          <p style={{ fontSize: '13px', color: 'var(--color-ink-muted-48)', marginTop: '4px', fontStyle: 'italic' }}>
            "{expense.notes}"
          </p>
        )}

        {expense.items && expense.items.length > 0 && (
          <div style={{ marginTop: '8px', paddingTop: '8px', borderTop: '1px stroke var(--color-hairline)', fontSize: '12px', color: 'var(--color-ink-muted-80)' }}>
            <div style={{ fontWeight: 600, marginBottom: '2px' }}>Chi tiết món:</div>
            {expense.items.map((item, idx) => (
              <div key={idx} style={{ display: 'flex', justifyContent: 'space-between', color: 'var(--color-ink-muted-48)' }}>
                <span>• {item.name}</span>
                <span>{item.price ? item.price.toLocaleString('vi-VN') + ' đ' : ''}</span>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
};
