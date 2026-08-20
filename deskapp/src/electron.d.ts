interface NativeReceiptResult {
  isReceipt: boolean
  amount: number
  engine: string
}

interface Window {
  ipcRenderer?: {
    invoke(channel: 'analyze-receipt-native', imageBase64: string): Promise<NativeReceiptResult | null>
  }
}
