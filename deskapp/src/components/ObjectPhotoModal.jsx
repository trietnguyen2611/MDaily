import React, { useState } from 'react';
import { X, Upload, Camera, DollarSign, Tag, Calendar, FileText } from 'lucide-react';
import { MOCK_EXPENSE_PHOTOS } from '../services/ExpenseStore';

export const ObjectPhotoModal = ({ isOpen, onClose, onSave }) => {
  const [title, setTitle] = useState('');
  const [amount, setAmount] = useState('');
  const [category, setCategory] = useState('Mua sắm');
  const [merchant, setMerchant] = useState('');
  const [notes, setNotes] = useState('');
  const [imageUrl, setImageUrl] = useState(MOCK_EXPENSE_PHOTOS.shoes);

  if (!isOpen) return null;

  const handleImageUpload = (e) => {
    const file = e.target.files[0];
    if (file) {
      const reader = new FileReader();
      reader.onloadend = () => {
        setImageUrl(reader.result);
      };
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

    // Reset
    setTitle('');
    setAmount('');
    setNotes('');
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content-apple">
        <div className="modal-header">
          <div>
            <h3>Chụp / Import Ảnh Đồ Vật</h3>
            <p style={{ fontSize: '13px', color: 'var(--color-ink-muted-48)' }}>
              Ghi nhận chi tiêu bằng cách tải ảnh món đồ và nhập số tiền
            </p>
          </div>
          <button
            onClick={onClose}
            style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-ink-muted-48)' }}
          >
            <X size={20} />
          </button>
        </div>

        <form onSubmit={handleSubmit} style={{ display: 'flex', flexDirection: 'column', gap: '16px' }}>
          {/* Image Preview & Import */}
          <div style={{ display: 'flex', flexDirection: 'column', gap: '8px' }}>
            <label style={{ fontSize: '14px', fontWeight: 600 }}>Ảnh đồ vật / sản phẩm</label>
            <div style={{ position: 'relative', width: '100%', height: '180px', borderRadius: 'var(--radius-md)', overflow: 'hidden', border: '2px dashed var(--color-hairline)', backgroundColor: 'var(--color-canvas-parchment)', display: 'flex', alignItems: 'center', justifyContent: 'center' }}>
              <img src={imageUrl} alt="Preview" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
              <label style={{ position: 'absolute', bottom: '12px', right: '12px', background: 'rgba(0,0,0,0.7)', color: '#fff', padding: '6px 14px', borderRadius: 'var(--radius-pill)', fontSize: '12px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <Upload size={14} />
                <span>Đổi ảnh</span>
                <input type="file" accept="image/*" onChange={handleImageUpload} style={{ display: 'none' }} />
              </label>
            </div>
          </div>

          <div>
            <label style={{ fontSize: '14px', fontWeight: 600 }}>Tên đồ vật / Chi tiêu *</label>
            <input
              type="text"
              className="input-apple"
              placeholder="VD: Cà phê Phin Sữa Đá, Tai nghe AirPods..."
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              required
            />
          </div>

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div>
              <label style={{ fontSize: '14px', fontWeight: 600 }}>Giá tiền (VNĐ) *</label>
              <input
                type="number"
                className="input-apple"
                placeholder="VD: 85000"
                value={amount}
                onChange={(e) => setAmount(e.target.value)}
                required
              />
            </div>

            <div>
              <label style={{ fontSize: '14px', fontWeight: 600 }}>Danh mục *</label>
              <select
                className="select-apple"
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

          <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
            <div>
              <label style={{ fontSize: '14px', fontWeight: 600 }}>Cửa hàng / Địa điểm</label>
              <input
                type="text"
                className="input-apple"
                placeholder="VD: Highlands Nguyễn Huệ"
                value={merchant}
                onChange={(e) => setMerchant(e.target.value)}
              />
            </div>
            <div>
              <label style={{ fontSize: '14px', fontWeight: 600 }}>Ghi chú thêm</label>
              <input
                type="text"
                className="input-apple"
                placeholder="VD: Mua cùng đối tác..."
                value={notes}
                onChange={(e) => setNotes(e.target.value)}
              />
            </div>
          </div>

          <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '12px' }}>
            <button type="button" className="btn-secondary-pill" onClick={onClose}>
              Hủy
            </button>
            <button type="submit" className="btn-primary-pill">
              Lưu chi tiêu
            </button>
          </div>
        </form>
      </div>
    </div>
  );
};
