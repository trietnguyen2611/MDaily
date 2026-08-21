import React, { useState, useEffect } from 'react'
import {
  Globe,
  Trash2,
  Info,
  Sparkles,
  Check,
  XCircle,
  RefreshCw,
  Save,
  ScanLine,
  MessageCircle,
  Wifi,
  QrCode,
  Copy,
  Languages,
  CheckCircle2
} from 'lucide-react'
import QRCode from 'qrcode'
import { clearExpenses } from '../services/db'
import {
  getCustomAiUrl,
  setCustomAiUrl,
  checkAiConnection,
  checkAiAvailability,
  getAutoExtractEnabled,
  setAutoExtractEnabled,
  getAiChatEnabled,
  setAiChatEnabled
} from '../services/ai'
import {
  getLanguage,
  setLanguage,
  getCurrency,
  setCurrency,
  t
} from '../services/i18n'
import type { Language, Currency } from '../services/i18n'
import { CustomSelect } from './CustomSelect'
import type { SelectOption } from './CustomSelect'
import type { SyncServerInfo } from '../electron'
import { APP_NAME, APP_VERSION_LABEL } from '../constants'
import './SettingsPage.css'

const CURRENCY_OPTIONS: SelectOption[] = [
  { value: 'vnd', label: 'VNĐ (₫)' },
  { value: 'usd', label: 'USD ($)' },
  { value: 'eur', label: 'EUR (€)' },
  { value: 'jpy', label: 'JPY (¥)' },
  { value: 'gbp', label: 'GBP (£)' }
]

const LANGUAGE_OPTIONS: SelectOption[] = [
  { value: 'vi', label: 'Tiếng Việt' },
  { value: 'en', label: 'English' }
]

interface SettingsPageProps {
  onDataCleared?: () => void
  onAiSettingsChanged?: () => void
  onSettingsChanged?: () => void
}

export const SettingsPage: React.FC<SettingsPageProps> = ({
  onDataCleared,
  onAiSettingsChanged,
  onSettingsChanged
}) => {
  const [currentLang, setCurrentLang] = useState<Language>(getLanguage())
  const [currentCurrency, setCurrentCurrency] = useState<Currency>(getCurrency())
  const [isClearing, setIsClearing] = useState(false)
  const [aiUrl, setAiUrl] = useState('')
  const [aiStatus, setAiStatus] = useState<'checking' | 'ok' | 'error' | 'idle'>('idle')
  const [aiModel, setAiModel] = useState('')
  const [isAiUrlDirty, setIsAiUrlDirty] = useState(false)
  const [aiAvailable, setAiAvailable] = useState(false)
  const [autoExtract, setAutoExtract] = useState(getAutoExtractEnabled())
  const [aiChatOn, setAiChatOn] = useState(getAiChatEnabled())

  // Wi-Fi Sync State
  const [syncInfo, setSyncInfo] = useState<SyncServerInfo | null>(null)
  const [qrDataUrl, setQrDataUrl] = useState<string>('')
  const [copiedNotice, setCopiedNotice] = useState(false)
  const [syncEventNotice, setSyncEventNotice] = useState<string | null>(null)

  useEffect(() => {
    const saved = getCustomAiUrl()
    if (saved) setAiUrl(saved)
    else setAiUrl('http://127.0.0.1:1337/v1')
  }, [])

  // Load sync server info on mount
  useEffect(() => {
    if (window.ipcRenderer) {
      window.ipcRenderer.invoke('get-sync-server-info').then((info: SyncServerInfo) => {
        if (info) {
          setSyncInfo(info)
          generateQr(info.qrPayload)
        }
      }).catch(console.error)

      const handleServerStatus = (_event: any, info: SyncServerInfo) => {
        const payload = info || _event
        if (payload && payload.qrPayload) {
          setSyncInfo(payload)
          generateQr(payload.qrPayload)
        }
      }

      const handleSyncEvent = (_event: any, eventData: any) => {
        const data = eventData || _event
        if (data && data.message) {
          setSyncEventNotice(data.message)
          setTimeout(() => setSyncEventNotice(null), 6000)
        }
      }

      window.ipcRenderer.on('sync-server-status-changed', handleServerStatus)
      window.ipcRenderer.on('sync-event-notification', handleSyncEvent)

      return () => {
        window.ipcRenderer?.removeListener('sync-server-status-changed', handleServerStatus)
        window.ipcRenderer?.removeListener('sync-event-notification', handleSyncEvent)
      }
    }
  }, [])

  const generateQr = async (payloadText: string) => {
    try {
      const url = await QRCode.toDataURL(payloadText, {
        width: 220,
        margin: 2,
        color: {
          dark: '#000000',
          light: '#ffffff'
        }
      })
      setQrDataUrl(url)
    } catch (err) {
      console.error('Failed to generate QR Code', err)
    }
  }

  const handleRefreshToken = async () => {
    if (window.ipcRenderer) {
      const info = await window.ipcRenderer.invoke('refresh-sync-token')
      if (info) {
        setSyncInfo(info)
        generateQr(info.qrPayload)
      }
    }
  }

  const handleCopyIpPort = () => {
    if (!syncInfo) return
    const textToCopy = `${syncInfo.ip}:${syncInfo.port}`
    navigator.clipboard.writeText(textToCopy)
    setCopiedNotice(true)
    setTimeout(() => setCopiedNotice(false), 2000)
  }

  useEffect(() => {
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

  const notifySettingsChanged = () => {
    onSettingsChanged?.()
    window.dispatchEvent(new CustomEvent('mdaily_settings_change'))
  }

  const handleLanguageChange = (newLangVal: string) => {
    const l = newLangVal as Language
    setCurrentLang(l)
    setLanguage(l)
    notifySettingsChanged()
  }

  const handleCurrencyChange = (newCurrVal: string) => {
    const c = newCurrVal as Currency
    setCurrentCurrency(c)
    setCurrency(c)
    notifySettingsChanged()
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
    onAiSettingsChanged?.()
    notifySettingsChanged()
  }

  const toggleAiChat = () => {
    const next = !aiChatOn
    setAiChatOn(next)
    setAiChatEnabled(next)
    onAiSettingsChanged?.()
    notifySettingsChanged()
  }

  const handleClearData = async () => {
    if (confirm(t('delete_confirm_all', currentLang))) {
      setIsClearing(true)
      await clearExpenses()
      setIsClearing(false)
      alert(t('deleted_success', currentLang))
      if (onDataCleared) onDataCleared()
    }
  }

  return (
    <div className="settings-container">
      {/* 1. Wi-Fi Sync Server & QR Code Section */}
      <div className="settings-section">
        <h3>{t('wifi_sync', currentLang)}</h3>
        <div className="settings-group">
          <div className="sync-server-card">
            <div className="sync-server-header">
              <div className="settings-item-left">
                <div className="settings-icon-wrapper wifi-icon">
                  <Wifi size={18} />
                </div>
                <div className="settings-item-info">
                  <span className="settings-item-label">{t('sync_server_running', currentLang)}</span>
                  <span className="settings-item-desc">
                    {syncInfo ? `${syncInfo.ip}:${syncInfo.port}` : t('sync_ready_waiting', currentLang)}
                  </span>
                </div>
              </div>

              <span className="settings-badge success-badge">
                <Check size={14} /> Sẵn sàng kết nối
              </span>
            </div>

            <div className="sync-qr-container-row">
              {/* QR Code Canvas Frame */}
              <div className="sync-qr-frame">
                {qrDataUrl ? (
                  <img src={qrDataUrl} alt="QR Code Đồng bộ MDaily" className="sync-qr-image" />
                ) : (
                  <div className="sync-qr-placeholder">
                    <QrCode size={48} className="spinner" />
                  </div>
                )}
              </div>

              {/* Instructions & Parameters */}
              <div className="sync-details-col">
                <p className="sync-qr-desc-text">
                  {t('sync_qr_instruction', currentLang)}
                </p>

                <div className="sync-credentials-grid">
                  <div className="sync-cred-item">
                    <span className="sync-cred-label">{t('sync_server_ip', currentLang)}</span>
                    <div className="sync-cred-val-row">
                      <strong className="sync-code-text">{syncInfo?.ip || '127.0.0.1'}</strong>
                    </div>
                  </div>

                  <div className="sync-cred-item">
                    <span className="sync-cred-label">{t('sync_server_port', currentLang)}</span>
                    <strong className="sync-code-text">{syncInfo?.port || 18321}</strong>
                  </div>

                  <div className="sync-cred-item">
                    <span className="sync-cred-label">{t('sync_server_pin', currentLang)}</span>
                    <strong className="sync-code-text pin-highlight">{syncInfo?.token || '------'}</strong>
                  </div>
                </div>

                <div className="sync-actions-toolbar">
                  <button className="btn-utility" onClick={handleCopyIpPort}>
                    <Copy size={15} />
                    <span>{copiedNotice ? 'Đã sao chép!' : t('sync_copy_ip', currentLang)}</span>
                  </button>

                  <button className="btn-utility" onClick={handleRefreshToken} title={t('sync_refresh_token', currentLang)}>
                    <RefreshCw size={15} />
                    <span>{t('sync_refresh_token', currentLang)}</span>
                  </button>
                </div>

                {syncEventNotice && (
                  <div className="sync-live-event-toast">
                    <CheckCircle2 size={16} />
                    <span>{syncEventNotice}</span>
                  </div>
                )}
              </div>
            </div>
          </div>
        </div>
      </div>

      {/* 2. Local AI Configuration Section */}
      <div className="settings-section">
        <h3>MDaily AI</h3>
        <div className="settings-group">
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper ai-icon"><Sparkles size={18} /></div>
              <div className="settings-item-info">
                <span className="settings-item-label">{t('ai_local_status', currentLang)}</span>
                <span className="settings-item-desc">
                  {aiAvailable ? t('ai_local_desc_connected', currentLang) : t('ai_local_desc_disconnected', currentLang)}
                </span>
              </div>
            </div>
            <span className={`settings-badge ${aiAvailable ? 'success-badge' : 'error-badge'}`}>
              {aiAvailable ? <Check size={14} /> : <XCircle size={14} />}
              {aiAvailable ? t('ai_ready', currentLang) : t('ai_not_ready', currentLang)}
            </span>
          </div>

          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper scan-icon"><ScanLine size={18} /></div>
              <div className="settings-item-info">
                <span className="settings-item-label">{t('auto_extract', currentLang)}</span>
                <span className="settings-item-desc">{t('auto_extract_desc', currentLang)}</span>
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
                <span className="settings-item-label">{t('ai_chat', currentLang)}</span>
                <span className="settings-item-desc">{t('ai_chat_desc', currentLang)}</span>
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

      {/* 3. UI Options: Language & Currency */}
      <div className="settings-section">
        <h3>{t('ui_options', currentLang)}</h3>
        <div className="settings-group">
          {/* Language Selector */}
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper theme-icon">
                <Languages size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">{t('language', currentLang)}</span>
                <span className="settings-item-desc">{t('language_desc', currentLang)}</span>
              </div>
            </div>
            <div style={{ width: 140 }}>
              <CustomSelect
                options={LANGUAGE_OPTIONS}
                value={currentLang}
                onChange={handleLanguageChange}
              />
            </div>
          </div>

          {/* Currency Selector */}
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper scan-icon">
                <Globe size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">{t('currency', currentLang)}</span>
                <span className="settings-item-desc">{t('currency_desc', currentLang)}</span>
              </div>
            </div>
            <div style={{ width: 140 }}>
              <CustomSelect
                options={CURRENCY_OPTIONS}
                value={currentCurrency}
                onChange={handleCurrencyChange}
              />
            </div>
          </div>
        </div>
      </div>

      {/* 4. Data Management */}
      <div className="settings-section">
        <h3>{t('data_management', currentLang)}</h3>
        <div className="settings-group">
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper danger-icon">
                <Trash2 size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">{t('delete_all_data', currentLang)}</span>
                <span className="settings-item-desc">{t('delete_all_desc', currentLang)}</span>
              </div>
            </div>
            <button
              className="btn-danger"
              onClick={handleClearData}
              disabled={isClearing}
            >
              {isClearing ? t('deleting', currentLang) : t('delete_data_btn', currentLang)}
            </button>
          </div>
        </div>
      </div>

      {/* 5. App Info */}
      <div className="settings-section">
        <h3>{t('app_info', currentLang)}</h3>
        <div className="settings-group">
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper info-icon">
                <Info size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">{APP_NAME}</span>
                <span className="settings-item-desc">{t('app_version_desc', currentLang)}</span>
              </div>
            </div>
            <span className="settings-badge">macOS · {APP_VERSION_LABEL}</span>
          </div>
        </div>
      </div>
    </div>
  )
}
