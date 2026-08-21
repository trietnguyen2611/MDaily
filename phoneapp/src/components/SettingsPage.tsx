import React, { useState, useEffect } from 'react'
import { Globe, Trash2, Info, Sparkles, ScanLine, MessageCircle, CheckCircle2, XCircle, Languages } from 'lucide-react'
import { clearExpenses } from '../services/db'
import { checkAFMStatus, getAutoExtractEnabled, setAutoExtractEnabled, getAiChatEnabled, setAiChatEnabled } from '../services/ai'
import { getLanguage, setLanguage, getCurrency, setCurrency, t } from '../services/i18n'
import type { Language, Currency } from '../services/i18n'
import { CustomSelect } from './CustomSelect'
import type { SelectOption } from './CustomSelect'
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
  const [afmStatus, setAfmStatus] = useState<{ available: boolean; model: string; canExtractImage: boolean; message: string } | null>(null)
  const [autoExtract, setAutoExtract] = useState(getAutoExtractEnabled())
  const [aiChatOn, setAiChatOn] = useState(getAiChatEnabled())

  useEffect(() => {
    checkAFMStatus().then(setAfmStatus)
  }, [])

  const handleLanguageChange = (newLangVal: string) => {
    const l = newLangVal as Language
    setCurrentLang(l)
    setLanguage(l)
    onSettingsChanged?.()
  }

  const handleCurrencyChange = (newCurrVal: string) => {
    const c = newCurrVal as Currency
    setCurrentCurrency(c)
    setCurrency(c)
    onSettingsChanged?.()
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

      {/* 2. Apple Intelligence Section */}
      <div className="settings-section">
        <h3>{t('apple_intelligence', currentLang)}</h3>
        <div className="settings-group">
          {/* AFM Status */}
          <div className="settings-item">
            <div className="settings-item-left">
              <div className="settings-icon-wrapper ai-icon">
                <Sparkles size={18} />
              </div>
              <div className="settings-item-info">
                <span className="settings-item-label">{t('status', currentLang)}</span>
                <span className="settings-item-desc">
                  {afmStatus ? afmStatus.message : '...'}
                </span>
              </div>
            </div>
            {afmStatus && (
              <span className={`settings-badge ${isAFMAvailable ? 'success-badge' : 'error-badge'}`}>
                {isAFMAvailable ? <CheckCircle2 size={14} /> : <XCircle size={14} />}
                {isAFMAvailable ? t('available', currentLang) : t('unavailable', currentLang)}
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
                <span className="settings-item-label">{t('auto_extract', currentLang)}</span>
                <span className="settings-item-desc">
                  {isAFMAvailable
                    ? t('auto_extract_desc', currentLang)
                    : t('auto_extract_req', currentLang)}
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
                <span className="settings-item-label">{t('ai_chat', currentLang)}</span>
                <span className="settings-item-desc">
                  {isAFMAvailable
                    ? t('ai_chat_desc', currentLang)
                    : t('auto_extract_req', currentLang)}
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

      {/* 3. UI & Options: Language & Currency */}
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
                <span className="settings-item-label">MDaily Mobile</span>
                <span className="settings-item-desc">{t('app_version_desc', currentLang)}</span>
              </div>
            </div>
            <span className="settings-badge">v2.4.0</span>
          </div>
        </div>
      </div>
    </div>
  )
}
