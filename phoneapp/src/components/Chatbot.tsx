import React, { useState, useRef, useEffect } from 'react'
import { Sparkles, Send, Loader2, Trash2, AlertTriangle, CheckCircle2 } from 'lucide-react'
import { chatWithAI, checkAFMStatus } from '../services/ai'
import type { Expense } from '../types'
import { getCategoryLabel } from '../services/categories'
import type { CategoryItem } from '../services/categories'
import { BottomSheet } from './BottomSheet'
import './Chatbot.css'

interface ChatMessage {
  id: string
  role: 'user' | 'assistant'
  content: string
}

interface ChatbotProps {
  expenses: Expense[]
  categories: CategoryItem[]
  isOpen: boolean
  onClose: () => void
}

const INITIAL_MESSAGE: ChatMessage = {
  id: '1',
  role: 'assistant',
  content: 'Mở app lên làm gì đấy? Lại định phung phí tiền đúng không? Khai mau, nay mày đã tiêu bao nhiêu tiền rồi!'
}

export const Chatbot: React.FC<ChatbotProps> = ({ expenses, categories, isOpen, onClose }) => {
  const [messages, setMessages] = useState<ChatMessage[]>([INITIAL_MESSAGE])
  const [input, setInput] = useState('')
  const [isLoading, setIsLoading] = useState(false)
  const [afmStatus, setAfmStatus] = useState<{ available: boolean; model: string; message: string } | null>(null)
  const [keyboardHeight, setKeyboardHeight] = useState(0)

  const endRef = useRef<HTMLDivElement>(null)
  const inputRef = useRef<HTMLInputElement>(null)
  const messagesRef = useRef<HTMLDivElement>(null)

  const quickPrompts = [
    '💡 Tổng chi tiêu?',
    '📊 Lời khuyên tiết kiệm',
    '🍔 Chi ăn uống?',
    '⚡ Khoản chi lớn nhất?'
  ]

  // Check AFM status when opened
  useEffect(() => {
    if (isOpen) {
      setTimeout(() => inputRef.current?.focus(), 400)
      checkAFMStatus().then(status => setAfmStatus(status))
    } else {
      setKeyboardHeight(0)
    }
  }, [isOpen])

  // Keyboard-aware height tracking
  useEffect(() => {
    if (!isOpen) return

    const handleViewportResize = () => {
      if (window.visualViewport) {
        const vvHeight = window.visualViewport.height
        const windowHeight = window.innerHeight
        const kbHeight = windowHeight - vvHeight
        setKeyboardHeight(kbHeight > 100 ? kbHeight : 0)
      }
    }

    window.visualViewport?.addEventListener('resize', handleViewportResize)
    return () => {
      window.visualViewport?.removeEventListener('resize', handleViewportResize)
    }
  }, [isOpen])

  // Auto scroll to bottom on new messages
  useEffect(() => {
    endRef.current?.scrollIntoView({ behavior: 'smooth' })
  }, [messages])

  const handleSend = async (customText?: string) => {
    const textToSend = customText || input
    if (!textToSend.trim() || isLoading) return
    const userMsg: ChatMessage = { id: Date.now().toString(), role: 'user', content: textToSend }
    const assistantId = (Date.now() + 1).toString()
    const typingMsg: ChatMessage = { id: assistantId, role: 'assistant', content: '...' }

    const apiMessages = [...messages, userMsg]

    setMessages(prev => [...prev, userMsg, typingMsg])
    if (!customText) setInput('')
    setIsLoading(true)

    const formatDate = (dateStr: string) => {
      const d = new Date(dateStr)
      if (isNaN(d.getTime())) return dateStr
      return `${String(d.getDate()).padStart(2, '0')}/${String(d.getMonth() + 1).padStart(2, '0')}/${d.getFullYear()}`
    }
    const context = expenses
      .slice(0, 30)
      .map(e => `${formatDate(e.date)}: ${getCategoryLabel(categories, e.category)} - ${e.amount.toLocaleString('vi-VN')} VND${e.note ? ` (${e.note})` : ''}`)
      .join('\n')

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
      setMessages(prev => prev.map(m => m.id === assistantId ? { ...m, content: '⚠️ Đã xảy ra lỗi kết nối AI.' } : m))
    } finally {
      setIsLoading(false)
    }
  }

  const handleClearHistory = () => {
    if (messages.length <= 1) return
    if (confirm('Xoá toàn bộ lịch sử trò chuyện với AI?')) {
      setMessages([{ ...INITIAL_MESSAGE, id: Date.now().toString() }])
    }
  }

  const sheetStyle: React.CSSProperties = keyboardHeight > 0
    ? { paddingBottom: 0, maxHeight: `calc(100vh - ${keyboardHeight}px)` }
    : {}

  return (
    <BottomSheet isOpen={isOpen} onClose={onClose}>
      <div className={`chatbot-sheet-content ${keyboardHeight > 0 ? 'keyboard-open' : ''}`} style={sheetStyle}>
        {/* Header */}
        <div className="chatbot-header">
          <div className="chatbot-header-title">
            <div className="ai-icon-badge">
              <Sparkles size={20} className="sparkle-icon" />
            </div>
            <div>
              <h3>MDaily AI</h3>
              {afmStatus ? (
                <span className={`afm-status-tag ${afmStatus.available ? 'active' : 'warning'}`}>
                {afmStatus.available ? <CheckCircle2 size={12} /> : <AlertTriangle size={12} />}
                  {afmStatus.model}
                </span>
              ) : (
                <span className="ai-subtitle">Trợ lý tài chính thông minh</span>
              )}
            </div>
          </div>

          <div className="chatbot-header-actions">
            <button
              className="chatbot-action-btn clear-btn"
              onClick={handleClearHistory}
              title="Xoá lịch sử chat"
            >
              <Trash2 size={16} />
            </button>
          </div>
        </div>

        {/* Messages */}
        <div className="chatbot-messages" ref={messagesRef}>
          {messages.map(msg => (
            <div key={msg.id} className={`chat-bubble-row ${msg.role}`}>
              {msg.role === 'assistant' && (
                <div className="msg-avatar">
                  <Sparkles size={14} />
                </div>
              )}
              <div className={`chat-bubble ${msg.role}`}>
                {msg.content === '...' ? (
                  <div className="typing-indicator">
                    <Loader2 size={16} className="spinner" />
                    <span>MDaily AI đang suy nghĩ...</span>
                  </div>
                ) : (
                  msg.content
                )}
              </div>
            </div>
          ))}
          <div ref={endRef} />
        </div>

        {/* Quick Suggestion Chips */}
        {keyboardHeight === 0 && (
          <div className="quick-prompts-bar">
            {quickPrompts.map((promptText, idx) => (
              <button
                key={idx}
                className="quick-prompt-chip"
                onClick={() => handleSend(promptText)}
                disabled={isLoading}
              >
                {promptText}
              </button>
            ))}
          </div>
        )}

        {/* Input Bar */}
        <div className="chatbot-input-bar">
          <input
            ref={inputRef}
            type="text"
            placeholder="Hỏi AI về chi tiêu, lời khuyên..."
            value={input}
            onChange={e => setInput(e.target.value)}
            onKeyDown={e => e.key === 'Enter' && handleSend()}
            disabled={isLoading}
          />
          <button
            type="button"
            className="chat-send-btn"
            onClick={() => handleSend()}
            disabled={!input.trim() || isLoading}
          >
            {isLoading ? <Loader2 size={18} className="spinner" /> : <Send size={18} />}
          </button>
        </div>
      </div>
    </BottomSheet>
  )
}
