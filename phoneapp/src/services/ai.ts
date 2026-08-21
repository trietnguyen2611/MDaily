import { registerPlugin, Capacitor } from '@capacitor/core'

export interface AFMPluginInterface {
  isAFMAvailable(): Promise<{ available: boolean; model: string; canExtractImage: boolean }>
  generateText(options: { prompt: string; context?: string; systemPrompt?: string }): Promise<{ text: string; engine: string }>
  extractFromImage(options: { imageBase64: string }): Promise<{
    success: boolean
    itemName?: string
    amount?: number
    category?: string
    isInvoice?: boolean
    description?: string
    engine?: string
    error?: string
  }>
  chooseSyncFile(): Promise<{ configured: boolean; name?: string }>
  ensureSyncFile(): Promise<{ configured: boolean; name?: string }>
  readSyncFile(): Promise<{ configured: boolean; contents?: string; name?: string }>
  writeSyncFile(options: { contents: string }): Promise<{ success: boolean; configured: boolean }>
}

export const AFMPlugin = registerPlugin<AFMPluginInterface>('AFMPlugin')

const SETTINGS_AI_URL_KEY = 'mdaily_ai_url'
const SETTINGS_AUTO_EXTRACT_KEY = 'mdaily_auto_extract'
const SETTINGS_AI_CHAT_KEY = 'mdaily_ai_chat_enabled'

export const getCustomAiUrl = () => localStorage.getItem(SETTINGS_AI_URL_KEY) || ''
export const setCustomAiUrl = (url: string) => {
  if (url) localStorage.setItem(SETTINGS_AI_URL_KEY, url)
  else localStorage.removeItem(SETTINGS_AI_URL_KEY)
}

export const getAutoExtractEnabled = () => localStorage.getItem(SETTINGS_AUTO_EXTRACT_KEY) !== 'false'
export const setAutoExtractEnabled = (enabled: boolean) => localStorage.setItem(SETTINGS_AUTO_EXTRACT_KEY, enabled ? 'true' : 'false')

export const getAiChatEnabled = () => localStorage.getItem(SETTINGS_AI_CHAT_KEY) !== 'false'
export const setAiChatEnabled = (enabled: boolean) => localStorage.setItem(SETTINGS_AI_CHAT_KEY, enabled ? 'true' : 'false')

// Check AFM availability
export const checkAFMStatus = async (): Promise<{ available: boolean; model: string; canExtractImage: boolean; message: string }> => {
  if (Capacitor.isNativePlatform()) {
    try {
      const res = await AFMPlugin.isAFMAvailable()
      return {
        available: res.available,
        model: res.model,
        canExtractImage: res.canExtractImage,
        message: res.available
          ? 'Apple Intelligence đã kích hoạt trên thiết bị'
          : res.model
      }
    } catch {
      return { available: false, model: 'Không thể kiểm tra', canExtractImage: false, message: 'Lỗi kết nối plugin' }
    }
  }
  return { available: false, model: 'Chỉ hỗ trợ trên iPhone/iPad', canExtractImage: false, message: 'Cần thiết bị iOS với Apple Intelligence' }
}

// Extract expense info from image using AFM
export const extractExpenseFromImage = async (base64: string): Promise<{
  success: boolean
  itemName?: string
  amount?: number
  category?: string
  isInvoice?: boolean
  description?: string
  error?: string
}> => {
  if (!Capacitor.isNativePlatform()) {
    return { success: false, error: 'Chỉ hỗ trợ trên thiết bị iOS' }
  }
  try {
    const result = await AFMPlugin.extractFromImage({ imageBase64: base64 })
    return result
  } catch (err: any) {
    return { success: false, error: err?.message || 'Lỗi trích xuất ảnh' }
  }
}

// Chat with AI
export const chatWithAI = async (
  messages: { role: string; content: string }[],
  expenseHistoryContext: string,
  onToken?: (text: string) => void
): Promise<string> => {
  const lastUserMsg = messages[messages.length - 1]?.content || ''

  // 1. Try Native AFM
  if (Capacitor.isNativePlatform()) {
    try {
      const res = await AFMPlugin.generateText({
        prompt: lastUserMsg,
        context: expenseHistoryContext,
        systemPrompt: 'Bạn là MDaily AI, trợ lý tài chính cá nhân hóm hỉnh, thông minh và sắc sảo.'
      })
      if (res?.text) {
        onToken?.(res.text)
        return res.text
      }
    } catch (err) {
      console.warn('AFMPlugin error:', err)
    }
  }

  // 2. Try custom AI endpoint
  const customAiUrl = getCustomAiUrl()
  if (customAiUrl) {
    let endpoint = customAiUrl
    if (endpoint.endsWith('/v1')) endpoint += '/chat/completions'
    else if (!endpoint.endsWith('/chat/completions')) endpoint += '/v1/chat/completions'

    try {
      const controller = new AbortController()
      const timeoutId = setTimeout(() => controller.abort(), 5000)
      const response = await fetch(endpoint, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        signal: controller.signal,
        body: JSON.stringify({
          model: 'gemma-2-2b-it-Q4_K_M.gguf',
          messages: [
            { role: 'system', content: `Bạn là MDaily AI.\nDữ liệu chi tiêu:\n${expenseHistoryContext}` },
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
        if (reply) { onToken?.(reply); return reply }
      }
    } catch { /* continue */ }
  }

  // 3. Fallback local
  const reply = generateLocalResponse(lastUserMsg, expenseHistoryContext)
  onToken?.(reply)
  return reply
}

function generateLocalResponse(prompt: string, context: string): string {
  const p = prompt.toLowerCase()
  const lines = context.split('\n').filter(l => l.trim())
  let total = 0
  const catTotals: Record<string, number> = {}
  let maxAmt = 0, maxLine = ''

  for (const line of lines) {
    const parts = line.split(' - ')
    if (parts.length >= 2) {
      const cat = parts[0].split(': ')[1] || 'Khác'
      const m = parts[1].match(/([0-9.,]+)\s*VND/i)
      if (m) {
        const n = parseFloat(m[1].replace(/\./g, '').replace(/,/g, ''))
        if (!isNaN(n)) {
          total += n; catTotals[cat] = (catTotals[cat] || 0) + n
          if (n > maxAmt) { maxAmt = n; maxLine = line }
        }
      }
    }
  }
  const fmt = (n: number) => n.toLocaleString('vi-VN')

  if (p.includes('tổng') || p.includes('bao nhiêu')) {
    if (!lines.length) return 'Chưa có khoản chi nào!'
    const bd = Object.entries(catTotals).sort((a, b) => b[1] - a[1])
      .map(([c, a]) => `• ${c}: ${fmt(a)} đ (${Math.round(a / total * 100)}%)`).join('\n')
    return `💸 Tổng chi: ${fmt(total)} đ (${lines.length} khoản)\n\n${bd}`
  }
  if (p.includes('lớn nhất') || p.includes('tốn nhất')) {
    return maxAmt > 0 ? `🚨 Khoản chi nặng nhất: ${maxLine}` : 'Chưa có dữ liệu.'
  }
  if (p.includes('khuyên') || p.includes('tiết kiệm'))
    return '💡 Quy tắc 50/30/20: 50% thiết yếu, 30% mong muốn, 20% tiết kiệm!'
  if (p.includes('chào') || p.includes('hi'))
    return 'Chào! Tôi là MDaily AI. Hỏi tôi về chi tiêu của bạn nhé!'
  return `MDaily AI nhận yêu cầu: "${prompt}". ${lines.length > 0 ? `Tổng chi hiện tại: ${fmt(total)} đ.` : ''}`
}
