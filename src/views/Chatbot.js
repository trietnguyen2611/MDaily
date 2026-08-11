/* ============================================================
   MDaily — Chatbot View
   AI chatbot with expense context awareness
   ============================================================ */

import { chat, isAIAvailable } from '../services/ai.js';
import { getExpenseContext, saveChatMessage, getChatHistory, clearChatHistory } from '../services/db.js';
import { formatTime } from '../utils/format.js';

export default async function ChatbotView() {
  const element = document.createElement('div');
  element.className = 'view';
  element.style.padding = '0';
  element.style.paddingBottom = '0';

  // Load chat history
  const history = await getChatHistory();
  const aiAvailable = await isAIAvailable();

  element.innerHTML = `
    <div class="chat-container">
      <!-- Chat Header -->
      <div style="padding: var(--space-lg) var(--space-md) var(--space-sm); background: rgba(255,255,255,0.9); backdrop-filter: var(--backdrop-blur); -webkit-backdrop-filter: var(--backdrop-blur); border-bottom: 1px solid var(--color-hairline); display: flex; align-items: center; justify-content: space-between;">
        <div>
          <h1 style="font-size: 21px; font-weight: 600;">MDaily AI</h1>
          <p class="text-caption" style="color: ${aiAvailable ? 'var(--color-cat-food)' : '#ef4444'};">
            ${aiAvailable ? '🟢 Gemma 2 2B · Sẵn sàng' : '🔴 JAN AI chưa chạy'}
          </p>
        </div>
        <button class="btn-icon" id="clear-chat-btn" title="Xoá lịch sử">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <polyline points="3 6 5 6 21 6"/>
            <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
          </svg>
        </button>
      </div>

      <!-- Messages -->
      <div class="chat-messages" id="chat-messages">
        ${history.length === 0 ? `
          <!-- Welcome Message -->
          <div class="chat-bubble chat-bubble--ai">
            <p>Xin chào! 👋 Tôi là MDaily AI, trợ lý quản lý chi tiêu của bạn.</p>
            <p style="margin-top: 8px;">Bạn có thể hỏi tôi về chi tiêu, ví dụ:</p>
            <ul style="margin-top: 4px; padding-left: 16px; font-size: 14px; color: var(--color-ink-muted-80);">
              <li>"Tháng này mình tiêu bao nhiêu?"</li>
              <li>"Danh mục nào tốn kém nhất?"</li>
              <li>"Cho lời khuyên tiết kiệm"</li>
            </ul>
          </div>
        ` : history.map(msg => `
          <div class="chat-bubble chat-bubble--${msg.role === 'user' ? 'user' : 'ai'}">
            ${msg.content}
            <div class="chat-bubble__time">${formatTime(msg.createdAt)}</div>
          </div>
        `).join('')}
      </div>

      <!-- Quick Suggestions -->
      <div class="quick-suggestions" id="quick-suggestions">
        <button class="quick-suggestion">💰 Tháng này tiêu bao nhiêu?</button>
        <button class="quick-suggestion">📊 Danh mục nào tốn nhất?</button>
        <button class="quick-suggestion">📈 So với tháng trước?</button>
        <button class="quick-suggestion">💡 Lời khuyên tiết kiệm</button>
      </div>

      <!-- Input Bar -->
      <div class="chat-input-bar">
        <input type="text" class="chat-input" id="chat-input"
               placeholder="Hỏi về chi tiêu của bạn..."
               ${!aiAvailable ? 'disabled' : ''}>
        <button class="chat-send-btn" id="send-btn" disabled>
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2">
            <line x1="22" y1="2" x2="11" y2="13"/>
            <polygon points="22 2 15 22 11 13 2 9 22 2"/>
          </svg>
        </button>
      </div>
    </div>
  `;

  function setup() {
    const messagesContainer = element.querySelector('#chat-messages');
    const chatInput = element.querySelector('#chat-input');
    const sendBtn = element.querySelector('#send-btn');
    const clearBtn = element.querySelector('#clear-chat-btn');
    const suggestions = element.querySelector('#quick-suggestions');

    let isProcessing = false;
    let chatHistoryForContext = history.map(h => ({ role: h.role, content: h.content }));

    // Scroll to bottom
    function scrollToBottom() {
      messagesContainer.scrollTop = messagesContainer.scrollHeight;
    }
    scrollToBottom();

    // Update send button
    function updateSendBtn() {
      sendBtn.disabled = !chatInput.value.trim() || isProcessing || !aiAvailable;
    }

    chatInput.addEventListener('input', updateSendBtn);

    // Send message
    async function sendMessage(text) {
      if (!text.trim() || isProcessing || !aiAvailable) return;

      isProcessing = true;
      const userText = text.trim();
      chatInput.value = '';
      updateSendBtn();

      // Hide suggestions after first message
      suggestions.style.display = 'none';

      // Add user bubble
      const userBubble = document.createElement('div');
      userBubble.className = 'chat-bubble chat-bubble--user';
      userBubble.innerHTML = `${escapeHtml(userText)}<div class="chat-bubble__time">${formatTime(new Date().toISOString())}</div>`;
      messagesContainer.appendChild(userBubble);
      scrollToBottom();

      // Save user message
      await saveChatMessage({ role: 'user', content: userText });

      // Show typing indicator
      const typingEl = document.createElement('div');
      typingEl.className = 'chat-typing';
      typingEl.innerHTML = `
        <div class="chat-typing__dot"></div>
        <div class="chat-typing__dot"></div>
        <div class="chat-typing__dot"></div>
      `;
      messagesContainer.appendChild(typingEl);
      scrollToBottom();

      try {
        // Get expense context
        const context = await getExpenseContext();

        // Send to AI
        const response = await chat(userText, context, chatHistoryForContext);

        // Remove typing indicator
        typingEl.remove();

        // Add AI bubble
        const aiBubble = document.createElement('div');
        aiBubble.className = 'chat-bubble chat-bubble--ai';
        aiBubble.innerHTML = `${formatAIResponse(response)}<div class="chat-bubble__time">${formatTime(new Date().toISOString())}</div>`;
        messagesContainer.appendChild(aiBubble);
        scrollToBottom();

        // Save AI message
        await saveChatMessage({ role: 'assistant', content: response });

        // Update context history
        chatHistoryForContext.push(
          { role: 'user', content: userText },
          { role: 'assistant', content: response }
        );

      } catch (error) {
        typingEl.remove();

        const errorBubble = document.createElement('div');
        errorBubble.className = 'chat-bubble chat-bubble--ai';
        errorBubble.innerHTML = `
          <p style="color: #ef4444;">❌ Không thể kết nối AI</p>
          <p class="text-caption" style="margin-top: 4px; color: var(--color-ink-muted-48);">
            Kiểm tra JAN AI đang chạy và model Gemma 2 2B đã được tải.
          </p>
        `;
        messagesContainer.appendChild(errorBubble);
        scrollToBottom();
      }

      isProcessing = false;
      updateSendBtn();
    }

    // Send button click
    sendBtn.addEventListener('click', () => sendMessage(chatInput.value));

    // Enter key
    chatInput.addEventListener('keydown', (e) => {
      if (e.key === 'Enter' && !e.shiftKey) {
        e.preventDefault();
        sendMessage(chatInput.value);
      }
    });

    // Quick suggestions
    element.querySelectorAll('.quick-suggestion').forEach(btn => {
      btn.addEventListener('click', () => {
        sendMessage(btn.textContent.trim());
      });
    });

    // Clear chat
    clearBtn.addEventListener('click', async () => {
      await clearChatHistory();
      chatHistoryForContext = [];
      messagesContainer.innerHTML = `
        <div class="chat-bubble chat-bubble--ai">
          <p>Lịch sử đã được xoá! 🧹</p>
          <p style="margin-top: 4px;">Hãy hỏi tôi bất cứ điều gì về chi tiêu của bạn.</p>
        </div>
      `;
      suggestions.style.display = 'flex';
    });

    // Focus input
    if (aiAvailable) {
      chatInput.focus();
    }
  }

  return { element, setup };
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function formatAIResponse(text) {
  // Basic markdown-like formatting
  return text
    .replace(/\*\*(.*?)\*\*/g, '<strong>$1</strong>')
    .replace(/\*(.*?)\*/g, '<em>$1</em>')
    .replace(/\n/g, '<br>');
}
