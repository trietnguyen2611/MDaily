import React, { useState } from 'react'
import { Globe, Trash2, Info } from 'lucide-react'
import { clearExpenses } from '../services/db'
import { CustomSelect } from './CustomSelect'
import type { SelectOption } from './CustomSelect'
import './SettingsPage.css'

const CURRENCY_OPTIONS: SelectOption[] = [
  { value: 'vnd', label: 'VNĐ (₫)' },
  { value: 'usd', label: 'USD ($)' },
  { value: 'eur', label: 'EUR (€)' }
]

interface SettingsPageProps {
  onDataCleared?: () => void
}

export const SettingsPage: React.FC<SettingsPageProps> = ({ onDataCleared }) => {
  const [currency, setCurrency] = useState('vnd')
  const [isClearing, setIsClearing] = useState(false)

  const handleClearData = async () => {
    if (confirm('Bạn có chắc chắn muốn xoá toàn bộ dữ liệu chi tiêu? Thao tác này không thể hoàn tác.')) {
      setIsClearing(true)
      await clearExpenses()
      setIsClearing(false)
      alert('Đã xoá toàn bộ dữ liệu chi tiêu.')
      if (onDataCleared) onDataCleared()
    }
  }

  return (
    <div className="settings-container">
      <div className="settings-section">
        <h3>Giao diện & Tùy chọn</h3>
        <div className="settings-group">
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper theme-icon">
                <Globe size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">Đơn vị tiền tệ</span>
                <span className="settings-item-desc">Đơn vị tiền tệ hiển thị trong ứng dụng</span>
              </div>
            </div>
            <div style={{ width: 140 }}>
              <CustomSelect
                options={CURRENCY_OPTIONS}
                value={currency}
                onChange={setCurrency}
              />
            </div>
          </div>
        </div>
      </div>


      <div className="settings-section">
        <h3>Quản lý dữ liệu</h3>
        <div className="settings-group">
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper danger-icon">
                <Trash2 size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">Xoá toàn bộ dữ liệu</span>
                <span className="settings-item-desc">Xoá tất cả chi tiêu đã lưu</span>
              </div>
            </div>
            <button
              className="btn-danger"
              onClick={handleClearData}
              disabled={isClearing}
            >
              {isClearing ? 'Đang xoá...' : 'Xoá dữ liệu'}
            </button>
          </div>
        </div>
      </div>

      <div className="settings-section">
        <h3>Thông tin ứng dụng</h3>
        <div className="settings-group">
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper info-icon">
                <Info size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">MDaily Mobile</span>
                <span className="settings-item-desc">Phiên bản 1.0</span>
              </div>
            </div>
            <span className="settings-badge">iOS - v1.0</span>
          </div>
        </div>
      </div>
    </div>
  )
}
