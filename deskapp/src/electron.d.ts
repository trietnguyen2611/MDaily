interface NativeReceiptResult {
  isReceipt: boolean
  amount: number
  engine: string
}

export interface SyncServerInfo {
  active: boolean
  ip: string
  port: number
  token: string
  url: string
  qrPayload: string
  deviceName: string
  allIps: string[]
}

interface Window {
  ipcRenderer?: {
    invoke(channel: 'analyze-receipt-native', imageBase64: string): Promise<NativeReceiptResult | null>
    invoke(channel: 'get-sync-server-info'): Promise<SyncServerInfo>
    invoke(channel: 'refresh-sync-token'): Promise<SyncServerInfo>
    invoke(channel: 'get-system-theme'): Promise<string>
    invoke(channel: string, ...args: any[]): Promise<any>
    on(channel: string, listener: (...args: any[]) => void): void
    removeListener(channel: string, listener: (...args: any[]) => void): void
    send(channel: string, ...args: any[]): void
  }
}
