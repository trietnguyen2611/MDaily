import React, { useState, useRef, useEffect } from 'react';
import { Send, Sparkles, Bot, Loader2 } from 'lucide-react';
import { JanAIService } from '../services/JanAIService';

export const MobileAIChatTab = ({ expenses, currentUser }) => {
  const [messages, setMessages] = useState([
    {
      id: 'welcome',
      role: 'assistant',
      text: `Xin chào ${currentUser?.name || 'bạn'}! Tôi là Trợ lý AI Chi Tiêu trên iPhone (Gemma 2 2B).\nTôi đã tổng hợp ${expenses.length} khoản chi tiêu của bạn. Hãy đặt câu hỏi bất kỳ!`,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    }
  ]);
  const [inputText, setInputText] = useState('');
  const [isLoading, setIsLoading] = useState(false);
  const [aiSource, setAiSource] = useState('');
  const chatEndRef = useRef(null);

  useEffect(() => {
    chatEndRef.current?.scrollIntoView({ behavior: 'smooth' });
  }, [messages, isLoading]);

  const handleSend = async (customQuery) => {
    const query = customQuery || inputText;
    if (!query.trim()) return;

    const userMsg = {
      id: 'user-' + Date.now(),
      role: 'user',
      text: query,
      timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
    };

    setMessages(prev => [...prev, userMsg]);
    if (!customQuery) setInputText('');
    setIsLoading(true);

    try {
      const res = await JanAIService.askExpenseChatbot(query, expenses, currentUser);
      setAiSource(res.source);
      const aiMsg = {
        id: 'ai-' + Date.now(),
        role: 'assistant',
        text: res.reply,
        timestamp: new Date().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })
      };
      setMessages(prev => [...prev, aiMsg]);
    } catch (e) {
      console.error(e);
    } finally {
      setIsLoading(false);
    }
  };

  return (
    <div className="ios-scroll-content" style={{ paddingBottom: '90px' }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '10px', padding: '12px', background: 'var(--color-canvas)', borderRadius: '20px', border: '1px solid var(--color-hairline)' }}>
        <div style={{ width: '36px', height: '36px', borderRadius: '50%', background: 'var(--color-primary)', display: 'flex', alignItems: 'center', justifyContent: 'center', color: '#fff' }}>
          <Bot size={20} />
        </div>
        <div>
          <div style={{ fontWeight: 700, fontSize: '15px', display: 'flex', alignItems: 'center', gap: '6px' }}>
            <span>Trợ Lý Tài Chính AI</span>
            <span style={{ fontSize: '10px', background: 'rgba(0,102,204,0.1)', color: 'var(--color-primary)', padding: '2px 8px', borderRadius: '99px' }}>
              *Gemma 2 2B
            </span>
          </div>
          <div style={{ fontSize: '11px', color: 'var(--color-ink-muted-48)' }}>
            Cá nhân hóa cho {currentUser?.name}
          </div>
        </div>
      </div>

      {/* Suggested prompts */}
      <div style={{ display: 'flex', gap: '6px', overflowX: 'auto', paddingBottom: '4px' }}>
        <button className="ios-category-chip" style={{ fontSize: '12px' }} onClick={() => handleSend('Tôi đã tiêu bao nhiêu tiền ăn uống?')}>
          ☕ Ăn uống hết bao nhiêu?
        </button>
        <button className="ios-category-chip" style={{ fontSize: '12px' }} onClick={() => handleSend('Tổng tiền hoá đơn?')}>
          🧾 Các hoá đơn?
        </button>
        <button className="ios-category-chip" style={{ fontSize: '12px' }} onClick={() => handleSend('Cho tôi lời khuyên tiết kiệm')}>
          💡 Lời khuyên
        </button>
      </div>

      {/* Messages */}
      <div style={{ display: 'flex', flexDirection: 'column', gap: '12px' }}>
        {messages.map(m => (
          <div key={m.id} className={`ios-chat-bubble ${m.role === 'user' ? 'user' : 'ai'}`}>
            <div style={{ whiteSpace: 'pre-wrap' }}>{m.text}</div>
            <div style={{ fontSize: '10px', opacity: 0.6, marginTop: '4px', textAlign: m.role === 'user' ? 'right' : 'left' }}>
              {m.timestamp} {m.role === 'assistant' && aiSource ? `• ${aiSource}` : ''}
            </div>
          </div>
        ))}

        {isLoading && (
          <div className="ios-chat-bubble ai" style={{ display: 'flex', alignItems: 'center', gap: '6px' }}>
            <Loader2 size={14} style={{ animation: 'spin 1s linear infinite' }} />
            <span>Gemma 2 2B đang phân tích...</span>
          </div>
        )}
        <div ref={chatEndRef} />
      </div>

      {/* Fixed input bar for iOS feel */}
      <div style={{ display: 'flex', gap: '8px', marginTop: '12px' }}>
        <input
          type="text"
          style={{ flex: 1, height: '44px', borderRadius: '99px', border: '1px solid var(--color-hairline)', padding: '0 16px', fontSize: '15px', background: 'var(--color-canvas)', outline: 'none' }}
          placeholder="Hỏi AI câu hỏi tài chính..."
          value={inputText}
          onChange={(e) => setInputText(e.target.value)}
          onKeyDown={(e) => e.key === 'Enter' && handleSend()}
        />
        <button
          onClick={() => handleSend()}
          style={{ width: '44px', height: '44px', borderRadius: '50%', background: 'var(--color-primary)', color: '#fff', border: 'none', display: 'flex', alignItems: 'center', justifyContent: 'center', cursor: 'pointer' }}
        >
          <Send size={18} />
        </button>
      </div>
    </div>
  );
};
