import Tesseract from 'tesseract.js'

const JAN_AI_URL = 'http://127.0.0.1:1337/v1'
const MODEL_NAME = 'gemma-2-2b-it-Q4_K_M' // matched with JAN AI local models

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

export const processReceiptWithAI = async (text: string) => {
  const prompt = `You are a receipt parser. I will provide you the text extracted from a receipt.
Extract the total amount (as a number) and guess the category.
Categories allowed: 'bills', 'shopping', 'food', 'transport'.
Return ONLY a valid JSON object in this format: {"amount": number, "category": "string"}. Do not return any other text or markdown.

Extracted Text:
${text}
`

  try {
    const response = await fetch(JAN_AI_URL, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: MODEL_NAME,
        messages: [{ role: 'user', content: prompt }],
        temperature: 0.1
      })
    })

    const data = await response.json()
    const content = data.choices[0].message.content
    // Try to parse JSON from response
    const jsonMatch = content.match(/\\{.*?\\}/s)
    if (jsonMatch) {
      return JSON.parse(jsonMatch[0])
    }
    return JSON.parse(content)
  } catch (error) {
    console.error('AI Error:', error)
    // fallback if AI fails or formatting is wrong
    return { amount: 0, category: 'shopping' }
  }
}

export const chatWithAI = async (messages: { role: string, content: string }[], expenseHistoryContext: string) => {
  const systemPrompt = `You are MDaily AI, an intelligent personal finance assistant.
Be concise, helpful, and friendly. You understand the user's spending context.
You MUST reply and communicate entirely in Vietnamese (Tiếng Việt).
Here is a summary of the user's expenses:
${expenseHistoryContext}
`

  try {
    const response = await fetch(`${JAN_AI_URL}/chat/completions`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({
        model: MODEL_NAME,
        messages: [{ role: 'system', content: systemPrompt }, ...messages],
        temperature: 0.7
      })
    })

    const data = await response.json()
    return data.choices[0].message.content
  } catch (error) {
    console.error('Chat AI Error:', error)
    return 'Lỗi kết nối'
  }
}
