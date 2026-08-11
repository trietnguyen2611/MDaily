/**
 * AIChatDrawer Component
 * Context-aware AI Financial Assistant powered by Gemma 2 2B local server.
 * Understands user's exact spending history and provides personalized answers.
 */

import { db } from '../services/db.js';
import { janAI } from '../services/jan-ai.js';

export function renderAIChatDrawer(platform = 'macOS', onClose = null) {
  let chatHistory = [
    {
      sender: 'ai',
      text: `Xin chào! Tôi là **Trợ lý Tài chính Gemma 2 2B (MDaily AI)**. Tôi đã phân tích toàn bộ lịch sử chi tiêu của bạn.\n\nBạn có thể hỏi tôi những câu như:\n• *"Tháng này tôi đã chi bao nhiêu cho Ăn uống?"*\n• *"Tổng chi tiêu hiện tại là bao nhiêu?"*\n• *"Tôi nên cắt giảm chi phí ở khoản nào?"*`,
      timestamp: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
    }
  ];
  let isSending = false;

  const overlay = document.createElement('div');
  overlay.className = 'ai-chat-drawer-overlay';
  overlay.style.cssText = `
    position: fixed; top: 0; left: 0; right: 0; bottom: 0;
    background: rgba(0, 0, 0, 0.4);
    backdrop-filter: blur(12px);
    z-index: 9990;
    display: flex; justify-content: flex-end;
  `;

  function renderContent() {
    overlay.innerHTML = `
      <div class="glass-panel" style="
        width: 100%; max-width: 440px; height: 100%;
        background: rgba(255, 255, 255, 0.94);
        box-shadow: -10px 0 40px rgba(0,0,0,0.2);
        display: flex; flex-direction: column;
        animation: slideInRight 0.3s cubic-bezier(0.16, 1, 0.3, 1);
      ">
        <!-- Header -->
        <div style="
          padding: 16px 20px; border-bottom: 1px solid var(--color-divider-soft);
          display: flex; align-items: center; justify-content: space-between; background: rgba(245,245,247,0.8);
        ">
          <div style="display: flex; align-items: center; gap: 10px;">
            <div style="
              width: 38px; height: 38px; border-radius: 12px; background: var(--color-primary);
              color: #fff; display: flex; align-items: center; justify-content: center;
              box-shadow: 0 4px 12px rgba(0, 102, 204, 0.3);
            ">
              <span class="material-symbols-outlined" style="font-size: 22px;">auto_awesome</span>
            </div>
            <div>
              <h3 style="font-size: 15px; font-weight: 700; color: var(--color-ink);">AI Chatbot Tài Chính</h3>
              <div style="display: flex; align-items: center; gap: 6px; font-size: 11px; color: var(--color-ink-muted-48);">
                <span class="dot-status online" style="width: 6px; height: 6px;"></span> Gemma 2 2B (Jan AI Local)
              </div>
            </div>
          </div>

          <button id="close-chat-btn" style="
            border: none; background: rgba(0,0,0,0.06); width: 30px; height: 30px;
            border-radius: 50%; cursor: pointer; display: flex; align-items: center; justify-content: center;
          ">
            <span class="material-symbols-outlined" style="font-size: 18px;">close</span>
          </button>
        </div>

        <!-- Chat History List -->
        <div id="chat-messages-container" style="
          flex: 1; overflow-y: auto; padding: 20px; display: flex; flex-direction: column; gap: 16px;
        ">
          ${chatHistory
            .map(
              (msg) => `
            <div style="
              display: flex; flex-direction: column;
              align-items: ${msg.sender === 'user' ? 'flex-end' : 'flex-start'};
            ">
              <div style="
                max-width: 85%; padding: 12px 16px; border-radius: 18px; font-size: 13px; line-height: 1.5;
                background: ${msg.sender === 'user' ? 'var(--color-primary)' : '#f0f0f5'};
                color: ${msg.sender === 'user' ? '#ffffff' : 'var(--color-ink)'};
                border-bottom-right-radius: ${msg.sender === 'user' ? '4px' : '18px'};
                border-bottom-left-radius: ${msg.sender === 'ai' ? '4px' : '18px'};
                box-shadow: 0 2px 8px rgba(0,0,0,0.04);
                white-space: pre-wrap;
              ">
                ${msg.text.replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')}
              </div>
              <span style="font-size: 10px; color: var(--color-ink-muted-48); margin-top: 4px; padding: 0 4px;">
                ${msg.timestamp} ${msg.sender === 'ai' ? '• Gemma 2 2B' : ''}
              </span>
            </div>
          `
            )
            .join('')}

          ${
            isSending
              ? `
            <div style="display: flex; align-items: center; gap: 8px; font-size: 12px; color: var(--color-ink-muted-48);">
              <span class="material-symbols-outlined" style="animation: spin 1s linear infinite;">sync</span>
              Gemma 2 2B đang phân tích ngữ cảnh chi tiêu...
            </div>
          `
              : ''
          }
        </div>

        <!-- Quick Questions Chips -->
        <div style="
          padding: 8px 16px; background: #fafafc; border-top: 1px solid var(--color-divider-soft);
          display: flex; gap: 6px; overflow-x: auto;
        ">
          <button class="quick-chip" data-q="Tháng này tôi tiêu bao nhiêu tiền ăn uống?">🍔 Chi ăn uống?</button>
          <button class="quick-chip" data-q="Tổng tất cả chi tiêu của tôi?">💰 Tổng chi tiêu?</button>
          <button class="quick-chip" data-q="Tôi nên tiết kiệm khoản nào nhất?">💡 Lời khuyên tiết kiệm</button>
        </div>

        <!-- Input Bar -->
        <form id="chat-form" style="
          padding: 16px; border-top: 1px solid var(--color-divider-soft); display: flex; gap: 8px; background: #fff;
        ">
          <input type="text" id="chat-input" placeholder="Hỏi AI về ngân sách & chi tiêu..." required style="
            flex: 1; padding: 12px 16px; border-radius: 24px; border: 1px solid rgba(0,0,0,0.12);
            font-size: 13px; outline: none; background: #f8f8fa;
          " />
          <button type="submit" class="btn-primary" style="
            width: 44px; height: 44px; border-radius: 50%; padding: 0; justify-content: center;
          ">
            <span class="material-symbols-outlined" style="font-size: 20px;">send</span>
          </button>
        </form>
      </div>
    `;

    // Scroll chat to bottom
    const container = overlay.querySelector('#chat-messages-container');
    if (container) container.scrollTop = container.scrollHeight;

    // Events
    overlay.querySelector('#close-chat-btn').addEventListener('click', () => {
      overlay.remove();
      if (onClose) onClose();
    });

    const quickChips = overlay.querySelectorAll('.quick-chip');
    quickChips.forEach((chip) => {
      chip.style.cssText = `
        padding: 6px 12px; border-radius: 16px; border: 1px solid rgba(0,0,0,0.08);
        background: #fff; font-size: 11px; font-weight: 500; color: var(--color-ink-muted-80);
        cursor: pointer; white-space: nowrap; transition: all 0.2s ease;
      `;
      chip.addEventListener('click', () => {
        const question = chip.getAttribute('data-q');
        sendMessage(question);
      });
    });

    const form = overlay.querySelector('#chat-form');
    form.addEventListener('submit', (e) => {
      e.preventDefault();
      const input = overlay.querySelector('#chat-input');
      const val = input.value.trim();
      if (val) {
        sendMessage(val);
        input.value = '';
      }
    });
  }

  async function sendMessage(text) {
    const timeStr = new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
    chatHistory.push({ sender: 'user', text, timestamp: timeStr });
    isSending = true;
    renderContent();

    // Fetch user expenses context
    const expenses = db.getExpenses();
    const response = await janAI.chatWithAI(text, expenses, chatHistory);

    chatHistory.push({
      sender: 'ai',
      text: response.text,
      timestamp: new Date().toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' })
    });
    isSending = false;
    renderContent();
  }

  renderContent();
  document.body.appendChild(overlay);
}
