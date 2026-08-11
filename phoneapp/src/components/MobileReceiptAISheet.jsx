import React, { useState } from 'react';
import { X, Sparkles, Upload, Loader2, CheckCircle2 } from 'lucide-react';
import { JanAIService } from '../services/JanAIService';
import { MOCK_EXPENSE_PHOTOS } from '../services/ExpenseStore';

export const MobileReceiptAISheet = ({ isOpen, onClose, onSave }) => {
  const [selectedImage, setSelectedImage] = useState(MOCK_EXPENSE_PHOTOS.electricity);
  const [hintText, setHintText] = useState('Hóa đơn Điện Lực EVN Tháng 8');
  const [isScanning, setIsScanning] = useState(false);
  const [scanResult, setScanResult] = useState(null);
  const [aiSource, setAiSource] = useState('');

  if (!isOpen) return null;

  const handleImageChange = (e) => {
    const file = e.target.files[0];
    if (file) {
      setHintText(file.name);
      const reader = new FileReader();
      reader.onloadend = () => setSelectedImage(reader.result);
      reader.readAsDataURL(file);
    }
  };

  const handlePresetSelect = (preset) => {
    if (preset === 'evn') {
      setSelectedImage(MOCK_EXPENSE_PHOTOS.electricity);
      setHintText('Hóa đơn EVN Điện lực');
    } else if (preset === 'lotte') {
      setSelectedImage(MOCK_EXPENSE_PHOTOS.supermarket);
      setHintText('Hóa đơn Lotte Mart');
    } else if (preset === 'grab') {
      setSelectedImage(MOCK_EXPENSE_PHOTOS.taxi);
      setHintText('Hóa đơn Grab Taxi');
    }
  };

  const handleStartScan = async () => {
    setIsScanning(true);
    setScanResult(null);
    try {
      const res = await JanAIService.scanInvoiceWithAI(selectedImage, hintText);
      setAiSource(res.source);
      setScanResult(res.data);
    } catch (e) {
      console.error(e);
    } finally {
      setIsScanning(false);
    }
  };

  const handleConfirm = () => {
    if (!scanResult) return;
    onSave({
      title: scanResult.title || 'Hóa đơn quét AI',
      amount: Number(scanResult.amount) || 0,
      category: scanResult.category || 'Hoá đơn',
      merchant: scanResult.merchant || 'Nhà cung cấp',
      notes: scanResult.notes || 'Quét tự động bởi Gemma 2 2B',
      items: scanResult.items || [],
      imageUrl: selectedImage,
      type: 'ai_receipt',
      date: scanResult.date || new Date().toISOString().split('T')[0]
    });
    setScanResult(null);
    onClose();
  };

  return (
    <div className="ios-sheet-overlay" onClick={onClose}>
      <div className="ios-sheet-content" onClick={(e) => e.stopPropagation()}>
        <div className="ios-sheet-handle" />

        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center' }}>
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
              <h3 style={{ fontSize: '20px', fontWeight: 700, fontFamily: 'var(--font-display)', margin: 0 }}>
                Quét Hóa Đơn AI
              </h3>
              <span style={{ fontSize: '10px', background: 'rgba(0,102,204,0.1)', color: 'var(--color-primary)', padding: '2px 8px', borderRadius: '99px', fontWeight: 600 }}>
                *có sử dụng AI
              </span>
            </div>
            <p style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)' }}>
              Tự động đọc số tiền &amp; danh mục từ ảnh hóa đơn trên iPhone
            </p>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', color: 'var(--color-ink-muted-48)' }}>
            <X size={20} />
          </button>
        </div>

        {/* Presets */}
        <div>
          <label style={{ fontSize: '11px', color: 'var(--color-ink-muted-48)', fontWeight: 600 }}>
            CHỌN HÓA ĐƠN MẪU:
          </label>
          <div style={{ display: 'flex', gap: '6px', marginTop: '6px' }}>
            <button className="ios-category-chip" type="button" onClick={() => handlePresetSelect('evn')}>
              ⚡ Tiền điện
            </button>
            <button className="ios-category-chip" type="button" onClick={() => handlePresetSelect('lotte')}>
              🛒 Siêu thị
            </button>
            <button className="ios-category-chip" type="button" onClick={() => handlePresetSelect('grab')}>
              🚕 Grab Taxi
            </button>
          </div>
        </div>

        {/* Photo view */}
        <div style={{ position: 'relative', width: '100%', height: '160px', borderRadius: '16px', overflow: 'hidden', background: '#e5e5ea' }}>
          <img src={selectedImage} alt="Invoice" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          <label style={{ position: 'absolute', bottom: '10px', right: '10px', background: 'rgba(0,0,0,0.7)', color: '#fff', padding: '6px 12px', borderRadius: '99px', fontSize: '11px', cursor: 'pointer', display: 'flex', alignItems: 'center', gap: '4px' }}>
            <Upload size={12} />
            <span>Tải hóa đơn khác</span>
            <input type="file" accept="image/*" onChange={handleImageChange} style={{ display: 'none' }} />
          </label>
        </div>

        {!scanResult ? (
          <button
            onClick={handleStartScan}
            disabled={isScanning}
            style={{ width: '100%', height: '48px', borderRadius: '99px', background: 'var(--color-primary)', color: '#fff', fontWeight: 600, border: 'none', cursor: 'pointer', display: 'flex', alignItems: 'center', justifyContent: 'center', gap: '8px', fontSize: '15px' }}
          >
            {isScanning ? (
              <>
                <Loader2 size={18} style={{ animation: 'spin 1s linear infinite' }} />
                <span>AI đang đọc hóa đơn...</span>
              </>
            ) : (
              <>
                <Sparkles size={18} />
                <span>Bắt đầu Quét AI (*Gemma 2 2B)</span>
              </>
            )}
          </button>
        ) : (
          <div style={{ background: 'var(--color-canvas-parchment)', padding: '16px', borderRadius: '16px', border: '1px solid var(--color-primary)' }}>
            <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#34c759', fontWeight: 600, fontSize: '13px', marginBottom: '10px' }}>
              <CheckCircle2 size={16} />
              <span>AI Trích xuất thành công</span>
            </div>

            <div style={{ display: 'flex', flexDirection: 'column', gap: '8px', fontSize: '14px' }}>
              <div><strong>Hóa đơn:</strong> {scanResult.title}</div>
              <div><strong>Đơn vị:</strong> {scanResult.merchant}</div>
              <div><strong>Số tiền:</strong> <span style={{ color: 'var(--color-primary)', fontWeight: 700 }}>{scanResult.amount?.toLocaleString('vi-VN')} đ</span></div>
              <div><strong>Danh mục AI chọn:</strong> {scanResult.category}</div>
            </div>

            <button
              onClick={handleConfirm}
              style={{ width: '100%', height: '44px', borderRadius: '99px', background: 'var(--color-primary)', color: '#fff', fontWeight: 600, border: 'none', cursor: 'pointer', marginTop: '14px' }}
            >
              Ghi nhận vào Nhật Ký
            </button>
          </div>
        )}
      </div>
    </div>
  );
};
