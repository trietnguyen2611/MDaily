export type Category = string

export interface Expense {
  id: string
  amount: number
  category: Category
  date: string
  photo?: string // base64 or blob URL (optional)
  note?: string
  isAiProcessed?: boolean
}

export interface ChatMessage {
  id: string
  role: 'user' | 'assistant'
  content: string
}
