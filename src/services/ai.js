/* ============================================================
   MDaily — AI Service
   Connects to JAN AI local server (Gemma 2 2B)
   OpenAI-compatible API at http://127.0.0.1:1337/v1
   ============================================================ */

const JAN_API_BASE = 'http://127.0.0.1:1337/v1';
const MODEL_ID = 'gemma-2-2b-it';

/**
 * Check if JAN AI server is available
 * @returns {Promise<boolean>}
 */
export async function isAIAvailable() {
  try {
    const response = await fetch(`${JAN_API_BASE}/models`, {
      method: 'GET',
      signal: AbortSignal.timeout(3000)
    });
    return response.ok;
  } catch {
    return false;
  }
}

/**
 * Send a chat completion request to JAN AI
 * @param {Array<{role: string, content: string}>} messages
 * @param {Object} options
 * @returns {Promise<string>} - AI response text
 */
async function chatCompletion(messages, options = {}) {
  const response = await fetch(`${JAN_API_BASE}/chat/completions`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      model: MODEL_ID,
      messages,
      temperature: options.temperature || 0.7,
      max_tokens: options.maxTokens || 1024,
      stream: false
    })
  });

  if (!response.ok) {
    const errorText = await response.text();
    throw new Error(`AI API Error (${response.status}): ${errorText}`);
  }

  const data = await response.json();
  return data.choices[0]?.message?.content || '';
}

/**
 * Analyze receipt text extracted via OCR
 * Returns structured data: items, prices, total, suggested category
 * @param {string} ocrText - Raw text from OCR
 * @returns {Promise<Object>} - { items: [{name, price}], total, category }
 */
export async function analyzeReceipt(ocrText) {
  const systemPrompt = `Bạn là trợ lý AI phân tích hóa đơn. Nhiệm vụ của bạn là trích xuất thông tin từ text hóa đơn đã được OCR.

Hãy trả về kết quả dưới dạng JSON với format sau:
{
  "items": [{"name": "tên sản phẩm", "price": số_tiền}],
  "total": tổng_tiền,
  "category": "danh_mục",
  "description": "mô tả ngắn"
}

Các danh mục hợp lệ: "bills" (hoá đơn điện/nước/internet), "shopping" (mua sắm), "food" (ăn uống), "transport" (di chuyển/xăng/giao thông).

Lưu ý:
- Giá tiền tính bằng VNĐ
- Nếu không rõ danh mục, chọn danh mục phù hợp nhất
- Nếu không đọc được giá, để giá = 0
- CHỈ trả về JSON, không giải thích thêm`;

  const messages = [
    { role: 'system', content: systemPrompt },
    { role: 'user', content: `Phân tích hóa đơn sau:\n\n${ocrText}` }
  ];

  try {
    const response = await chatCompletion(messages, { temperature: 0.3 });

    // Extract JSON from response
    const jsonMatch = response.match(/\{[\s\S]*\}/);
    if (jsonMatch) {
      const parsed = JSON.parse(jsonMatch[0]);
      return {
        items: parsed.items || [],
        total: parsed.total || 0,
        category: parsed.category || 'shopping',
        description: parsed.description || 'Hóa đơn',
        raw: response
      };
    }

    // Fallback if JSON not found
    return {
      items: [],
      total: 0,
      category: 'shopping',
      description: 'Không thể phân tích hóa đơn',
      raw: response
    };
  } catch (error) {
    console.error('AI receipt analysis error:', error);
    throw error;
  }
}

/**
 * Chat with AI about expenses
 * The AI has context about the user's spending patterns
 * @param {string} userMessage - User's question
 * @param {string} expenseContext - Summary of user's expenses (from db.getExpenseContext())
 * @param {Array<{role: string, content: string}>} history - Previous chat messages
 * @returns {Promise<string>} - AI response
 */
export async function chat(userMessage, expenseContext, history = []) {
  const systemPrompt = `Bạn là MDaily AI, trợ lý quản lý chi tiêu cá nhân thông minh. Bạn luôn trả lời bằng tiếng Việt, thân thiện và hữu ích.

Bạn có quyền truy cập vào dữ liệu chi tiêu cá nhân của người dùng. Dùng thông tin này để trả lời câu hỏi một cách cá nhân hóa.

${expenseContext}

Hướng dẫn:
- Trả lời ngắn gọn, dễ hiểu
- Đưa ra lời khuyên thiết thực về quản lý chi tiêu khi phù hợp
- Sử dụng emoji phù hợp để tạo cảm giác thân thiện
- Khi được hỏi về chi tiêu, sử dụng dữ liệu thực tế từ context
- Nếu không có dữ liệu, hãy gợi ý người dùng bắt đầu ghi nhận chi tiêu
- Đơn vị tiền tệ: VNĐ`;

  const messages = [
    { role: 'system', content: systemPrompt },
    ...history.slice(-10), // Keep last 10 messages for context window
    { role: 'user', content: userMessage }
  ];

  try {
    return await chatCompletion(messages, { temperature: 0.7, maxTokens: 512 });
  } catch (error) {
    console.error('AI chat error:', error);
    throw error;
  }
}
