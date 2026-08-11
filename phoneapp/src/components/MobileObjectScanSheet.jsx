import React, { useState } from 'react';
import { X, Upload, Camera } from 'lucide-react';
import { MOCK_EXPENSE_PHOTOS } from '../services/ExpenseStore';

export const MobileObjectScanSheet = ({ isOpen, onClose, onSave }) => {
  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState('Mua sắm');
  const [merchant, setMerchant] = useState('');
  const [notes, setNotes] = useState('');
  const [imageUrl, setImageUrl] = useState(MOCK_EXPENSE_PHOTOS.coffee);

  if (!isOpen) return null;

  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => setImageUrl(reader.result);
      reader.readAsDataURL(file);
    }
  };

  const handleSubmit = (e) => {
    e.preventDefault();
    if (!title || !amount) return;

    onSave({
      title,
      amount: Number(amount),
      category,
      merchant: merchant || 'Cửa hàng',
      notes,
      imageUrl,
      type: 'manual_object',
      date: new Date().toISOString().split('T')[0]
    });

    setTitle('');
    setAmount('');
    setNotes('');
    onClose();
  };

  return (
    <div className="ios-sheet-overlay" onClick={onClose}>
      <div className="ios-sheet-content" onClick={(e) => e.stopPropagation()}>
        <div className="ios-sheet-handle" />

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <h3 style={{ fontSize: '20px', fontWeight: 700, fontFamily: 'var(--font-display)' }}>
              Chụp / Tải Ảnh Đồ Vật
            </h3>
            <p style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)' }}>
              Ghi nhận chi tiêu và nhập giá tiền
            </p>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--color-ink-muted-48)' }}>
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '14px' }}>
          {/* Photo preview */}
          <div style={{ position: 'relative', width: '100%', height: '150px', borderRadius: '16px', overflow: 'hidden', background: '#e5e5ea', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
            <img src={imageUrl} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
            <label style={{ position: 'absolute', bottom: '10px', right: '10px', background: 'rgba(0,0,0,0.7)', color: '#fff', padding: '6px 12px', borderRadius: '99px', fontSize: '12px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}>
              <Upload size={12} />
              <span>Đổi ảnh</span>
              <input type="file" accept="image/*" onChange={handleImageUpload} style={{ display: 'none' }} />
            </label>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: 600 }}>Tên đồ vật / món hàng *</label>
            <input
              type="text"
              style={{ width: '100%', height: '44px', borderRadius: '12px', border: '1px solid var(--color-hairline)', padding: '0 14px', fontSize: '15px', background: 'var(--color-canvas-parchment)', marginTop: '4px' }}
              placeholder="VD: Cà phê phin, Giày sneaker..."
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '10px' }}>
            <div>
              <label style={{ fontSize: '12px', fontWeight: 600 }}>Số tiền (VNĐ) *</label>
              <input
                type="number"
                style={{ width: '100%', height: '44px', borderRadius: '12px', border: '1px solid var(--color-hairline)', padding: '0 14px', fontSize: '15px', background: 'var(--color-canvas-parchment)', marginTop: '4px' }}
                placeholder="VD: 85000"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
              />
            </div>
            <div>
              <label style={{ fontSize: '12px', fontWeight: 600 }}>Danh mục *</label>
              <select
                style={{ width: '100%', height: '44px', borderRadius: '12px', border: '1px solid var(--color-hairline)', padding: '0 14px', fontSize: '14px', background: 'var(--color-canvas-parchment)', marginTop: '4px' }}
                value={category}
                onChange={(e) => setCategory(e.target.value)}
              >
                <option value="Hoá đơn">Hoá đơn</option>
                <option value="Mua sắm">Mua sắm</option>
                <option value="Ăn uống">Ăn uống</option>
                <option value="Di chuyển">Di chuyển</option>
              </select>
            </div>
          </div>

          <div>
            <label style={{ fontSize: '12px', fontWeight: 600 }}>Ghi chú / Địa điểm</label>
            <input
              type="text"
              style={{ width: '100%', height: '44px', borderRadius: '12px', border: '1px solid var(--color-hairline)', padding: '0 14px', fontSize: '14px', background: 'var(--color-canvas-parchment)', marginTop: '4px' }}
              placeholder="VD: Highlands Nguyễn Huệ..."
              value={notes}
              onChange={(e) => setNotes(e.target.value)}
            />
          </div>

          <button
            type="submit"
            style={{ width: '100%', height: '48px', borderRadius: '99px', background: 'var(--color-primary)', color: '#fff', fontWeight: 600, border: 'none', cursor: 'pointer', fontSize: '16px', marginTop: '8px' }}
          >
            Lưu Chi Tiêu iOS
          </button>
        </form>
      </div>
    </div>
  );
};
