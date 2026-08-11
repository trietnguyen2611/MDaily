import React, { useState, useEffect } from 'react'
import { Globe, Trash2, Info, Sparkles, Check, XCircle, RefreshCw, Save } from 'lucide-react'
import { clearExpenses } from '../services/db'
import { getCustomAiUrl, setCustomAiUrl, checkAiConnection } from '../services/ai'
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
  const [aiUrl, setAiUrl] = useState('')
  const [aiStatus, setAiStatus] = useState<'checking' | 'ok' | 'error' | 'idle'>('idle')
  const [aiModel, setAiModel] = useState('')
  const [isAiUrlDirty, setIsAiUrlDirty] = useState(false)

  useEffect(() => {
    const saved = getCustomAiUrl()
    if (saved) setAiUrl(saved)
    else setAiUrl('http://127.0.0.1:1337/v1')
  }, [])

  useEffect(() => {
    // Auto check status on load
    if (aiUrl && !isAiUrlDirty) {
      handleCheckConnection(aiUrl)
    }
  }, [isAiUrlDirty])

  const handleCheckConnection = async (urlToCheck: string) => {
    setAiStatus('checking')
    const result = await checkAiConnection(urlToCheck)
    if (result.status === 'ok') {
      setAiStatus('ok')
      setAiModel(result.model)
    } else {
      setAiStatus('error')
    }
  }

  const handleSaveAiUrl = () => {
    setCustomAiUrl(aiUrl)
    setIsAiUrlDirty(false)
    handleCheckConnection(aiUrl)
  }

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
        <h3>Cấu hình MDaily AI Engine</h3>
        <div className="settings-group">
          <div className="settings-item-column">
            <div className="settings-item-header">
              <div className="settings-item-left">
                <div className="settings-icon-wrapper ai-icon">
                  <Sparkles size={18} />
                </div>
                <div className="settings-item-info">
                  <span className="settings-item-label">AI Local Server URL</span>
                  <span className="settings-item-desc">
                    Kết nối với Jan AI, LMStudio hoặc Ollama cục bộ. <br />
                    Mặc định: http://127.0.0.1:1337/v1
                  </span>
                </div>
              </div>
              {aiStatus === 'ok' && (
                <span className="settings-badge success-badge">
                  <Check size={14} /> Sẵn sàng
                </span>
              )}
              {aiStatus === 'error' && (
                <span className="settings-badge error-badge">
                  <XCircle size={14} /> Mất kết nối
                </span>
              )}
              {aiStatus === 'checking' && (
                <span className="settings-badge warning-badge">
                  <RefreshCw size={14} className="spinner" /> Đang kiểm tra...
                </span>
              )}
            </div>
            
            <div className="settings-action-row">
              <input 
                type="text" 
                className="settings-input"
                value={aiUrl}
                onChange={(e) => {
                  setAiUrl(e.target.value)
                  setIsAiUrlDirty(true)
                  setAiStatus('idle')
                }}
                placeholder="http://127.0.0.1:1337/v1"
              />
              {isAiUrlDirty ? (
                <button className="btn-utility save-btn" onClick={handleSaveAiUrl}>
                  <Save size={16} /> Lưu
                </button>
              ) : (
                <button className="btn-utility check-btn" onClick={() => handleCheckConnection(aiUrl)} disabled={aiStatus === 'checking'}>
                  <RefreshCw size={16} className={aiStatus === 'checking' ? 'spinner' : ''} /> Kiểm tra
                </button>
              )}
            </div>
            
            {aiStatus === 'ok' && aiModel && (
              <div className="ai-model-info">
                Mô hình đang dùng: <strong>{aiModel}</strong>
              </div>
            )}
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
                <span className="settings-item-desc">Xoá tất cả chi tiêu đã lưu trong cơ sở dữ liệu</span>
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
                <span className="settings-item-label">MDaily Desktop</span>
                <span className="settings-item-desc">Phiên bản 1.0</span>
              </div>
            </div>
            <span className="settings-badge">macOS - v1.0</span>
          </div>
        </div>
      </div>
    </div>
  )
}
