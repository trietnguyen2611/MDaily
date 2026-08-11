import React, { useState, useRef } from 'react'
import { Camera, Upload, Loader2, Wand2 } from 'lucide-react'
import type { Expense } from '../types'
import { extractTextFromImage, processReceiptWithAI } from '../services/ai'
import './AddExpense.css'

interface AddExpenseProps {
  onCancel: () => void
  onSave: (expense: Omit<Expense, 'id' | 'date'>) => void
}

export const AddExpense: React.FC<AddExpenseProps> = ({ onCancel, onSave }) => {
  const [amount, setAmount] = useState<string>('')
  const [category, setCategory] = useState<string>('shopping')
  const [note, setNote] = useState<string>('')
  const [photoPreview, setPhotoPreview] = useState<string | null>(null)
  
  const [isAiProcessed, setIsAiProcessed] = useState(false)
  const [isAiProcessing, setIsAiProcessing] = useState(false)
  const [isConverting, setIsConverting] = useState(false)
  const fileInputRef = useRef<HTMLInputElement>(null)

  const handleFileChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    let file = e.target.files?.[0]
    if (!file) return

    setIsConverting(true)
    
    const isHeic = file.type.toLowerCase().includes('heic') || 
                   file.type.toLowerCase().includes('heif') ||
                   file.name.toLowerCase().endsWith('.heic') ||
                   file.name.toLowerCase().endsWith('.heif');

    if (isHeic) {
      try {
        const heic2anyModule = await import('heic2any')
        const convert = heic2anyModule.default || heic2anyModule
        const convertedBlob = await convert({
          blob: file,
          toType: 'image/jpeg',
          quality: 0.7
        })
        const blob = Array.isArray(convertedBlob) ? convertedBlob[0] : convertedBlob
        file = new File([blob], file.name.replace(/\.hei[cf]$/i, '.jpg'), { type: 'image/jpeg' })
      } catch (error: any) {
        console.error('HEIC conversion failed:', error)
        alert(`Không thể chuyển đổi ảnh HEIC: ${error?.message || error?.toString() || 'Lỗi không xác định'}`)
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

  const handleProcessAI = async () => {
    if (!photoPreview) return
    setIsAiProcessing(true)
    try {
      const text = await extractTextFromImage(photoPreview)
      const aiData = await processReceiptWithAI(text)
      if (aiData.amount) setAmount(aiData.amount.toLocaleString('en-US'))
      if (aiData.category) setCategory(aiData.category)
      setIsAiProcessed(true)
    } catch (err) {
      console.error(err)
      alert('MDaily AI failed to process the image.')
    } finally {
      setIsAiProcessing(false)
    }
  }

  const handleSave = () => {
    const rawNumeric = parseFloat(amount.replace(/,/g, ''))
    if (!photoPreview || isNaN(rawNumeric) || rawNumeric <= 0) {
      alert('Vui lòng chọn ảnh và nhập số tiền hợp lệ')
      return
    }
    onSave({
      amount: rawNumeric,
      category: category as any,
      photo: photoPreview,
      note,
      isAiProcessed
    })
  }

  return (
    <div className="add-expense-container">
      <h2>Thêm chi tiêu mới</h2>
      
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
            <div className="preview-area">
              <img src={photoPreview} alt="Preview" className="preview-image" />
              <button className="btn-icon change-photo" onClick={() => setPhotoPreview(null)}>
                <Upload size={20} />
              </button>
              <button 
                className={`btn-utility ai-button ${isAiProcessing ? 'loading' : ''}`}
                onClick={handleProcessAI}
                disabled={isAiProcessing}
              >
                {isAiProcessing ? <Loader2 className="spinner" size={16} /> : <Wand2 size={16} />}
                <span>MDaily AI Tự động trích xuất</span>
              </button>
            </div>
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
            <select value={category} onChange={e => setCategory(e.target.value)}>
              <option value="bills">Hoá đơn</option>
              <option value="shopping">Mua sắm</option>
              <option value="food">Ăn uống</option>
              <option value="transport">Di chuyển</option>
            </select>
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
