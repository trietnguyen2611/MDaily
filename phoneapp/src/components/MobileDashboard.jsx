import React, { useState } from 'react';
import { Sparkles, Camera, Trash2, Store, Calendar, Search, RefreshCw, ShoppingBag } from 'lucide-react';

export const MobileDashboard = ({
  expenses,
  currentUser,
  activeCategory,
  onSelectCategory,
  onDeleteExpense,
  onOpenReceiptSheet,
  onOpenObjectSheet,
  onResetData
}) => {
  const [searchQuery, setSearchQuery] = useState('');

  const filtered = expenses.filter(item => {
    const matchCat = activeCategory === 'ALL' || item.category === activeCategory;
    const matchSearch = searchQuery === '' ||
      item.title.toLowerCase().includes(searchQuery.toLowerCase()) ||
      (item.merchant && item.merchant.toLowerCase().includes(searchQuery.toLowerCase()));
    return matchCat && matchSearch;
  });

  const totalSpent = expenses.reduce((sum, item) => sum + item.amount, 0);
  const aiCount = expenses.filter(i => i.type === 'ai_receipt').length;

  return (
    <div className="ios-scroll-content">
      {/* iOS Spending Total Card */}
      <div className="ios-card" style={{ background: 'linear-gradient(135deg, #0066cc 0%, #004499 100%)', color: '#ffffff', borderRadius: '24px', padding: '20px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <span style={{ fontSize: '13px', opacity: 0.8, textTransform: 'uppercase', letterSpacing: '0.5px' }}>TỔNG CHI TIÊU</span>
          <span style={{ fontSize: '11px', background: 'rgba(255,255,255,0.2)', padding: '3px 10px', borderRadius: '99px' }}>
             Sync Active
          </span>
        </div>
        <div style={{ fontFamily: 'var(--font-display)', fontSize: '32px', fontWeight: 700, margin: '8px 0 12px 0' }}>
          {totalSpent.toLocaleString('vi-VN')} đ
        </div>
        <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '13px', opacity: 0.9, paddingTop: '10px', borderTop: '1px solid rgba(255,255,255,0.2)' }}>
          <span>{expenses.length} khoản chi</span>
          <span>{aiCount} hóa đơn *AI</span>
        </div>
      </div>

      {/* Quick Action Buttons */}
      <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
        <button
          onClick={onOpenReceiptSheet}
          style={{
            background: 'var(--color-canvas)',
            border: '1px solid var(--color-hairline)',
            borderRadius: '18px',
            padding: '14px',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            cursor: 'pointer',
            boxShadow: '0 2px 8px rgba(0,0,0,0.04)'
          }}
        >
          <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'rgba(0,102,204,0.1)', color: 'var(--color-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Sparkles size={18} />
          </div>
          <div style={{ textAlign: 'left' }}>
            <div style={{ fontWeight: 600, fontSize: '14px', color: 'var(--color-ink)' }}>Quét Hóa Đơn</div>
            <div style={{ fontSize: '11px', color: 'var(--color-primary)' }}>*có sử dụng AI</div>
          </div>
        </button>

        <button
          onClick={onOpenObjectSheet}
          style={{
            background: 'var(--color-canvas)',
            border: '1px solid var(--color-hairline)',
            borderRadius: '18px',
            padding: '14px',
            display: 'flex',
            alignItems: 'center',
            gap: '10px',
            cursor: 'pointer',
            boxShadow: '0 2px 8px rgba(0,0,0,0.04)'
          }}
        >
          <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'rgba(52,199,89,0.1)', color: '#34c759', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <Camera size={18} />
          </div>
          <div style={{ textAlign: 'left' }}>
            <div style={{ fontWeight: 600, fontSize: '14px', color: 'var(--color-ink)' }}>Chụp Đồ Vật</div>
            <div style={{ fontSize: '11px', color: 'var(--color-ink-muted-48)' }}>Nhập số tiền</div>
          </div>
        </button>
      </div>

      {/* Category Scroll Chips */}
      <div className="ios-category-scroll">
        {['ALL', 'Hoá đơn', 'Mua sắm', 'Ăn uống', 'Di chuyển'].map(cat => (
          <button
            key={cat}
            className={`ios-category-chip ${activeCategory === cat ? 'active' : ''}`}
            onClick={() => onSelectCategory(cat)}
          >
            {cat === 'ALL' ? 'Tất cả' : cat}
          </button>
        ))}
      </div>

      {/* Search Bar */}
      <div style={{ position: 'relative' }}>
        <Search size={16} style={{ position: 'absolute', left: '14px', top: '50%', transform: 'translateY(-50%)', color: 'var(--color-ink-muted-48)' }} />
        <input
          type="text"
          style={{
            width: '100%',
            height: '42px',
            borderRadius: '99px',
            backgroundColor: 'var(--color-canvas)',
            border: '1px solid var(--color-hairline)',
            paddingLeft: '40px',
            paddingRight: '16px',
            fontSize: '14px',
            outline: 'none'
          }}
          placeholder="Tìm chi tiêu..."
          value={searchQuery}
          onChange={(e) => setSearchQuery(e.target.value)}
        />
      </div>

      {/* Photo Expenses Feed */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <h3 style={{ fontSize: '18px', fontWeight: 700, fontFamily: 'var(--font-display)' }}>
            Ảnh Chi Tiêu ({filtered.length})
          </h3>
          <button
            onClick={onResetData}
            style={{ background: 'none', border: 'none', color: 'var(--color-ink-muted-48)', cursor: 'pointer', fontSize: '12px', display: 'flex', alignItems: 'center', gap: '4px' }}
          >
            <RefreshCw size={12} />
            <span>Dữ liệu mẫu</span>
          </button>
        </div>

        {filtered.length === 0 ? (
          <div style={{ textAlign: 'center', padding: '40px 20px', color: 'var(--color-ink-muted-48)' }}>
            <ShoppingBag size={40} style={{ marginBottom: '8px' }} />
            <p style={{ fontSize: '14px' }}>Chưa có chi tiêu nào</p>
          </div>
        ) : (
          filtered.map(item => (
            <div key={item.id} className="ios-photo-item">
              <div className="ios-photo-wrap">
                <img src={item.imageUrl} alt={item.title} className="ios-photo-img" />
                <span style={{ position: 'absolute', top: '10px', left: '10px', background: 'rgba(0,0,0,0.75)', color: '#fff', fontSize: '11px', fontWeight: 600, padding: '4px 10px', borderRadius: '99px', backdropFilter: 'blur(4px)' }}>
                  {item.category}
                </span>
                {item.type === 'ai_receipt' && (
                  <span style={{ position: 'absolute', top: '10px', right: '10px', background: 'var(--color-primary)', color: '#fff', fontSize: '10px', fontWeight: 600, padding: '4px 8px', borderRadius: '99px', display: 'flex', alignItems: 'center', gap: '3px' }}>
                    <Sparkles size={10} /> AI Receipt
                  </span>
                )}
              </div>

              <div style={{ padding: '14px 16px' }}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <div style={{ fontWeight: 600, fontSize: '16px', color: 'var(--color-ink)' }}>{item.title}</div>
                  <button
                    onClick={() => onDeleteExpense(item.id)}
                    style={{ background: 'none', border: 'none', color: 'var(--color-ink-muted-48)', cursor: 'pointer' }}
                  >
                    <Trash2 size={16} />
                  </button>
                </div>

                <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: '12px', color: 'var(--color-ink-muted-48)', marginTop: '4px' }}>
                  <span>{item.merchant || 'Cửa hàng'}</span>
                  <span>{item.date}</span>
                </div>

                <div style={{ fontSize: '20px', fontWeight: 700, color: 'var(--color-primary)', fontFamily: 'var(--font-display)', marginTop: '8px' }}>
                  {item.amount.toLocaleString('vi-VN')} đ
                </div>

                {item.notes && (
                  <p style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)', fontStyle: 'italic', marginTop: '4px' }}>
                    "{item.notes}"
                  </p>
                )}
              </div>
            </div>
          ))
        )}
      </div>
    </div>
  );
};
