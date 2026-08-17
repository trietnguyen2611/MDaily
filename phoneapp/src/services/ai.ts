import { registerPlugin } from '@capacitor/core'

export interface AFMPluginInterface {
  isAFMAvailable(): Promise<{ available: boolean; model: string }>
  generateText(options: { prompt: string; context?: string; systemPrompt?: string }): Promise<{ text: string; engine: string }>
}

const AFMPlugin = registerPlugin<AFMPluginInterface>('AFMPlugin')

const SETTINGS_AI_URL_KEY = 'mdaily_ai_url'

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

const LOCAL_AI_ENDPOINTS = [
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

// Interface for Apple Foundation Models / Web AI standard proposals
declare global {
  interface Window {
    ai?: {
      languageModel?: {
        create: (options?: any) => Promise<{
          prompt: (text: string) => Promise<string>
          promptStreaming?: (text: string) => AsyncIterable<string>
        }>
      }
      createTextSession?: () => Promise<{
        prompt: (text: string) => Promise<string>
      }>
    }
  }
}

// Detect if Apple Foundation Model or Local Browser AI is available
export const detectLocalFoundationModel = async (): Promise<boolean> => {
  if (typeof window !== 'undefined' && window.ai) {
    return true
  }
  try {
    const res = await AFMPlugin.isAFMAvailable()
    return res && res.available
  } catch {
    return false
  }
}

export const checkAFMStatus = async (): Promise<{ available: boolean; model: string; message: string }> => {
  try {
    const res = await AFMPlugin.isAFMAvailable()
    if (res && res.available) {
      return { available: true, model: res.model, message: 'Đã kết nối Apple Foundation Model (On-Device AI)' }
    }
  } catch (e) {
    // ignore
  }
  if (typeof window !== 'undefined' && window.ai) {
    return { available: true, model: 'Web AI Language Model', message: 'Đã kết nối Web AI' }
  }
  return { available: false, model: 'Không khả dụng', message: 'AFM chưa khả dụng (cần iOS 26+ và thiết bị hỗ trợ)' }
}

// Fallback intelligent local analysis response when no external server is connected
const generateLocalSmartResponse = (userPrompt: string, expenseContext: string): string => {
  const promptLower = userPrompt.toLowerCase()

  if (promptLower.includes('tổng') || promptLower.includes('tổng cộng') || promptLower.includes('bao nhiêu')) {
    if (!expenseContext.trim()) {
      return 'Mày chưa có khoản chi tiêu nào cả! Vẫn còn giàu chán, giữ phong độ nhé!'
    }
    return `Theo dữ liệu chi tiêu mày đã lưu:\n\n${expenseContext}\n\nHãy xem lại xem có khoản nào tiêu hoang quá không nhé!`
  }

  if (promptLower.includes('khuyên') || promptLower.includes('tiết kiệm') || promptLower.includes('lời khuyên')) {
    return 'Lời khuyên chân thành của MDaily AI: Hạn chế trà sữa, bớt săn sale Shopee lại và ghi chép chi tiêu đầy đủ mỗi ngày. Đồng tiền đi liền khúc ruột đó!'
  }

  if (promptLower.includes('ăn') || promptLower.includes('uống') || promptLower.includes('nước')) {
    return 'Chi tiêu ăn uống là nhu cầu thiết yếu, nhưng nhớ đừng ăn sang chảnh quá đà vào đầu tháng để rồi cuối tháng phải ăn mì tôm gói nhé!'
  }

  if (promptLower.includes('chào') || promptLower.includes('hi') || promptLower.includes('hello')) {
    return 'Chào mày! MDaily AI đây. Hôm nay mày đã lỡ tay vung tiền vào cái gì rồi? Khai ra để tao tổng kết cho!'
  }

  return `MDaily Local AI đã ghi nhận câu hỏi: "${userPrompt}".\n\nDữ liệu chi tiêu hiện tại của mày:\n${expenseContext || '(Chưa có dữ liệu)'}\n\nHãy tiếp tục quản lý tài chính thông minh nhé!`
}

export const chatWithAI = async (
  messages: { role: string; content: string }[],
  expenseHistoryContext: string,
  onToken?: (text: string) => void
): Promise<string> => {
  const lastUserMsg = messages[messages.length - 1]?.content || ''

  // 1. Try Native Apple Foundation Model (AFM) Capacitor Plugin on iOS
  try {
    const afmStatus = await AFMPlugin.isAFMAvailable()
    if (afmStatus && afmStatus.available) {
      const res = await AFMPlugin.generateText({
        prompt: lastUserMsg,
        context: expenseHistoryContext,
        systemPrompt: 'Bạn là MDaily AI, trợ lý tài chính cá nhân hóm hỉnh và hài hước.'
      })
      if (res && res.text) {
        if (onToken) onToken(res.text)
        return res.text
      }
    }
  } catch (err) {
    console.warn('Native AFMPlugin invocation warning, checking Web AI:', err)
  }

  // 2. Try Apple Foundation Model / Local Browser AI API if supported
  if (typeof window !== 'undefined' && window.ai) {
    try {
      let session: any = null
      if (window.ai.languageModel) {
        session = await window.ai.languageModel.create({
          systemPrompt: 'Bạn là MDaily AI, trợ lý tài chính cá nhân thông minh, hóm hỉnh và hài hước.'
        })
      } else if (window.ai.createTextSession) {
        session = await window.ai.createTextSession()
      }

      if (session && session.prompt) {
        const fullPrompt = `Dữ liệu chi tiêu của tôi:\n${expenseHistoryContext}\n\nCâu hỏi: ${lastUserMsg}`
        const result = await session.prompt(fullPrompt)
        if (onToken) onToken(result)
        return result
      }
    } catch (err) {
      console.warn('Apple Foundation Model invocation error, falling back:', err)
    }
  }

  // 2. Try Local AI endpoints (Jan AI, Ollama, etc.) if configured or reachable
  const endpoints = getAiEndpointsToTry()
  const systemPrompt = `Bạn là MDaily AI - Trợ lý tài chính hóm hỉnh, cá tính và sắc sảo.
Dữ liệu chi tiêu hiện tại của người dùng:
${expenseHistoryContext}

Nhiệm vụ của bạn là đưa ra lời khuyên tài chính, nhận xét về các khoản chi và trả lời ngắn gọn, thẳng thắn, mang tính giải trí cao.`

  for (const endpoint of endpoints) {
    try {
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 4000)

      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          model: 'gemma-2-2b-it-Q4_K_M.gguf',
          messages: [
            { role: 'system', content: systemPrompt },
            ...messages
          ],
          temperature: 0.7,
          stream: false
        })
      })

      clearTimeout(timeoutId)

      if (response.ok) {
        const data = await response.json()
        const reply = data.choices?.[0]?.message?.content || ''
        if (reply) {
          if (onToken) onToken(reply)
          return reply
        }
      }
    } catch (e) {
      // Continue to next endpoint or fallback
    }
  }

  // 3. Fallback to Local Smart Engine
  const localReply = generateLocalSmartResponse(lastUserMsg, expenseHistoryContext)
  if (onToken) onToken(localReply)
  return localReply
}
