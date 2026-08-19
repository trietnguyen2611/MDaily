import React, { useState, useEffect } from 'react'
import { Globe, Trash2, Info, Sparkles, ScanLine, MessageCircle, CheckCircle2, XCircle } from 'lucide-react'
import { clearExpenses } from '../services/db'
import { checkAFMStatus, getAutoExtractEnabled, setAutoExtractEnabled, getAiChatEnabled, setAiChatEnabled } from '../services/ai'
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
  onAiSettingsChanged?: () => void
}

export const SettingsPage: React.FC<SettingsPageProps> = ({ onDataCleared, onAiSettingsChanged }) => {
  const [currency, setCurrency] = useState('vnd')
  const [isClearing, setIsClearing] = useState(false)
  const [afmStatus, setAfmStatus] = useState<{ available: boolean; model: string; canExtractImage: boolean; message: string } | null>(null)
  const [autoExtract, setAutoExtract] = useState(getAutoExtractEnabled())
  const [aiChatOn, setAiChatOn] = useState(getAiChatEnabled())

  useEffect(() => {
    checkAFMStatus().then(setAfmStatus)
  }, [])

  const handleClearData = async () => {
    if (confirm('Bạn chắc chắn muốn xoá toàn bộ dữ liệu chi tiêu?')) {
      setIsClearing(true)
      await clearExpenses()
      setIsClearing(false)
      alert('Đã xoá toàn bộ dữ liệu chi tiêu.')
      if (onDataCleared) onDataCleared()
    }
  }

  const toggleAutoExtract = () => {
    const next = !autoExtract
    setAutoExtract(next)
    setAutoExtractEnabled(next)
    onAiSettingsChanged?.()
  }

  const toggleAiChat = () => {
    const next = !aiChatOn
    setAiChatOn(next)
    setAiChatEnabled(next)
    onAiSettingsChanged?.()
  }

  const isAFMAvailable = afmStatus?.available ?? false

  return (
    <div className="settings-container">
      {/* Apple Intelligence Section */}
      <div className="settings-section">
        <h3>Apple Intelligence</h3>
        <div className="settings-group">
          {/* AFM Status */}
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper ai-icon">
                <Sparkles size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">Trạng thái</span>
                <span className="settings-item-desc">
                  {afmStatus ? afmStatus.message : 'Đang kiểm tra...'}
                </span>
              </div>
            </div>
            {afmStatus && (
              <span className={`settings-badge ${isAFMAvailable ? 'success-badge' : 'error-badge'}`}>
                {isAFMAvailable ? <CheckCircle2 size={14} /> : <XCircle size={14} />}
                {isAFMAvailable ? 'Khả dụng' : 'Không khả dụng'}
              </span>
            )}
          </div>

          {/* Auto Extract Toggle */}
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper scan-icon">
                <ScanLine size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">Tự động nhận diện ảnh</span>
                <span className="settings-item-desc">
                  {isAFMAvailable
                    ? 'Trích xuất hoá đơn & tên đồ vật khi chụp ảnh'
                    : 'Cần thiết bị hỗ trợ Apple Intelligence'}
                </span>
              </div>
            </div>
            <label className={`toggle-switch ${!isAFMAvailable ? 'disabled' : ''}`}>
              <input
                type="checkbox"
                checked={autoExtract && isAFMAvailable}
                onChange={toggleAutoExtract}
                disabled={!isAFMAvailable}
              />
              <span className="toggle-slider" />
            </label>
          </div>

          {/* AI Chat Toggle */}
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper chat-icon">
                <MessageCircle size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">AI Chat</span>
                <span className="settings-item-desc">
                  {isAFMAvailable
                    ? 'Trò chuyện với MDaily AI trợ lý tài chính'
                    : 'Cần thiết bị hỗ trợ Apple Intelligence'}
                </span>
              </div>
            </div>
            <label className={`toggle-switch ${!isAFMAvailable ? 'disabled' : ''}`}>
              <input
                type="checkbox"
                checked={aiChatOn && isAFMAvailable}
                onChange={toggleAiChat}
                disabled={!isAFMAvailable}
              />
              <span className="toggle-slider" />
            </label>
          </div>
        </div>
      </div>

      {/* UI & Options */}
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

      {/* Data Management */}
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

      {/* App Info */}
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
                <span className="settings-item-desc">Phiên bản 1.1 — Apple Intelligence</span>
              </div>
            </div>
            <span className="settings-badge">iOS - v1.1</span>
          </div>
        </div>
      </div>
    </div>
  )
}
