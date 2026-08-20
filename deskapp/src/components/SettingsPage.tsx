import React, { useState, useEffect } from 'react'
import { Globe, Trash2, Info, Sparkles, Check, XCircle, RefreshCw, Save, ScanLine, MessageCircle } from 'lucide-react'
import { clearExpenses } from '../services/db'
import { getCustomAiUrl, setCustomAiUrl, checkAiConnection, checkAiAvailability, getAutoExtractEnabled, setAutoExtractEnabled, getAiChatEnabled, setAiChatEnabled } from '../services/ai'
import { CustomSelect } from './CustomSelect'
import type { SelectOption } from './CustomSelect'
import { APP_NAME, APP_VERSION_LABEL } from '../constants'
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
  const [aiUrl, setAiUrl] = useState('')
  const [aiStatus, setAiStatus] = useState<'checking' | 'ok' | 'error' | 'idle'>('idle')
  const [aiModel, setAiModel] = useState('')
  const [isAiUrlDirty, setIsAiUrlDirty] = useState(false)
  const [aiAvailable, setAiAvailable] = useState(false)
  const [autoExtract, setAutoExtract] = useState(getAutoExtractEnabled())
  const [aiChatOn, setAiChatOn] = useState(getAiChatEnabled())

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
  }, [aiUrl, isAiUrlDirty])

  useEffect(() => {
    checkAiAvailability().then(result => {
      setAiAvailable(result.available)
      if (result.available) setAiModel(result.model)
    })
  }, [aiUrl])

  const notifyAiSettingsChanged = () => {
    onAiSettingsChanged?.()
    window.dispatchEvent(new CustomEvent('mdaily_settings_change'))
  }

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

  const toggleAutoExtract = () => {
    const next = !autoExtract
    setAutoExtract(next)
    setAutoExtractEnabled(next)
    notifyAiSettingsChanged()
  }

  const toggleAiChat = () => {
    const next = !aiChatOn
    setAiChatOn(next)
    setAiChatEnabled(next)
    notifyAiSettingsChanged()
  }

  const handleClearData = async () => {
    if (confirm('Bạn chắc chắn muốn xoá toàn bộ dữ liệu chi tiêu?')) {
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
        <h3>MDaily</h3>
        <div className="settings-group">
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper ai-icon"><Sparkles size={18} /></div>
              <div className="settings-item-info">
                <span className="settings-item-label">Trạng thái AI local</span>
                <span className="settings-item-desc">{aiAvailable ? 'Đã kết nối máy chủ AI' : 'Cần kết nối Jan, LM Studio hoặc Ollama'}</span>
              </div>
            </div>
            <span className={`settings-badge ${aiAvailable ? 'success-badge' : 'error-badge'}`}>
              {aiAvailable ? <Check size={14} /> : <XCircle size={14} />}
              {aiAvailable ? 'Sẵn sàng' : 'Chưa sẵn sàng'}
            </span>
          </div>
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper scan-icon"><ScanLine size={18} /></div>
              <div className="settings-item-info">
                <span className="settings-item-label">Tự động trích xuất ảnh</span>
                <span className="settings-item-desc">Tự điền số tiền và danh mục từ ảnh hoá đơn</span>
              </div>
            </div>
            <label className={`toggle-switch ${!aiAvailable ? 'disabled' : ''}`}>
              <input type="checkbox" checked={autoExtract && aiAvailable} onChange={toggleAutoExtract} disabled={!aiAvailable} />
              <span className="toggle-slider" />
            </label>
          </div>
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper chat-icon"><MessageCircle size={18} /></div>
              <div className="settings-item-info">
                <span className="settings-item-label">MDaily AI Chat</span>
                <span className="settings-item-desc">Mở trợ lý AI từ thanh công cụ</span>
              </div>
            </div>
            <label className={`toggle-switch ${!aiAvailable ? 'disabled' : ''}`}>
              <input type="checkbox" checked={aiChatOn && aiAvailable} onChange={toggleAiChat} disabled={!aiAvailable} />
              <span className="toggle-slider" />
            </label>
          </div>
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
                <span className="settings-item-label">{APP_NAME}</span>
                <span className="settings-item-desc">Phiên bản {APP_VERSION_LABEL}</span>
              </div>
            </div>
            <span className="settings-badge">macOS - {APP_VERSION_LABEL}</span>
          </div>
        </div>
      </div>
    </div>
  )
}
