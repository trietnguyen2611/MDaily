/**
 * Jan AI & Gemma 2 2B Local Integration Service
 * Connects to Jan AI local API server running Gemma 2 2B model on macOS Intel.
 * Configured at http://localhost:1337/v1
 */

import { db } from './db.js';

export const janAI = {
  /**
   * Check connection status of Jan AI Local Server
   */
  async checkConnection() {
    const config = db.getJanConfig();
    const endpoint = config.endpoint || 'http://localhost:1337/v1';

    try {
      const controller = new AbortController();
      const timeoutId = setTimeout(() => controller.abort(), 2000);

      const res = await fetch(`${endpoint}/models`, {
        method: 'GET',
        signal: controller.signal
      });
      clearTimeout(timeoutId);

      if (res.ok) {
        return { online: true, message: 'Đã kết nối Jan AI (Gemma 2 2B local)' };
      }
      return { online: false, message: 'Server Jan AI không phản hồi HTTP 200' };
    } catch (err) {
      return {
        online: false,
        message: 'Không kết nối được Jan AI tại ' + endpoint + '. Đang chạy ở chế độ AI Heuristic Local.'
      };
    }
  },

  /**
   * Call Jan AI Chat Completion API
   */
  async callAPI(messages, systemPrompt = '') {
    const config = db.getJanConfig();
    const endpoint = config.endpoint || 'http://localhost:1337/v1';
    const model = config.model || 'gemma-2-2b-it';

    const fullMessages = [];
    if (systemPrompt) {
      fullMessages.push({ role: 'system', content: systemPrompt });
    }
    fullMessages.push(...messages);

    try {
      const res = await fetch(`${endpoint}/chat/completions`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          model: model,
          messages: fullMessages,
          temperature: 0.3,
          max_tokens: 600
        })
      });

      if (!res.ok) {
        throw new Error(`HTTP error ${res.status}`);
      }

      const data = await res.json();
      return data.choices[0]?.message?.content || '';
    } catch (error) {
      console.warn('Jan AI server connection failed, switching to local AI heuristic mode:', error);
      return null;
    }
  },

  /**
   * AI Feature 1: Receipt Auto-Parsing (*có sử dụng AI - Gemma 2 2B)
   */
  async parseReceiptWithAI(rawText) {
    const systemPrompt = `Bạn là mô hình trí tuệ nhân tạo Gemma 2 2B chuyên phân tích hoá đơn mua hàng.
Nhiệm vụ: Trích xuất thông tin hoá đơn từ đoạn văn bản thô và trả về DUY NHẤT một chuỗi định dạng JSON hợp lệ (không kèm theo văn bản giải thích nào khác).

JSON schema bắt buộc:
{
  "merchant": "Tên cửa hàng / thương hiệu",
  "amount": 150000, // Số tiền tổng dạng số nguyên
  "category": "Hoá đơn" | "Mua sắm" | "Ăn uống" | "Di chuyển",
  "date": "YYYY-MM-DD",
  "items": "Tóm tắt các món hàng mua"
}`;

    const messages = [{ role: 'user', content: `Đoạn văn bản hoá đơn OCR:\n"""\n${rawText}\n"""` }];

    const aiResult = await this.callAPI(messages, systemPrompt);

    if (aiResult) {
      try {
        const jsonMatch = aiResult.match(/\{[\s\S]*\}/);
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[0]);
          return {
            merchant: parsed.merchant || 'Cửa hàng / Hoá đơn',
            amount: Number(parsed.amount) || 120000,
            category: ['Hoá đơn', 'Mua sắm', 'Ăn uống', 'Di chuyển'].includes(parsed.category)
              ? parsed.category
              : 'Hoá đơn',
            date: parsed.date || new Date().toISOString().split('T')[0],
            items: parsed.items || 'Thanh toán hoá đơn',
            isAIPowered: true
          };
        }
      } catch (e) {
        console.error('Lỗi parse JSON từ Jan AI:', e);
      }
    }

    // Fallback Heuristic Parsing if Jan AI server is offline or returned bad JSON
    return this.fallbackParseReceipt(rawText);
  },

  /**
   * Fallback Heuristic parser for receipts
   */
  fallbackParseReceipt(text) {
    const numbers = text.match(/\d+[\d\.,]*/g) || [];
    let maxAmount = 0;
    numbers.forEach((numStr) => {
      const cleanNum = parseInt(numStr.replace(/[\.,]/g, ''), 10);
      if (cleanNum > maxAmount && cleanNum < 50000000) {
        maxAmount = cleanNum;
      }
    });

    if (maxAmount === 0) maxAmount = 145000;

    let category = 'Hoá đơn';
    const lower = text.toLowerCase();
    if (lower.includes('cà phê') || lower.includes('trà') || lower.includes('phở') || lower.includes('bún') || lower.includes('nhà hàng') || lower.includes('com')) {
      category = 'Ăn uống';
    } else if (lower.includes('supermarket') || lower.includes('winmart') || lower.includes('coop') || lower.includes('quần áo') || lower.includes('shopee')) {
      category = 'Mua sắm';
    } else if (lower.includes('grab') || lower.includes('be') || lower.includes('xăng') || lower.includes('tài xế')) {
      category = 'Di chuyển';
    }

    const lines = text.split('\n').map((l) => l.trim()).filter((l) => l.length > 2);
    const merchant = lines[0] || 'Hoá đơn dịch vụ';

    return {
      merchant,
      amount: maxAmount,
      category,
      date: new Date().toISOString().split('T')[0],
      items: lines.slice(1, 4).join(', ') || 'Thực phẩm / Dịch vụ',
      isAIPowered: false
    };
  },

  /**
   * AI Feature 2: Smart Object Tagging (*có sử dụng AI)
   */
  async suggestObjectCategory(titleStr) {
    const systemPrompt = `Bạn là trợ lý tài chính AI Gemma 2 2B. Khi người dùng nhập tên đồ vật vừa mua, hãy chọn danh mục phù hợp nhất từ 4 danh mục: "Hoá đơn", "Mua sắm", "Ăn uống", "Di chuyển". Trả về JSON: {"category": "..."}`;

    const res = await this.callAPI([{ role: 'user', content: `Đồ vật: ${titleStr}` }], systemPrompt);
    if (res) {
      try {
        const json = JSON.parse(res.match(/\{[\s\S]*\}/)[0]);
        if (json.category) return json.category;
      } catch (e) {}
    }

    // Heuristic fallback
    const t = titleStr.toLowerCase();
    if (t.includes('cà phê') || t.includes('bánh') || t.includes('trà') || t.includes('cơm') || t.includes('nước') || t.includes('ăn')) return 'Ăn uống';
    if (t.includes('xe') || t.includes('xăng') || t.includes('grab') || t.includes('vé') || t.includes('bus')) return 'Di chuyển';
    if (t.includes('điện') || t.includes('nước') || t.includes('mạng') || t.includes('wifi') || t.includes('tiền')) return 'Hoá đơn';
    return 'Mua sắm';
  },

  /**
   * AI Feature 3: Context-aware Financial Chatbot (*có sử dụng AI - Gemma 2 2B)
   */
  async chatWithAI(userQuery, userExpenses, chatHistory = []) {
    const currentUser = db.getCurrentUser();

    // Compute spending context statistics
    const totalSpent = userExpenses.reduce((sum, e) => sum + e.amount, 0);
    const categoryTotals = {
      'Hoá đơn': 0,
      'Mua sắm': 0,
      'Ăn uống': 0,
      'Di chuyển': 0
    };

    userExpenses.forEach((e) => {
      if (categoryTotals[e.category] !== undefined) {
        categoryTotals[e.category] += e.amount;
      }
    });

    const recentList = userExpenses
      .slice(0, 5)
      .map((e) => `- ${e.title} (${e.category}): ${e.amount.toLocaleString('vi-VN')} VNĐ vào ${new Date(e.date).toLocaleDateString('vi-VN')}`)
      .join('\n');

    const systemPrompt = `Bạn là trợ lý tài chính cá nhân thông minh MDaily powered by Gemma 2 2B running local on Mac Intel.
Bạn đang giao tiếp trực tiếp với người dùng: "${currentUser.name}" (${currentUser.email}).

NGỮ CẢNH DỮ LIỆU CHI TIÊU CỦA ${currentUser.name.toUpperCase()}:
- Tổng số tiền đã chi tiêu: ${totalSpent.toLocaleString('vi-VN')} VNĐ
- Chi tiết theo danh mục:
  + Hoá đơn: ${categoryTotals['Hoá đơn'].toLocaleString('vi-VN')} VNĐ
  + Mua sắm: ${categoryTotals['Mua sắm'].toLocaleString('vi-VN')} VNĐ
  + Ăn uống: ${categoryTotals['Ăn uống'].toLocaleString('vi-VN')} VNĐ
  + Di chuyển: ${categoryTotals['Di chuyển'].toLocaleString('vi-VN')} VNĐ
- 5 Giao dịch gần nhất:
${recentList || '(Chưa có giao dịch nào)'}

Yêu cầu trả lời:
- Trả lời bằng tiếng Việt thân thiện, lịch sự và súc tích.
- Trích dẫn đúng số liệu thống kê ở trên để trả lời thắc mắc của người dùng.
- Đưa ra lời khuyên cá nhân hoá về cách tối ưu chi tiêu hoặc tiết kiệm dựa trên dữ liệu thật của họ.`;

    const formattedMessages = chatHistory.map((h) => ({
      role: h.sender === 'user' ? 'user' : 'assistant',
      content: h.text
    }));

    formattedMessages.push({ role: 'user', content: userQuery });

    const aiReply = await this.callAPI(formattedMessages, systemPrompt);

    if (aiReply) {
      return { text: aiReply, isAI: true };
    }

    // Smart Local Heuristic Chatbot Fallback if Gemma 2 2B server is not currently reachable
    return this.fallbackChatResponse(userQuery, totalSpent, categoryTotals, currentUser.name);
  }

  /**
   * Fallback Financial Assistant response generator
   */
  fallbackChatResponse(query, totalSpent, categoryTotals, userName) {
    const q = query.toLowerCase();

    if (q.includes('tổng') || q.includes('bao nhiêu') || q.includes('tất cả')) {
      return {
        text: `Chào ${userName}, tổng chi tiêu của bạn hiện tại là **${totalSpent.toLocaleString('vi-VN')} VNĐ**.\n\nPhân rã theo danh mục:\n• 📄 Hoá đơn: ${categoryTotals['Hoá đơn'].toLocaleString('vi-VN')} VNĐ\n• 🛍️ Mua sắm: ${categoryTotals['Mua sắm'].toLocaleString('vi-VN')} VNĐ\n• 🍔 Ăn uống: ${categoryTotals['Ăn uống'].toLocaleString('vi-VN')} VNĐ\n• 🚗 Di chuyển: ${categoryTotals['Di chuyển'].toLocaleString('vi-VN')} VNĐ`,
        isAI: false
      };
    }

    if (q.includes('ăn uống') || q.includes('cà phê') || q.includes('ăn')) {
      return {
        text: `Khoản chi cho **Ăn uống** của bạn là **${categoryTotals['Ăn uống'].toLocaleString('vi-VN')} VNĐ**. Mẹo: Bạn có thể chuẩn bị bữa sáng tại nhà để tiết kiệm khoảng 20-30% chi phí này nhé!`,
        isAI: false
      };
    }

    if (q.includes('tiết kiệm') || q.includes('khuyên') || q.includes('tối ưu')) {
      const topCat = Object.keys(categoryTotals).reduce((a, b) => (categoryTotals[a] > categoryTotals[b] ? a : b));
      return {
        text: `Dựa trên phân tích, danh mục bạn đang chi tiêu nhiều nhất là **${topCat}** (${categoryTotals[topCat].toLocaleString('vi-VN')} VNĐ).\n\n💡 **Lời khuyên từ MDaily:** Hãy đặt hạn mức ngân sách cố định hàng tuần cho danh mục ${topCat} và theo dõi qua ứng dụng mỗi ngày!`,
        isAI: false
      };
    }

    return {
      text: `Dữ liệu của ${userName}:\nTổng chi tiêu: **${totalSpent.toLocaleString('vi-VN')} VNĐ**.\nDanh mục cao nhất: **Ăn uống / Mua sắm**. (Lưu ý: Mở Jan AI trên Mac để kích hoạt Gemma 2 2B phản hồi tự nhiên hơn).`,
      isAI: false
    };
  }
};
