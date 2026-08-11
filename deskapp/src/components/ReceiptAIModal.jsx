import React, { useState } from 'react';
import { X, Sparkles, Upload, Loader2, CheckCircle2, AlertCircle, Cpu } from 'lucide-react';
import { JanAIService } from '../services/JanAIService';
import { MOCK_EXPENSE_PHOTOS } from '../services/ExpenseStore';

export const ReceiptAIModal = ({ isOpen, onClose, onSave }) => {
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
      reader.onloadend = () => {
        setSelectedImage(reader.result);
      };
      reader.readAsDataURL(file);
    }
  };

  const selectPreset = (type) => {
    if (type === 'electricity') {
      setSelectedImage(MOCK_EXPENSE_PHOTOS.electricity);
      setHintText('Hóa đơn Điện Lực EVN 1.250.000đ');
    } else if (type === 'supermarket') {
      setSelectedImage(MOCK_EXPENSE_PHOTOS.supermarket);
      setHintText('Hóa đơn Lotte Mart Quận 7');
    } else if (type === 'taxi') {
      setSelectedImage(MOCK_EXPENSE_PHOTOS.taxi);
      setHintText('Hóa đơn GrabCar Tân Sơn Nhất');
    } else if (type === 'coffee') {
      setSelectedImage(MOCK_EXPENSE_PHOTOS.coffee);
      setHintText('Hóa đơn Cà phê Highlands Nguyễn Huệ');
    }
  };

  const handleStartAIScan = async () => {
    setIsScanning(true);
    setScanResult(null);
    try {
      const res = await JanAIService.scanInvoiceWithAI(selectedImage, hintText);
      setAiSource(res.source);
      setScanResult(res.data);
    } catch (err) {
      console.error(err);
    } finally {
      setIsScanning(false);
    }
  };

  const handleConfirmSave = () => {
    if (!scanResult) return;
    onSave({
      title: scanResult.title || 'Hóa đơn quét AI',
      amount: Number(scanResult.amount) || 0,
      category: scanResult.category || 'Hoá đơn',
      merchant: scanResult.merchant || 'Nhà cung cấp',
      notes: scanResult.notes || 'Quét tự động bởi AI Gemma 2 2B',
      items: scanResult.items || [],
      imageUrl: selectedImage,
      type: 'ai_receipt',
      date: scanResult.date || new Date().toISOString().split('T')[0]
    });

    setScanResult(null);
    onClose();
  };

  return (
    <div className="modal-overlay">
      <div className="modal-content-apple" style={{ maxWidth: '640px' }}>
        <div className="modal-header">
          <div>
            <div style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <h3 style={{ margin: 0 }}>Quét Hóa Đơn Tự Động</h3>
              <span style={{ fontSize: '11px', background: 'rgba(0,102,204,0.1)', color: 'var(--color-primary)', padding: '3px 10px', borderRadius: 'var(--radius-pill)', fontWeight: 600 }}>
                *có sử dụng AI (Gemma 2 2B)
              </span>
            </div>
            <p style={{ fontSize: '13px', color: 'var(--color-ink-muted-48)', marginTop: '2px' }}>
              Tải ảnh hóa đơn / phiếu thu để Jan AI Gemma 2 tự động đọc số tiền, cửa hàng &amp; danh mục
            </p>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-ink-muted-48)' }}>
            <X size={20} />
          </button>
        </div>

        {/* Preset Sample Selector */}
        <div>
          <label style={{ fontSize: '13px', fontWeight: 600, color: 'var(--color-ink-muted-48)' }}>
            CHỌN MẪU HÓA ĐƠN THỬ NGHIỆM TẠI ĐÂY:
          </label>
          <div style={{ display: 'flex', gap: '8px', marginTop: '8px', flexWrap: 'wrap' }}>
            <button className="category-chip" type="button" onClick={() => selectPreset('electricity')}>
              ⚡ Hóa đơn Điện EVN
            </button>
            <button className="category-chip" type="button" onClick={() => selectPreset('supermarket')}>
              🛒 Hóa đơn Lotte Mart
            </button>
            <button className="category-chip" type="button" onClick={() => selectPreset('taxi')}>
              🚕 Hóa đơn Grab Taxi
            </button>
            <button className="category-chip" type="button" onClick={() => selectPreset('coffee')}>
              ☕ Hóa đơn Cà phê
            </button>
          </div>
        </div>

        {/* Image Preview */}
        <div style={{ display: 'flex', gap: '16px' }}>
          <div style={{ width: '200px', height: '180px', borderRadius: 'var(--radius-md)', overflow: 'hidden', border: '1px solid var(--color-hairline)', background: '#f0f0f2' }}>
            <img src={selectedImage} alt="Receipt" style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
          </div>

          <div style={{ flex: 1, display: 'flex', flexDirection: 'column', gap: '12px' }}>
            <label style={{ fontSize: '13px', fontWeight: 600 }}>Tải lên ảnh hóa đơn từ máy tính:</label>
            <label className="btn-secondary-pill" style={{ justifyContent: 'center', cursor: 'pointer' }}>
              <Upload size={16} />
              <span>Chọn ảnh hóa đơn khác</span>
              <input type="file" accept="image/*" onChange={handleImageChange} style={{ display: 'none' }} />
            </label>

            <label style={{ fontSize: '13px', fontWeight: 600 }}>Gợi ý văn bản / Từ khóa (Optional):</label>
            <input
              type="text"
              className="input-apple"
              placeholder="VD: Hóa đơn điện thoại, hóa đơn siêu thị..."
              value={hintText}
              onChange={(e) => setHintText(e.target.value)}
            />
          </div>
        </div>

        {/* Action button */}
        {!scanResult && (
          <button
            className="btn-primary-pill"
            style={{ width: '100%', justifyContent: 'center', padding: '14px' }}
            onClick={handleStartAIScan}
            disabled={isScanning}
          >
            {isScanning ? (
              <>
                <Loader2 size={18} className="spin-icon" style={{ animation: 'spin 1s linear infinite' }} />
                <span>Gemma 2 2B đang phân tích hóa đơn...</span>
              </>
            ) : (
              <>
                <Sparkles size={18} />
                <span>Bắt đầu Phân tích AI (*Gemma 2 2B)</span>
              </>
            )}
          </button>
        )}

        {/* AI Scan Result Card */}
        {scanResult && (
          <div style={{ background: 'var(--color-canvas-parchment)', padding: '20px', borderRadius: 'var(--radius-lg)', border: '1px solid var(--color-primary)' }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '12px' }}>
              <div style={{ display: 'flex', alignItems: 'center', gap: '6px', color: '#34c759', fontWeight: 600, fontSize: '14px' }}>
                <CheckCircle2 size={16} />
                <span>Kết quả AI Trích xuất thành công</span>
              </div>
              <span style={{ fontSize: '11px', color: 'var(--color-ink-muted-48)' }}>
                {aiSource}
              </span>
            </div>

            <div style={{ display: 'grid', gridTemplateColumns: '1fr 1fr', gap: '12px' }}>
              <div>
                <label style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)' }}>Tên hóa đơn</label>
                <input
                  type="text"
                  className="input-apple"
                  style={{ height: '38px', fontSize: '14px' }}
                  value={scanResult.title}
                  onChange={(e) => setScanResult({ ...scanResult, title: e.target.value })}
                />
              </div>
              <div>
                <label style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)' }}>Cửa hàng / Đơn vị</label>
                <input
                  type="text"
                  className="input-apple"
                  style={{ height: '38px', fontSize: '14px' }}
                  value={scanResult.merchant}
                  onChange={(e) => setScanResult({ ...scanResult, merchant: e.target.value })}
                />
              </div>
              <div>
                <label style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)' }}>Tổng số tiền (VNĐ)</label>
                <input
                  type="number"
                  className="input-apple"
                  style={{ height: '38px', fontSize: '14px', fontWeight: 600, color: 'var(--color-primary)' }}
                  value={scanResult.amount}
                  onChange={(e) => setScanResult({ ...scanResult, amount: Number(e.target.value) })}
                />
              </div>
              <div>
                <label style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)' }}>Danh mục AI chọn</label>
                <select
                  className="select-apple"
                  style={{ height: '38px', fontSize: '14px' }}
                  value={scanResult.category}
                  onChange={(e) => setScanResult({ ...scanResult, category: e.target.value })}
                >
                  <option value="Hoá đơn">Hoá đơn</option>
                  <option value="Mua sắm">Mua sắm</option>
                  <option value="Ăn uống">Ăn uống</option>
                  <option value="Di chuyển">Di chuyển</option>
                </select>
              </div>
            </div>

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '12px', marginTop: '16px' }}>
              <button className="btn-secondary-pill" onClick={() => setScanResult(null)}>
                Quét lại
              </button>
              <button className="btn-primary-pill" onClick={handleConfirmSave}>
                Ghi nhận vào Dashboard
              </button>
            </div>
          </div>
        )}
      </div>
    </div>
  );
};
