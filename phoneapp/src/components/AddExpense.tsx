import React, { useState, useRef, useEffect, useCallback } from 'react'
import { Loader2, X, Plus, Sparkles, ImagePlus } from 'lucide-react'
import type { Expense } from '../types'
import { CustomSelect } from './CustomSelect'
import type { SelectOption } from './CustomSelect'
import { extractExpenseFromImage } from '../services/ai'
import { getCurrencySymbol, t } from '../services/i18n'
import './AddExpense.css'

interface AddExpenseProps {
  onCancel: () => void
  onSave: (expense: Omit<Expense, 'id' | 'date'>) => void
  categoryOptions: SelectOption[]
  onAddCategory: (label: string) => void
  initialPhoto?: string | null
  isAFMAvailable?: boolean
  autoExtractEnabled?: boolean
}

export const AddExpense: React.FC<AddExpenseProps> = ({
  onCancel, onSave, categoryOptions, onAddCategory, initialPhoto,
  isAFMAvailable = false, autoExtractEnabled = false
}) => {
  const [isAddingCategory, setIsAddingCategory] = useState(false)
  const [newCategoryLabel, setNewCategoryLabel] = useState('')
  const [amount, setAmount] = useState<string>('')
  const [category, setCategory] = useState<string>('shopping')
  const [note, setNote] = useState<string>('')
  const [photoPreview, setPhotoPreview] = useState<string | null>(initialPhoto || null)
  const [isConverting, setIsConverting] = useState(false)
  const [isExtracting, setIsExtracting] = useState(false)
  const [extractResult, setExtractResult] = useState<string | null>(null)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const runExtraction = useCallback(async (base64: string) => {
    setIsExtracting(true)
    setExtractResult(null)
    try {
      const result = await extractExpenseFromImage(base64)
      if (result.success) {
        if (result.itemName) setNote(result.itemName)
        if (result.amount && result.amount > 0) {
          setAmount(result.amount.toLocaleString('en-US'))
        }
        if (result.category) {
          const match = categoryOptions.find(o =>
            o.value === result.category ||
            o.label.toLowerCase().includes(result.category!.toLowerCase())
          )
          if (match) setCategory(match.value)
        }
        setExtractResult(result.isInvoice
          ? `✨ ${result.itemName}`
          : `✨ ${result.itemName}`)
      } else {
        setExtractResult(null)
      }
    } catch {
      setExtractResult(null)
    } finally {
      setIsExtracting(false)
    }
  }, [categoryOptions])

  useEffect(() => {
    if (initialPhoto) {
      setPhotoPreview(initialPhoto)
      if (isAFMAvailable && autoExtractEnabled) {
        runExtraction(initialPhoto)
      }
    }
  }, [initialPhoto, isAFMAvailable, autoExtractEnabled, runExtraction])

  const decodeHeicWithHeicDecode = async (fileToConvert: File): Promise<Blob> => {
    const decodeModule = await import('heic-decode')
    let decodeFunc: any = decodeModule
    while (decodeFunc && typeof decodeFunc !== 'function' && decodeFunc.default) decodeFunc = decodeFunc.default
    const arrayBuffer = await fileToConvert.arrayBuffer()
    const { width, height, data } = await decodeFunc({ buffer: new Uint8Array(arrayBuffer) })
    const canvas = document.createElement('canvas'); canvas.width = width; canvas.height = height
    const ctx = canvas.getContext('2d')
    if (!ctx) throw new Error('Canvas 2D context null')
    const imageData = ctx.createImageData(width, height); imageData.data.set(data); ctx.putImageData(imageData, 0, 0)
    return new Promise((resolve, reject) => {
      canvas.toBlob(blob => blob ? resolve(blob) : reject(new Error('toBlob failed')), 'image/jpeg', 0.85)
    })
  }

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    let file = e.target.files?.[0]
    if (!file) return
    setIsConverting(true)

    const isHeic = file.type.toLowerCase().includes('heic') || file.type.toLowerCase().includes('heif') ||
      file.name.toLowerCase().endsWith('.heic') || file.name.toLowerCase().endsWith('.heif')

    if (isHeic) {
      try {
        const heic2anyModule = await import('heic2any')
        let convert: any = heic2anyModule
        while (convert && typeof convert !== 'function' && convert.default) convert = convert.default
        if (typeof convert === 'function') {
          const result = await convert({ blob: file, toType: 'image/jpeg', quality: 0.8, multiple: false })
          const blob = Array.isArray(result) ? result[0] : result
          file = new File([blob], file.name.replace(/\.hei[cf]$/i, '.jpg'), { type: 'image/jpeg' })
        }
      } catch {
        try {
          const jpegBlob = await decodeHeicWithHeicDecode(file)
          file = new File([jpegBlob], file.name.replace(/\.hei[cf]$/i, '.jpg'), { type: 'image/jpeg' })
        } catch {
          alert(t('heic_error'))
          setIsConverting(false)
          return
        }
      }
    }

    const reader = new FileReader()
    reader.onload = async (event) => {
      const base64 = event.target?.result as string
      setPhotoPreview(base64)
      setIsConverting(false)
      if (isAFMAvailable && autoExtractEnabled) {
        runExtraction(base64)
      }
    }
    reader.onerror = () => setIsConverting(false)
    reader.readAsDataURL(file)
  }

  const formatAmountInput = (val: string) => {
    const digitsOnly = val.replace(/\D/g, '')
    if (!digitsOnly) return ''
    return Number(digitsOnly).toLocaleString('en-US')
  }

  const handleSave = () => {
    const rawNumeric = parseFloat(amount.replace(/,/g, ''))
    if (isNaN(rawNumeric) || rawNumeric <= 0) {
      alert(t('amount_invalid'))
      return
    }
    onSave({
      amount: rawNumeric,
      category: category as any,
      photo: photoPreview || undefined,
      note: note || undefined,
      isAiProcessed: !!extractResult
    })
  }

  const currSymbol = getCurrencySymbol()

  return (
    <div className="add-expense-container">
      <div className="add-expense-body">
        <div className="add-expense-left">
          {!photoPreview ? (
            <div
              className="upload-area compact"
              onClick={() => !isConverting && fileInputRef.current?.click()}
            >
              <input
                type="file"
                ref={fileInputRef}
                style={{ display: 'none' }}
                accept="image/*"
                onChange={handleFileChange}
                disabled={isConverting}
              />
              {isConverting ? (
                <div className="upload-placeholder-content">
                  <Loader2 size={36} className="spinner" />
                  <p>{t('processing')}</p>
                </div>
              ) : (
                <div className="upload-placeholder-content">
                  <ImagePlus size={36} />
                  <p>{t('add_photo_optional')}</p>
                  <span className="upload-sub-text">
                    {isAFMAvailable && autoExtractEnabled
                      ? t('ai_auto_sub')
                      : t('take_photo_sub')}
                  </span>
                </div>
              )}
            </div>
          ) : (
            <>
              <div className="preview-area">
                <img src={photoPreview} alt="Preview" className="preview-image" />
                <button type="button" className="btn-icon change-photo" onClick={() => { setPhotoPreview(null); setExtractResult(null) }} title={t('cancel')}>
                  <X size={20} />
                </button>
                {isExtracting && (
                  <div className="extract-overlay">
                    <Loader2 size={28} className="spinner" />
                    <span>{t('ai_extracting')}</span>
                  </div>
                )}
              </div>
              {extractResult && (
                <div className="extract-result-badge">
                  <Sparkles size={14} />
                  <span>{extractResult}</span>
                </div>
              )}
            </>
          )}
        </div>

        <div className="add-expense-right">
          <div className="form-group">
            <label>{t('amount_label')} ({currSymbol})</label>
            <input
              type="text"
              value={amount}
              onChange={e => setAmount(formatAmountInput(e.target.value))}
              placeholder={t('amount_placeholder')}
            />
          </div>

          <div className="form-group">
            <label>{t('category_label')}</label>
            <CustomSelect
              options={categoryOptions}
              value={category}
              onChange={setCategory}
            />
            {!isAddingCategory ? (
              <button
                type="button"
                className="btn-add-category"
                onClick={() => setIsAddingCategory(true)}
              >
                <Plus size={14} /> {t('add_category_btn')}
              </button>
            ) : (
              <div className="add-category-inline">
                <input
                  type="text"
                  value={newCategoryLabel}
                  onChange={e => setNewCategoryLabel(e.target.value)}
                  placeholder={t('new_cat_placeholder')}
                  autoFocus
                  onKeyDown={e => {
                    if (e.key === 'Enter' && newCategoryLabel.trim()) {
                      onAddCategory(newCategoryLabel.trim())
                      setCategory(newCategoryLabel.trim().toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''))
                      setNewCategoryLabel(''); setIsAddingCategory(false)
                    }
                  }}
                />
                <button
                  type="button"
                  className="btn-confirm-category"
                  onClick={() => {
                    if (newCategoryLabel.trim()) {
                      onAddCategory(newCategoryLabel.trim())
                      setCategory(newCategoryLabel.trim().toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''))
                      setNewCategoryLabel(''); setIsAddingCategory(false)
                    }
                  }}
                >{t('add_btn')}</button>
                <button type="button" className="btn-cancel-category" onClick={() => { setIsAddingCategory(false); setNewCategoryLabel('') }}>
                  <X size={14} />
                </button>
              </div>
            )}
          </div>

          <div className="form-group">
            <label>{t('note_label')}</label>
            <input
              type="text"
              value={note}
              onChange={e => setNote(e.target.value)}
              placeholder={isAFMAvailable ? t('note_ai_placeholder') : t('note_placeholder')}
            />
          </div>

          <div className="form-actions">
            <button className="btn-utility" onClick={onCancel}>{t('cancel')}</button>
            <button className="btn-primary" onClick={handleSave}>{t('save_expense')}</button>
          </div>
        </div>
      </div>
    </div>
  )
}
