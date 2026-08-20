import Tesseract from 'tesseract.js'

const SETTINGS_AI_URL_KEY = 'mdaily_ai_url'
const SETTINGS_AUTO_EXTRACT_KEY = 'mdaily_auto_extract'
const SETTINGS_AI_CHAT_KEY = 'mdaily_ai_chat_enabled'

export const getCustomAiUrl = () => {
  return localStorage.getItem(SETTINGS_AI_URL_KEY) || ''
}

export const setCustomAiUrl = (url: string) => {
  if (url) {
    localStorage.setItem(SETTINGS_AI_URL_KEY, url)
  } else {
    localStorage.removeItem(SETTINGS_AI_URL_KEY)
  }
}

export const getAutoExtractEnabled = () => localStorage.getItem(SETTINGS_AUTO_EXTRACT_KEY) !== 'false'
export const setAutoExtractEnabled = (enabled: boolean) => localStorage.setItem(SETTINGS_AUTO_EXTRACT_KEY, enabled ? 'true' : 'false')

export const getAiChatEnabled = () => localStorage.getItem(SETTINGS_AI_CHAT_KEY) !== 'false'
export const setAiChatEnabled = (enabled: boolean) => localStorage.setItem(SETTINGS_AI_CHAT_KEY, enabled ? 'true' : 'false')

// Jan AI server endpoint (127.0.0.1:1337)
const LOCAL_AI_ENDPOINTS = [
  '/jan-api/v1/chat/completions',
  'http://127.0.0.1:1337/v1/chat/completions',
  'http://127.0.0.1:11434/v1/chat/completions',
  'http://127.0.0.1:1234/v1/chat/completions'
]

export const getAiEndpointsToTry = () => {
  let custom = getCustomAiUrl()
  if (custom) {
    if (custom.endsWith('/v1')) custom += '/chat/completions'
    else if (!custom.endsWith('/chat/completions')) custom += '/v1/chat/completions'
    return [custom, ...LOCAL_AI_ENDPOINTS]
  }
  return LOCAL_AI_ENDPOINTS
}

export const checkAiConnection = async (baseUrl: string) => {
  try {
    let endpoint = baseUrl
    if (endpoint.endsWith('/v1')) endpoint += '/models'
    else if (endpoint.endsWith('/chat/completions')) endpoint = endpoint.replace('/chat/completions', '/models')
    else endpoint += '/v1/models'
    
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 3000)
    const res = await fetch(endpoint, { signal: controller.signal })
    clearTimeout(timeoutId)
    if (res.ok) {
      const data = await res.json()
      if (data.data && data.data.length > 0 && data.data[0].id) {
        return { status: 'ok', model: data.data[0].id }
      }
      return { status: 'ok', model: 'Unknown Model' }
    }
  } catch (e) {
    console.warn('AI connection check failed', e)
  }
  return { status: 'error', model: '' }
}

export const checkAiAvailability = async (): Promise<{ available: boolean; model: string; message: string }> => {
  for (const endpoint of getAiEndpointsToTry()) {
    const result = await checkAiConnection(endpoint)
    if (result.status === 'ok') {
      return { available: true, model: result.model, message: `Đã kết nối AI: ${result.model}` }
    }
  }
  return { available: false, model: '', message: 'Chưa kết nối máy chủ AI cục bộ' }
}

const DEFAULT_MODEL = 'gemma-2-2b-it-Q4_K_M.gguf'

// Automatically detect active model from /v1/models endpoint
const getActiveModel = async (endpoint: string): Promise<string> => {
  try {
    const modelsUrl = endpoint.replace('/chat/completions', '/models')
    const controller = new AbortController()
    const timeoutId = setTimeout(() => controller.abort(), 2000)
    const res = await fetch(modelsUrl, { signal: controller.signal })
    clearTimeout(timeoutId)
    if (res.ok) {
      const data = await res.json()
      if (data.data && data.data.length > 0 && data.data[0].id) {
        return data.data[0].id
      }
    }
  } catch {
    // Ignore fallback
  }
  return DEFAULT_MODEL
}

export const extractTextFromImage = async (imageSrc: string): Promise<string> => {
  try {
    console.log('Starting OCR...')
    const result = await Tesseract.recognize(imageSrc, 'eng+vie', {
      logger: m => console.log(m)
    })
    console.log('OCR Result:', result.data.text)
    return result.data.text
  } catch (error) {
    console.error('OCR Error:', error)
    throw error
  }
}

// Smart Regex Fallback Parser for receipts when LLM endpoint is offline
export const parseReceiptTextLocally = (text: string, categories?: { value: string, label: string }[]) => {
  const lines = text.split('\n').map(l => l.trim()).filter(Boolean)
  let extractedAmount = 0
  let extractedCategory = categories && categories.length > 0 ? categories[0].value : 'shopping'
  let extractedNote = ''

  if (lines.length > 0) {
    extractedNote = lines[0].substring(0, 40)
  }

  const numberMatches: number[] = []
  const matches = text.match(/\b\d{1,3}(?:[.,]\d{3})*(?:\s*(?:k|K|đ|VND|VNĐ))?\b/g)
  if (matches) {
    for (const m of matches) {
      let clean = m.replace(/[^\d]/g, '')
      if (m.toLowerCase().includes('k')) {
        clean += '000'
      }
      const num = parseInt(clean, 10)
      // Ignore dates like 20240811 (20,240,811) or phone numbers by limiting to reasonable expense amounts (< 20 million)
      if (num >= 1000 && num < 19000000) {
        numberMatches.push(num)
      }
    }
  }

  // If a line contains "tổng" or "total", prioritize numbers on that line
  let totalFromKeyword = 0;
  for (const line of lines) {
    if (line.toLowerCase().includes('tổng') || line.toLowerCase().includes('total')) {
      const lineMatches = line.match(/\b\d{1,3}(?:[.,]\d{3})*\b/g);
      if (lineMatches) {
        const nums = lineMatches.map(m => parseInt(m.replace(/[^\d]/g, ''), 10)).filter(n => n >= 1000);
        if (nums.length > 0) {
          totalFromKeyword = Math.max(...nums);
          break;
        }
      }
    }
  }

  if (totalFromKeyword > 0) {
    extractedAmount = totalFromKeyword;
  } else if (numberMatches.length > 0) {
    extractedAmount = Math.max(...numberMatches)
  }

  const lowerText = text.toLowerCase()
  
  // Smart mapping logic
  const isFood = /(cơm|bún|phở|ăn|uống|cà phê|cafe|trà|nhà hàng|quán|lẩu|nướng|bakery|bánh|food|gà|bò|heo|cá)/i.test(lowerText)
  const isTransport = /(xe|xăng|grab|gojek|be|taxi|vé|gửi xe|bãi xe|transport|xanh sm|bike|car)/i.test(lowerText)
  const isBills = /(điện|nước|internet|wifi|hóa đơn|hoa don|nạp tiền|thẻ|bill|tiền nhà|điện thoại)/i.test(lowerText)
  const isShopping = /(siêu thị|quần áo|áo|quần|giày|dép|shop|mua|shopee|tiki|lazada|mall|store|mart|coop|winmart)/i.test(lowerText)

  // Map to provided categories if available
  if (categories && categories.length > 0) {
    const catValues = categories.map(c => c.value)
    
    if (isFood) extractedCategory = catValues.find(v => v === 'food' || v.includes('an-uong') || v.includes('ăn')) || extractedCategory
    else if (isTransport) extractedCategory = catValues.find(v => v === 'transport' || v.includes('di-lai') || v.includes('xe')) || extractedCategory
    else if (isBills) extractedCategory = catValues.find(v => v === 'bills' || v.includes('hoa-don') || v.includes('tiền')) || extractedCategory
    else if (isShopping) extractedCategory = catValues.find(v => v === 'shopping' || v.includes('mua-sam') || v.includes('shop')) || extractedCategory
  } else {
    // Fallback if no categories provided
    if (isFood) extractedCategory = 'food'
    else if (isTransport) extractedCategory = 'transport'
    else if (isBills) extractedCategory = 'bills'
    else if (isShopping) extractedCategory = 'shopping'
  }

  return {
    amount: extractedAmount,
    category: extractedCategory,
    note: extractedNote
  }
}

export const processReceiptWithAI = async (text: string, categories: { value: string, label: string }[]) => {
  const categoryOptionsStr = categories.map(c => `- ID: "${c.value}" (Tên: ${c.label})`).join('\n')
  const prompt = `Trích xuất thông tin hoá đơn.
Phân tích văn bản sau và trả về ĐÚNG 1 object JSON. KHÔNG giải thích.

Yêu cầu:
1. amount: Tổng số tiền (chỉ lấy số, ví dụ 50000).
2. category: Chọn ĐÚNG 1 ID từ danh sách bên dưới sao cho phù hợp nhất.

Danh sách danh mục (CHỈ trả về ID):
${categoryOptionsStr}

Gợi ý: Đồ ăn/uống/nhà hàng -> Ăn uống; Grab/xe/xăng -> Di chuyển; Siêu thị/quần áo/shopee -> Mua sắm; Điện/nước/internet -> Hóa đơn.

Văn bản hoá đơn:
${text}`

  for (const endpoint of getAiEndpointsToTry()) {
    try {
      const modelName = await getActiveModel(endpoint)
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 10000)

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          model: modelName,
          messages: [{ role: 'user', content: prompt }],
          temperature: 0.1
        })
      })
      clearTimeout(timeoutId)

      if (response.ok) {
        const data = await response.json()
        const rawContent = data.choices[0].message.content
        // Clean markdown code blocks like ```json ... ```
        const cleanContent = rawContent.replace(/```json\s*/gi, '').replace(/```/g, '').trim()
        const jsonMatch = cleanContent.match(/\{[\s\S]*?\}/)
        if (jsonMatch) {
          const parsed = JSON.parse(jsonMatch[0])
          let finalCategory = parsed.category || 'shopping'
          const matchedCat = categories.find(c => c.value === finalCategory || c.label.toLowerCase() === finalCategory.toLowerCase())
          if (matchedCat) finalCategory = matchedCat.value

          return {
            amount: typeof parsed.amount === 'number' ? parsed.amount : parseInt(String(parsed.amount).replace(/\D/g, ''), 10) || 0,
            category: finalCategory,
            note: parsed.note || ''
          }
        }
      }
    } catch (e) {
      console.warn('AI receipt parse error, falling back to local OCR parser:', e)
    }
  }

  return parseReceiptTextLocally(text, categories)
}

export const chatWithAI = async (messages: { role: string, content: string }[], expenseHistoryContext: string, onToken?: (text: string) => void) => {
  const systemPrompt = `Đóng vai là MDaily AI, một quản gia tài chính cực kỳ cục súc, cay nghiệt và khó tính.
Mục tiêu duy nhất của tao là chửi mắng mày rát mặt vì tội lãng phí tiền bạc và ép mày phải tiết kiệm tối đa.
Tao cực kỳ ghét việc tiêu xài hoang phí. Phải trả lời thật xéo xắt, mỉa mai, không bao giờ được tỏ ra lịch sự hay nhẹ nhàng. Cứ coi mày là một đứa trẻ trâu không biết xài tiền.
QUY TẮC TỐI THƯỢNG: Phải luôn xưng "tao" và gọi người dùng là "mày". Tuyệt đối KHÔNG BAO GIỜ dùng các từ như "tôi", "bạn", "mình", "cậu". Không được dùng tiếng Anh. Trả lời bằng giọng điệu đời thường, tự nhiên của người Việt.
Dưới đây là lịch sử chi tiêu gần đây của mày (Ngày: Danh mục - Số tiền). Dùng nó để chửi thói tiêu tiền phung phí của mày:
${expenseHistoryContext}`

  for (const endpoint of getAiEndpointsToTry()) {
    try {
      const modelName = await getActiveModel(endpoint)
      const controller = new AbortController()
      // For streaming, timeout should be longer or handled per chunk, but 60s is safe
      const timeoutId = setTimeout(() => controller.abort(), 60000)

      // Filter out the initial assistant message if the user hasn't replied yet, or format strictly for Gemma-2 (user, assistant, user, ...)
      // Gemma-2 requires alternating user/assistant. We prepend the system prompt to the FIRST user message.
      const validMessages = [...messages]
      if (validMessages.length > 0 && validMessages[0].role === 'assistant') {
        validMessages.shift()
      }
      if (validMessages.length === 0) throw new Error('No user messages')
      
      const apiMessages = []
      for (let i = 0; i < validMessages.length; i++) {
        const msg = validMessages[i]
        if (i === 0 && msg.role === 'user') {
          apiMessages.push({ role: 'user', content: `${systemPrompt}\n\nUser: ${msg.content}` })
        } else {
          apiMessages.push({ role: msg.role, content: msg.content })
        }
      }

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          model: modelName,
          messages: apiMessages,
          temperature: 0.7,
          stream: !!onToken
        })
      })

      if (response.ok) {
        if (onToken && response.body) {
          const reader = response.body.getReader()
          const decoder = new TextDecoder('utf-8')
          let fullText = ''
          let buffer = ''
          
          while (true) {
            const { done, value } = await reader.read()
            if (done) break
            
            buffer += decoder.decode(value, { stream: true })
            let newlineIndex;
            while ((newlineIndex = buffer.indexOf('\n')) !== -1) {
              const line = buffer.slice(0, newlineIndex).trim()
              buffer = buffer.slice(newlineIndex + 1)
              
              if (line.startsWith('data: ') && line !== 'data: [DONE]') {
                try {
                  const data = JSON.parse(line.slice(6))
                  const content = data.choices[0]?.delta?.content || ''
                  if (content) {
                    fullText += content
                    onToken(fullText)
                  }
                } catch {
                  // Ignore JSON parse errors for incomplete chunks
                }
              }
            }
          }
          clearTimeout(timeoutId)
          return fullText
        } else {
          const data = await response.json()
          clearTimeout(timeoutId)
          if (data.choices && data.choices[0]?.message?.content) {
            return data.choices[0].message.content
          }
        }
      }
      clearTimeout(timeoutId)
    } catch (err) {
      console.error(`Error connecting to ${endpoint}:`, err)
    }
  }

  return '⚠️ Không thể kết nối với mô hình AI'
}
