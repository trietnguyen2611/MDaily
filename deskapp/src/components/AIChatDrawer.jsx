import React, { useState, useEffect, useRef } from 'react';
import { X, Send, Sparkles, Bot, User, Cpu, Loader2 } from 'lucide-react';
import { JanAIService } from '../services/JanAIService';

export const AIChatDrawer = ({ isOpen, onClose, expenses, currentUser }) => {
  const [messages, setMessages] = useState([
    {
      id: 'welcome',
      role: 'assistant',
      text: `Xin chào ${currentUser?.name || 'bạn'}! Tôi là Trợ lý AI MDaily hoạt động trên mô hình Gemma 2 2B (Jan AI Local).\nTôi đã nắm đầy đủ ngữ cảnh ${expenses.length} khoản chi tiêu của bạn. Bạn muốn hỏi thông tin tài chính gì?`,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }
  ]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [aiSource, setAiSource] = useState('');
  const messagesEndRef = useRef(null);

  useEffect(() => {
    messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  if (!isOpen) return null;

  const handleSend = async (queryText) => {
    const textToSend = queryText || inputText;
    if (!textToSend.trim()) return;

    const userMsg = {
      id: 'msg-' + Date.now(),
      role: 'user',
      text: textToSend,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    setMessages(prev => [...prev, userMsg]);
    if (!queryText) setInputText('');
    setIsLoading(true);

    try {
      const res = await JanAIService.askExpenseChatbot(textToSend, expenses, currentUser);
      setAiSource(res.source);
      const aiMsg = {
        id: 'msg-' + (Date.now() + 1),
        role: 'assistant',
        text: res.reply,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };
      setMessages(prev => [...prev, aiMsg]);
    } catch (err) {
      console.error(err);
    } finally {
      setIsLoading(false);
    }
  };

  const handleQuickQuestion = (q) => {
    handleSend(q);
  };

  return (
    <div className="chat-drawer-overlay" onClick={onClose}>
      <div className="chat-drawer" onClick={(e) => e.stopPropagation()}>
        {/* Chat Drawer Header */}
        <div className="chat-header">
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
            <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'var(--color-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
              <Bot size={20} />
            </div>
            <div>
              <div style={{ fontWeight: 600, fontSize: '15px', display: 'flex', alignItems: 'center', gap: '6px' }}>
                <span>Trợ Lý Tài Chính AI</span>
                <span style={{ fontSize: '10px', background: 'rgba(0,102,204,0.1)', color: 'var(--color-primary)', padding: '2px 8px', borderRadius: '99px' }}>
                  Gemma 2 2B
                </span>
              </div>
              <p style={{ fontSize: '12px', color: 'var(--color-ink-muted-48)' }}>
                Cá nhân hóa cho {currentUser?.name}
              </p>
            </div>
          </div>
          <button onClick={onClose} style={{ background: 'none', border: 'none', cursor: 'pointer', color: 'var(--color-ink-muted-48)' }}>
            <X size={20} />
          </button>
        </div>

        {/* Quick Suggestion Chips */}
        <div style={{ padding: '10px 20px', background: 'var(--color-canvas-parchment)', borderBottom: '1px solid var(--color-hairline)', display: 'flex', gap: '6px', overflowX: 'auto' }}>
          <button className="category-chip" style={{ fontSize: '12px', padding: '6px 12px' }} onClick={() => handleQuickQuestion('Tháng này tôi tiêu tổng bao nhiêu tiền?')}>
            📊 Tổng chi tiêu?
          </button>
          <button className="category-chip" style={{ fontSize: '12px', padding: '6px 12px' }} onClick={() => handleQuickQuestion('Tôi đã tiêu bao nhiêu tiền ăn uống?')}>
            ☕ Tiền ăn uống?
          </button>
          <button className="category-chip" style={{ fontSize: '12px', padding: '6px 12px' }} onClick={() => handleQuickQuestion('Khoản chi nào đắt nhất?')}>
            📌 Chi nhiều nhất?
          </button>
          <button className="category-chip" style={{ fontSize: '12px', padding: '6px 12px' }} onClick={() => handleQuickQuestion('Cho tôi lời khuyên tiết kiệm')}>
            💡 Lời khuyên
          </button>
        </div>

        {/* Chat Messages */}
        <div className="chat-messages">
          {messages.map((msg) => (
            <div
              key={msg.id}
              className={`chat-bubble ${msg.role === 'user' ? 'user' : 'ai'}`}
            >
              <div>{msg.text}</div>
              <div style={{ fontSize: '10px', opacity: 0.6, marginTop: '6px', textAlign: msg.role === 'user' ? 'right' : 'left' }}>
                {msg.timestamp} {msg.role === 'assistant' && aiSource ? `• ${aiSource}` : ''}
              </div>
            </div>
          ))}

          {isLoading && (
            <div className="chat-bubble ai" style={{ display: 'flex', alignItems: 'center', gap: '8px' }}>
              <Loader2 size={16} className="spin-icon" style={{ animation: 'spin 1s linear infinite' }} />
              <span>Gemma 2 2B đang suy nghĩ...</span>
            </div>
          )}
          <div ref={messagesEndRef} />
        </div>

        {/* Input area */}
        <div className="chat-input-area">
          <input
            type="text"
            className="input-apple"
            placeholder="Hỏi AI về chi tiêu của bạn..."
            value={inputText}
            onChange={(e) => setInputText(e.target.value)}
            onKeyDown={(e) => e.key === 'Enter' && handleSend()}
          />
          <button className="btn-primary-pill" style={{ padding: '0 18px', height: '48px' }} onClick={() => handleSend()}>
            <Send size={16} />
          </button>
        </div>
      </div>
    </div>
  );
};
