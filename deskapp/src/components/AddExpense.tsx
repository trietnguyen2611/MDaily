import React, { useState, useRef, useEffect, useCallback } from 'react'
import { Upload, Loader2, Wand2, X, Plus } from 'lucide-react'
import type { Expense } from '../types'
import { analyzeReceiptWithMacModel, extractTextFromImage, processReceiptWithAI } from '../services/ai'
import { CustomSelect } from './CustomSelect'
import type { SelectOption } from './CustomSelect'
import { getCurrencySymbol, t, getLanguage } from '../services/i18n'
import './AddExpense.css'

interface AddExpenseProps {
  onCancel: () => void
  onSave: (expense: Omit<Expense, 'id' | 'date'>) => void
  categoryOptions: SelectOption[]
  onAddCategory: (label: string) => void
  initialPhoto?: string | null
  autoExtractEnabled?: boolean
}

export const AddExpense: React.FC<AddExpenseProps> = ({
  onCancel,
  onSave,
  categoryOptions,
  onAddCategory,
  initialPhoto,
  autoExtractEnabled = false
}) => {
  const [isAddingCategory, setIsAddingCategory] = useState(false)
  const [newCategoryLabel, setNewCategoryLabel] = useState('')
  const [amount, setAmount] = useState<string>('')
  const [category, setCategory] = useState<string>('shopping')
  const [note, setNote] = useState<string>('')
  const [photoPreview, setPhotoPreview] = useState<string | null>(initialPhoto || null)
  const lang = getLanguage()

  const [isAiProcessed, setIsAiProcessed] = useState(false)
  const [isAiProcessing, setIsAiProcessing] = useState(false)
  const [isConverting, setIsConverting] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const getBillsCategory = useCallback(() => {
    const billsCategory = categoryOptions.find(option => {
      const value = option.value.toLowerCase()
      const label = option.label.toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '')
      return value === 'bills' || value.includes('hoa-don') || label.includes('hoa don')
    })
    return billsCategory?.value || 'bills'
  }, [categoryOptions])

  const runExtraction = useCallback(async (base64: string) => {
    setIsAiProcessing(true)
    try {
      const nativeResult = await analyzeReceiptWithMacModel(base64)
      if (nativeResult) {
        if (!nativeResult.isReceipt) {
          setIsAiProcessed(false)
          return
        }
        if (nativeResult.amount > 0) setAmount(nativeResult.amount.toLocaleString('en-US'))
        setCategory(getBillsCategory())
        setIsAiProcessed(true)
        return
      }

      const text = await extractTextFromImage(base64)
      const aiData = await processReceiptWithAI(text, categoryOptions)
      if (!aiData.isReceipt) {
        setIsAiProcessed(false)
        return
      }
      if (aiData.amount > 0) setAmount(aiData.amount.toLocaleString('en-US'))
      if (aiData.category) setCategory(aiData.category)
      setIsAiProcessed(true)
    } catch (error) {
      console.error('AI Processing Error:', error)
    } finally {
      setIsAiProcessing(false)
    }
  }, [categoryOptions, getBillsCategory])

  useEffect(() => {
    if (initialPhoto && autoExtractEnabled) void runExtraction(initialPhoto)
  }, [initialPhoto, autoExtractEnabled, runExtraction])

  const decodeHeicWithHeicDecode = async (fileToConvert: File): Promise<Blob> => {
    const decodeModule = await import('heic-decode')
    let decodeFunc: any = decodeModule
    while (decodeFunc && typeof decodeFunc !== 'function' && decodeFunc.default) {
      decodeFunc = decodeFunc.default
    }

    const arrayBuffer = await fileToConvert.arrayBuffer()
    const { width, height, data } = await decodeFunc({ buffer: new Uint8Array(arrayBuffer) })

    const canvas = document.createElement('canvas')
    canvas.width = width
    canvas.height = height
    const ctx = canvas.getContext('2d')
    if (!ctx) throw new Error('Canvas 2D context null')

    const imageData = ctx.createImageData(width, height)
    imageData.data.set(data)
    ctx.putImageData(imageData, 0, 0)

    return new Promise((resolve, reject) => {
      canvas.toBlob((blob) => {
        if (blob) resolve(blob)
        else reject(new Error('Canvas toBlob failed'))
      }, 'image/jpeg', 0.85)
    })
  }

  const convertHeicViaCanvas = (fileToConvert: File): Promise<Blob> => {
    return new Promise((resolve, reject) => {
      const url = URL.createObjectURL(fileToConvert)
      const img = new Image()
      img.onload = () => {
        const canvas = document.createElement('canvas')
        canvas.width = img.naturalWidth || img.width
        canvas.height = img.naturalHeight || img.height
        const ctx = canvas.getContext('2d')
        if (!ctx) {
          URL.revokeObjectURL(url)
          return reject(new Error('Canvas context null'))
        }
        ctx.drawImage(img, 0, 0)
        canvas.toBlob((blob) => {
          URL.revokeObjectURL(url)
          if (blob) resolve(blob)
          else reject(new Error('Canvas toBlob failed'))
        }, 'image/jpeg', 0.85)
      }
      img.onerror = (err) => {
        URL.revokeObjectURL(url)
        reject(err)
      }
      img.src = url
    })
  }

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    let file = e.target.files?.[0]
    if (!file) return

    setIsConverting(true)

    const isHeic = file.type.toLowerCase().includes('heic') ||
      file.type.toLowerCase().includes('heif') ||
      file.name.toLowerCase().endsWith('.heic') ||
      file.name.toLowerCase().endsWith('.heif')

    if (isHeic) {
      let convertedSuccess = false

      // 1. Try heic2any library first
      try {
        const heic2anyModule = await import('heic2any')
        let convert: any = heic2anyModule
        while (convert && typeof convert !== 'function' && convert.default) {
          convert = convert.default
        }

        if (typeof convert === 'function') {
          const convertedResult = await convert({
            blob: file,
            toType: 'image/jpeg',
            quality: 0.8,
            multiple: false
          })

          const blob = Array.isArray(convertedResult) ? convertedResult[0] : convertedResult
          file = new File([blob], file.name.replace(/\.hei[cf]$/i, '.jpg'), { type: 'image/jpeg' })
          convertedSuccess = true
        }
      } catch (error: any) {
        console.warn('heic2any failed, trying heic-decode pixel pipeline:', error)
      }

      // 2. Try heic-decode
      if (!convertedSuccess) {
        try {
          const jpegBlob = await decodeHeicWithHeicDecode(file)
          file = new File([jpegBlob], file.name.replace(/\.hei[cf]$/i, '.jpg'), { type: 'image/jpeg' })
          convertedSuccess = true
        } catch (heicDecodeErr) {
          console.warn('heic-decode pipeline failed, trying Canvas fallback:', heicDecodeErr)
        }
      }

      // 3. Fallback to Canvas decoding
      if (!convertedSuccess) {
        try {
          const jpegBlob = await convertHeicViaCanvas(file)
          file = new File([jpegBlob], file.name.replace(/\.hei[cf]$/i, '.jpg'), { type: 'image/jpeg' })
          convertedSuccess = true
        } catch (canvasErr) {
          console.error('Canvas HEIC fallback failed:', canvasErr)
        }
      }

      if (!convertedSuccess) {
        alert(t('heic_error', lang))
        setIsConverting(false)
        return
      }
    }

    const reader = new FileReader()
    reader.onload = async (event) => {
      const base64 = event.target?.result as string
      setPhotoPreview(base64)
      setIsConverting(false)
      if (autoExtractEnabled) void runExtraction(base64)
    }
    reader.onerror = () => setIsConverting(false)
    reader.readAsDataURL(file)
  }

  const formatAmountInput = (val: string) => {
    const digitsOnly = val.replace(/\D/g, '')
    if (!digitsOnly) return ''
    return Number(digitsOnly).toLocaleString('en-US')
  }

  const handleProcessAI = async () => {
    if (!photoPreview) return
    setIsAiProcessing(true)
    try {
      const nativeResult = await analyzeReceiptWithMacModel(photoPreview)
      if (nativeResult) {
        if (!nativeResult.isReceipt) {
          setIsAiProcessed(false)
          alert('Ảnh này chưa có đủ dấu hiệu của hoá đơn nên chưa tự động trích xuất.')
          return
        }
        if (nativeResult.amount > 0) setAmount(nativeResult.amount.toLocaleString('en-US'))
        setCategory(getBillsCategory())
        setIsAiProcessed(true)
        return
      }

      const text = await extractTextFromImage(photoPreview)
      const aiData = await processReceiptWithAI(text, categoryOptions)
      if (!aiData.isReceipt) {
        setIsAiProcessed(false)
        alert('Ảnh này chưa có đủ dấu hiệu của hoá đơn nên chưa tự động trích xuất.')
        return
      }
      if (aiData.amount && aiData.amount > 0) {
        setAmount(aiData.amount.toLocaleString('en-US'))
      }
      if (aiData.category) {
        setCategory(aiData.category)
      }
      setIsAiProcessed(true)
    } catch (err) {
      console.error('AI Processing Error:', err)
      alert('Không thể trích xuất dữ liệu từ ảnh. Hãy thử chọn ảnh hoá đơn rõ nét hơn.')
    } finally {
      setIsAiProcessing(false)
    }
  }

  const handleSave = () => {
    const rawNumeric = parseFloat(amount.replace(/,/g, ''))
    if (isNaN(rawNumeric) || rawNumeric <= 0) {
      alert(t('amount_invalid', lang))
      return
    }
    onSave({
      amount: rawNumeric,
      category: category as any,
      photo: photoPreview || '',
      note,
      isAiProcessed
    })
  }

  const currSymbol = getCurrencySymbol()

  return (
    <div className="add-expense-container">
      <div className="add-expense-body">
        <div className="add-expense-left">
          {!photoPreview ? (
            <div className="upload-area" onClick={() => !isConverting && fileInputRef.current?.click()}>
              {isConverting ? (
                <>
                  <Loader2 size={48} className="spinner" />
                  <p>{t('processing', lang)}</p>
                </>
              ) : (
                <>
                  <Upload size={48} />
                  <p>{t('take_photo_sub', lang)}</p>
                </>
              )}
            </div>
          ) : (
            <>
              <div className="preview-area">
                <img src={photoPreview} alt="Preview" className="preview-image" />
                <button type="button" className="btn-icon change-photo" onClick={() => setPhotoPreview(null)} title={t('cancel', lang)}>
                  <X size={20} />
                </button>
              </div>
              <button
                type="button"
                className={`btn-ai-extract ${isAiProcessing ? 'loading' : ''}`}
                onClick={handleProcessAI}
                disabled={isAiProcessing}
              >
                {isAiProcessing ? <Loader2 className="spinner" size={20} /> : <Wand2 size={20} />}
                <span>{isAiProcessing ? t('ai_extracting', lang) : (lang === 'vi' ? 'Tự động trích xuất' : 'Auto Extract')}</span>
              </button>
            </>
          )}
          <input type="file" ref={fileInputRef} hidden accept="image/*,.heic,.heif,.HEIC,.HEIF,image/heic,image/heif" onChange={handleFileChange} />
        </div>

        <div className="add-expense-right">
          <div className="form-group">
            <label>{t('amount_label', lang)} ({currSymbol})</label>
            <input
              type="text"
              value={amount}
              onChange={e => setAmount(formatAmountInput(e.target.value))}
              placeholder={t('amount_placeholder', lang)}
            />
          </div>

          <div className="form-group">
            <label>{t('category_label', lang)}</label>
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
                <Plus size={14} /> {t('add_category_btn', lang)}
              </button>
            ) : (
              <div className="add-category-inline">
                <input
                  type="text"
                  value={newCategoryLabel}
                  onChange={e => setNewCategoryLabel(e.target.value)}
                  placeholder={t('new_cat_placeholder', lang)}
                  autoFocus
                  onKeyDown={e => {
                    if (e.key === 'Enter' && newCategoryLabel.trim()) {
                      onAddCategory(newCategoryLabel.trim())
                      setCategory(newCategoryLabel.trim().toLowerCase().normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/g, 'd').replace(/\s+/g, '-').replace(/[^a-z0-9-]/g, ''))
                      setNewCategoryLabel('')
                      setIsAddingCategory(false)
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
                      setNewCategoryLabel('')
                      setIsAddingCategory(false)
                    }
                  }}
                >
                  {t('add_btn', lang)}
                </button>
                <button
                  type="button"
                  className="btn-cancel-category"
                  onClick={() => { setIsAddingCategory(false); setNewCategoryLabel('') }}
                >
                  <X size={14} />
                </button>
              </div>
            )}
          </div>

          <div className="form-group">
            <label>{t('note_label', lang)}</label>
            <input
              type="text"
              value={note}
              onChange={e => setNote(e.target.value)}
              placeholder={t('note_placeholder', lang)}
            />
          </div>

          <div className="form-actions">
            <button className="btn-utility" onClick={onCancel}>{t('cancel', lang)}</button>
            <button className="btn-primary" onClick={handleSave}>{t('save_expense', lang)}</button>
          </div>
        </div>
      </div>
    </div>
  )
}
