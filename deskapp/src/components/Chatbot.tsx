import React, { useState, useRef, useEffect } from 'react'
import { X, Send, Loader2, Trash2 } from 'lucide-react'
import { chatWithAI } from '../services/ai'
import type { Expense, ChatMessage } from '../types'
import { getCategoryLabel } from '../services/categories'
import type { CategoryItem } from '../services/categories'
import './Chatbot.css'

interface ChatbotProps {
  expenses: Expense[]
  categories: CategoryItem[]
  isOpen: boolean
  onClose: () => void
}

const INITIAL_MESSAGE: ChatMessage = {
  id: '1',
  role: 'assistant',
  content: 'Mày mở app lên làm gì? Lại định tiêu tiền vớ vẩn gì nữa đúng không? Khai mau, nay mày đã phung phí bao nhiêu tiền rồi!'
}

export const Chatbot: React.FC<ChatbotProps> = ({ expenses, categories, isOpen, onClose }) => {
  const [shouldRender, setShouldRender] = useState(isOpen)
  const [isClosing, setIsClosing] = useState(false)
  const [messages, setMessages] = useState<ChatMessage[]>([INITIAL_MESSAGE])
  const [input, setInput] = useState('')
  const [isLoading, setIsLoading] = useState(false)

  const endRef = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (isOpen) {
      setShouldRender(true)
      setIsClosing(false)
    } else if (shouldRender) {
      setIsClosing(true)
      const timer = setTimeout(() => setShouldRender(false), 200)
      return () => clearTimeout(timer)
    }
  }, [isOpen, shouldRender])

  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSend = async () => {
    if (!input.trim()) return
    const userMsg: ChatMessage = { id: Date.now().toString(), role: 'user', content: input }
    const assistantId = (Date.now() + 1).toString()
    const typingMsg: ChatMessage = { id: assistantId, role: 'assistant', content: '' }
    
    // Snapshot the conversation before adding the empty typing message for the API
    const apiMessages = [...messages, userMsg]
    
    setMessages(prev => [...prev, userMsg, typingMsg])
    setInput('')
    setIsLoading(true)

    // Build context
    const formatDate = (dateStr: string) => {
      const d = new Date(dateStr)
      if (isNaN(d.getTime())) return dateStr
      const day = String(d.getDate()).padStart(2, '0')
      const month = String(d.getMonth() + 1).padStart(2, '0')
      const year = d.getFullYear()
      return `${day}/${month}/${year}`
    }
    const context = expenses.map(e => `${formatDate(e.date)}: ${getCategoryLabel(categories, e.category)} - ${e.amount.toLocaleString('vi-VN')} VND`).join('\n')

    try {
      const responseText = await chatWithAI(
        apiMessages.map(m => ({ role: m.role, content: m.content })),
        context,
        (currentText) => {
          setMessages(prev => prev.map(m => m.id === assistantId ? { ...m, content: currentText } : m))
        }
      )

      setMessages(prev => prev.map(m => m.id === assistantId ? { ...m, content: responseText } : m))
    } catch (e) {
      console.error(e)
      setMessages(prev => prev.map(m => m.id === assistantId ? { ...m, content: '⚠️ Đã xảy ra lỗi kết nối.' } : m))
    } finally {
      setIsLoading(false)
    }
  }

  const handleClearHistory = () => {
    if (messages.length <= 1) return
    if (confirm('Xoá toàn bộ lịch sử trò chuyện?')) {
      setMessages([{
        ...INITIAL_MESSAGE,
        id: Date.now().toString()
      }])
    }
  }

  const handleClose = () => {
    onClose()
  }

  return (
    <>
      {shouldRender && (
        <div className={`chatbot-window ${isClosing ? 'closing' : ''}`}>
          <div className="chatbot-header">
            <h3>MDaily AI</h3>
            <div className="chatbot-header-actions">
              <button
                className="btn-icon small"
                onClick={handleClearHistory}
                title="Xoá lịch sử trò chuyện"
                disabled={messages.length <= 1}
              >
                <Trash2 size={16} />
              </button>
              <button className="btn-icon small" onClick={handleClose} title="Đóng">
                <X size={16} />
              </button>
            </div>
          </div>

          <div className="chatbot-messages">
            {messages.map(msg => (
              <div key={msg.id} className={`message ${msg.role}`}>
                {msg.content ? (
                  <p>{msg.content}</p>
                ) : (
                  <div className="loading-indicator">
                    <Loader2 size={16} className="spinner" />
                  </div>
                )}
              </div>
            ))}
            <div ref={endRef} />
          </div>

          <div className="chatbot-input">
            <input
              type="text"
              value={input}
              onChange={e => setInput(e.target.value)}
              placeholder="Hỏi về chi tiêu của bạn..."
              onKeyDown={e => e.key === 'Enter' && handleSend()}
            />
            <button className="btn-icon primary" onClick={handleSend} disabled={isLoading || !input.trim()}>
              <Send size={16} color="var(--on-primary)" />
            </button>
          </div>
        </div>
      )}
    </>
  )
}
