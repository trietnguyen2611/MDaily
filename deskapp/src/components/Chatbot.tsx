import React, { useState, useRef, useEffect } from 'react'
import { MessageCircle, X, Send, Loader2 } from 'lucide-react'
import { chatWithAI } from '../services/ai'
import type { Expense, ChatMessage } from '../types'
import './Chatbot.css'

interface ChatbotProps {
  expenses: Expense[]
  isOpen: boolean
  onClose: () => void
}

export const Chatbot: React.FC<ChatbotProps> = ({ expenses, isOpen, onClose }) => {
  const [shouldRender, setShouldRender] = useState(isOpen)
  const [isClosing, setIsClosing] = useState(false)
  const [messages, setMessages] = useState<ChatMessage[]>([{
    id: '1',
    role: 'assistant',
    content: 'Chào bạn, tôi là MDaily AI. Bạn cần tư vấn gì về chi tiêu hôm nay?'
  }])
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
    setMessages(prev => [...prev, userMsg])
    setInput('')
    setIsLoading(true)

    // Build context
    const context = expenses.map(e => `${new Date(e.date).toLocaleDateString()}: ${e.category} - ${e.amount}đ`).join('\n')

    try {
      const responseText = await chatWithAI(
        [...messages, userMsg].map(m => ({ role: m.role, content: m.content })),
        context
      )

      const assistantMsg: ChatMessage = {
        id: (Date.now() + 1).toString(),
        role: 'assistant',
        content: responseText
      }
      setMessages(prev => [...prev, assistantMsg])
    } catch (e) {
      console.error(e)
    } finally {
      setIsLoading(false)
    }
  }

  const handleClose = () => {
    // Just call onClose, the useEffect will handle the animation
    onClose()
  }

  return (
    <>
      {shouldRender && (
        <div className={`chatbot-window ${isClosing ? 'closing' : ''}`}>
          <div className="chatbot-header">
            <h3>MDaily AI</h3>
            <button className="btn-icon small" onClick={handleClose}>
              <X size={16} />
            </button>
          </div>

          <div className="chatbot-messages">
            {messages.map(msg => (
              <div key={msg.id} className={`message ${msg.role}`}>
                <p>{msg.content}</p>
              </div>
            ))}
            {isLoading && (
              <div className="message assistant loading">
                <Loader2 size={16} className="spinner" />
                <span>MDaily AI đang trả lời...</span>
              </div>
            )}
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
