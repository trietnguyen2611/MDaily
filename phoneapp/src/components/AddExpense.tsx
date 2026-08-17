import React, { useState, useRef, useEffect } from 'react'
import { Upload, Loader2, X, Plus } from 'lucide-react'
import type { Expense } from '../types'
import { CustomSelect } from './CustomSelect'
import type { SelectOption } from './CustomSelect'
import './AddExpense.css'

interface AddExpenseProps {
  onCancel: () => void
  onSave: (expense: Omit<Expense, 'id' | 'date'>) => void
  categoryOptions: SelectOption[]
  onAddCategory: (label: string) => void
  initialPhoto?: string | null
}

export const AddExpense: React.FC<AddExpenseProps> = ({ onCancel, onSave, categoryOptions, onAddCategory, initialPhoto }) => {
  const [isAddingCategory, setIsAddingCategory] = useState(false)
  const [newCategoryLabel, setNewCategoryLabel] = useState('')
  const [amount, setAmount] = useState<string>('')
  const [category, setCategory] = useState<string>('shopping')
  const [note, setNote] = useState<string>('')
  const [photoPreview, setPhotoPreview] = useState<string | null>(initialPhoto || null)

  useEffect(() => {
    if (initialPhoto) {
      setPhotoPreview(initialPhoto)
    }
  }, [initialPhoto])


  const [isConverting, setIsConverting] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

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
      file.name.toLowerCase().endsWith('.heif');

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

      // 2. Try heic-decode (decodes raw RGBA pixels directly, supports iPhone HEVC format)
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
        alert('Không thể chuyển đổi định dạng ảnh HEIC này. Vui lòng thử lại hoặc chọn tệp JPG/PNG.')
        setIsConverting(false)
        return
      }
    }

    const reader = new FileReader()
    reader.onload = async (event) => {
      const base64 = event.target?.result as string
      setPhotoPreview(base64)
      setIsConverting(false)
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
    if (!photoPreview || isNaN(rawNumeric) || rawNumeric <= 0) {
      alert('Chọn ảnh và nhập số tiền hợp lệ')
      return
    }
    onSave({
      amount: rawNumeric,
      category: category as any,
      photo: photoPreview,
      note
    })
  }

  return (
    <div className="add-expense-container">
      <div className="add-expense-body">
        <div className="add-expense-left">
          {!photoPreview ? (
            <div className="upload-area" onClick={() => !isConverting && fileInputRef.current?.click()}>
              {isConverting ? (
                <>
                  <Loader2 size={48} className="spinner" />
                  <p>Đang xử lý ảnh...</p>
                </>
              ) : (
                <>
                  <Upload size={48} />
                  <p>Chọn hoặc chụp ảnh đồ vật / hoá đơn</p>
                </>
              )}
            </div>
          ) : (
            <>
              <div className="preview-area">
                <img src={photoPreview} alt="Preview" className="preview-image" />
                <button type="button" className="btn-icon change-photo" onClick={() => setPhotoPreview(null)} title="Bỏ ảnh này">
                  <X size={20} />
                </button>
              </div>
            </>
          )}
          <input type="file" ref={fileInputRef} hidden accept="image/*,.heic,.heif,.HEIC,.HEIF,image/heic,image/heif" onChange={handleFileChange} />
        </div>

        <div className="add-expense-right">
          <div className="form-group">
            <label>Số tiền (VNĐ)</label>
            <input
              type="text"
              value={amount}
              onChange={e => setAmount(formatAmountInput(e.target.value))}
              placeholder="Ví dụ: 50,000"
            />
          </div>

          <div className="form-group">
            <label>Danh mục</label>
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
                <Plus size={14} /> Thêm danh mục mới
              </button>
            ) : (
              <div className="add-category-inline">
                <input
                  type="text"
                  value={newCategoryLabel}
                  onChange={e => setNewCategoryLabel(e.target.value)}
                  placeholder="Tên danh mục mới..."
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
                  Thêm
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
            <label>Ghi chú (Tùy chọn)</label>
            <input
              type="text"
              value={note}
              onChange={e => setNote(e.target.value)}
              placeholder="Nhập ghi chú..."
            />
          </div>

          <div className="form-actions">
            <button className="btn-utility" onClick={onCancel}>Huỷ</button>
            <button className="btn-primary" onClick={handleSave}>Lưu chi tiêu</button>
          </div>
        </div>
      </div>
    </div>
  )
}
