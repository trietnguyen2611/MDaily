import { app, BrowserWindow, ipcMain, nativeTheme } from 'electron'
import { spawn } from 'node:child_process'
import http from 'node:http'
import os from 'node:os'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

process.env.DIST = path.join(__dirname, '../dist')
process.env.VITE_PUBLIC = app.isPackaged ? process.env.DIST : path.join(process.env.DIST, '../public')

let win: BrowserWindow | null = null
const VITE_DEV_SERVER_URL = process.env['VITE_DEV_SERVER_URL']

// Wi-Fi Sync Server State
let syncPort = 18321
let syncToken = generateSyncPin()
let syncServer: http.Server | null = null
let syncServerActive = false

function generateSyncPin(): string {
  const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'
  let pin = ''
  for (let i = 0; i < 6; i++) {
    pin += chars.charAt(Math.floor(Math.random() * chars.length))
  }
  return pin
}

function getLocalIps(): string[] {
  const interfaces = os.networkInterfaces()
  const ips: string[] = []
  for (const name of Object.keys(interfaces)) {
    for (const iface of interfaces[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) {
        ips.push(iface.address)
      }
    }
  }
  return ips.length > 0 ? ips : ['127.0.0.1']
}

function getPrimaryIp(): string {
  const ips = getLocalIps()
  // Prefer 192.168.x.x or 10.x.x.x or 172.16-31.x.x
  const wifiIp = ips.find(ip => ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.'))
  return wifiIp || ips[0] || '127.0.0.1'
}

function getSyncServerInfo() {
  const ip = getPrimaryIp()
  const allIps = getLocalIps()
  const qrPayload = JSON.stringify({
    app: 'MDaily',
    v: '2.4',
    ip,
    port: syncPort,
    token: syncToken,
    name: os.hostname()
  })
  return {
    active: syncServerActive,
    ip,
    port: syncPort,
    token: syncToken,
    url: `http://${ip}:${syncPort}`,
    qrPayload,
    deviceName: os.hostname(),
    allIps
  }
}

// Pending IPC requests map for renderer sync responses
const pendingSyncRequests = new Map<string, { resolve: (val: any) => void; reject: (err: any) => void; timeout: NodeJS.Timeout }>()

function sendRendererSyncRequest(type: 'export' | 'import' | 'merge', payload?: any): Promise<any> {
  return new Promise((resolve, reject) => {
    if (!win || win.isDestroyed()) {
      return reject(new Error('Window not available'))
    }
    const requestId = `sync_${Date.now()}_${Math.random().toString(36).substring(2, 7)}`
    const timeout = setTimeout(() => {
      pendingSyncRequests.delete(requestId)
      reject(new Error('Sync request to renderer timed out'))
    }, 15000)

    pendingSyncRequests.set(requestId, { resolve, reject, timeout })
    win.webContents.send('sync-bridge-request', { requestId, type, payload })
  })
}

function startSyncServer(portToTry = 18321) {
  if (syncServer) {
    try { syncServer.close() } catch { /* ignore */ }
  }

  const server = http.createServer(async (req, res) => {
    // Enable CORS for mobile browsers / Capacitor / Fetch
    res.setHeader('Access-Control-Allow-Origin', '*')
    res.setHeader('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
    res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization, x-sync-token')

    if (req.method === 'OPTIONS') {
      res.writeHead(204)
      res.end()
      return
    }

    const urlObj = new URL(req.url || '/', `http://localhost:${syncPort}`)
    const pathname = urlObj.pathname

    // 1. Health check / Ping
    if (pathname === '/api/ping' && req.method === 'GET') {
      res.writeHead(200, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({
        app: 'MDaily',
        version: '2.4.0',
        deviceName: os.hostname(),
        status: 'ready',
        timestamp: Date.now()
      }))
      return
    }

    // Helper to read request body
    const readBody = async (): Promise<any> => {
      return new Promise((resolve, reject) => {
        let body = ''
        req.on('data', chunk => { body += chunk.toString() })
        req.on('end', () => {
          try {
            resolve(body ? JSON.parse(body) : {})
          } catch {
            resolve({})
          }
        })
        req.on('error', reject)
      })
    }

    const checkAuth = (bodyToken?: string): boolean => {
      const authHeader = req.headers['authorization'] || ''
      const bearerToken = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : ''
      const customHeader = (req.headers['x-sync-token'] as string) || ''
      const queryToken = urlObj.searchParams.get('token') || ''
      const received = (bearerToken || customHeader || queryToken || bodyToken || '').trim().toUpperCase()
      return received === syncToken.toUpperCase()
    }

    try {
      // 2. Pull from Desktop -> Phone
      if (pathname === '/api/sync/pull' && req.method === 'POST') {
        const body = await readBody()
        if (!checkAuth(body.token)) {
          res.writeHead(401, { 'Content-Type': 'application/json' })
          res.end(JSON.stringify({ success: false, error: 'Unauthorized: Invalid token' }))
          return
        }

        const data = await sendRendererSyncRequest('export')
        if (win && !win.isDestroyed()) {
          win.webContents.send('sync-event-notification', {
            type: 'pull',
            source: 'phone',
            message: 'Đã gửi dữ liệu chi tiêu sang Điện thoại',
            timestamp: Date.now()
          })
        }
        res.writeHead(200, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify({
          success: true,
          expenses: data.expenses || [],
          categories: data.categories || [],
          timestamp: Date.now()
        }))
        return
      }

      // 3. Push from Phone -> Desktop
      if (pathname === '/api/sync/push' && req.method === 'POST') {
        const body = await readBody()
        if (!checkAuth(body.token)) {
          res.writeHead(401, { 'Content-Type': 'application/json' })
          res.end(JSON.stringify({ success: false, error: 'Unauthorized: Invalid token' }))
          return
        }

        const result = await sendRendererSyncRequest('import', {
          expenses: body.expenses || [],
          categories: body.categories || []
        })

        if (win && !win.isDestroyed()) {
          win.webContents.send('sync-event-notification', {
            type: 'push',
            source: 'phone',
            message: `Đã nhận ${body.expenses?.length || 0} chi tiêu từ Điện thoại`,
            timestamp: Date.now()
          })
        }

        res.writeHead(200, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify({
          success: true,
          count: body.expenses?.length || 0,
          details: result,
          timestamp: Date.now()
        }))
        return
      }

      // 4. Two-Way Smart Merge
      if (pathname === '/api/sync/merge' && req.method === 'POST') {
        const body = await readBody()
        if (!checkAuth(body.token)) {
          res.writeHead(401, { 'Content-Type': 'application/json' })
          res.end(JSON.stringify({ success: false, error: 'Unauthorized: Invalid token' }))
          return
        }

        const mergeResult = await sendRendererSyncRequest('merge', {
          expenses: body.expenses || [],
          categories: body.categories || []
        })

        if (win && !win.isDestroyed()) {
          win.webContents.send('sync-event-notification', {
            type: 'merge',
            source: 'phone',
            message: `Đồng bộ 2 chiều thành công (${mergeResult.expenses?.length || 0} chi tiêu)`,
            timestamp: Date.now()
          })
        }

        res.writeHead(200, { 'Content-Type': 'application/json' })
        res.end(JSON.stringify({
          success: true,
          expenses: mergeResult.expenses || [],
          categories: mergeResult.categories || [],
          stats: mergeResult.stats,
          timestamp: Date.now()
        }))
        return
      }

      // 404 for other paths
      res.writeHead(404, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({ error: 'Endpoint not found' }))
    } catch (err: any) {
      res.writeHead(500, { 'Content-Type': 'application/json' })
      res.end(JSON.stringify({ success: false, error: err?.message || 'Internal Server Error' }))
    }
  })

  server.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE' && portToTry < 18330) {
      startSyncServer(portToTry + 1)
    } else {
      syncServerActive = false
    }
  })

  server.listen(portToTry, '0.0.0.0', () => {
    syncPort = portToTry
    syncServer = server
    syncServerActive = true
    if (win && !win.isDestroyed()) {
      win.webContents.send('sync-server-status-changed', getSyncServerInfo())
    }
  })
}

function createWindow() {
  win = new BrowserWindow({
    icon: path.join(process.env.VITE_PUBLIC, 'icon.png'),
    title: 'MDaily Desktop v2.4',
    width: 1000,
    height: 700,
    minWidth: 850,
    minHeight: 600,
    titleBarStyle: 'hiddenInset',
    vibrancy: 'under-window', // macOS native blur effect
    visualEffectState: 'active',
    transparent: true,
    backgroundColor: '#00000000',
    webPreferences: {
      preload: path.join(__dirname, 'preload.js'),
      nodeIntegration: true,
      contextIsolation: false,
      webSecurity: false,
    },
  })

  win.webContents.on('did-finish-load', () => {
    win?.webContents.send('main-process-message', (new Date).toLocaleString())
    win?.webContents.send('sync-server-status-changed', getSyncServerInfo())
  })

  if (VITE_DEV_SERVER_URL) {
    win.loadURL(VITE_DEV_SERVER_URL)
  } else {
    win.loadFile(path.join(process.env.DIST, 'index.html'))
  }

  // Set system dark mode preference changes listener
  nativeTheme.on('updated', () => {
    win?.webContents.send('theme-changed', nativeTheme.shouldUseDarkColors ? 'dark' : 'light')
  })
}

app.on('window-all-closed', () => {
  if (syncServer) {
    try { syncServer.close() } catch { /* ignore */ }
  }
  if (process.platform !== 'darwin') {
    app.quit()
    win = null
  }
})

app.on('activate', () => {
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow()
  }
})

app.whenReady().then(() => {
  startSyncServer()
  createWindow()
})

// IPC Handler for Receipt Analyzer Native
ipcMain.handle('analyze-receipt-native', async (_event, imageBase64: string) => {
  const helperPath = app.isPackaged
    ? path.join(process.resourcesPath, 'receipt-analyzer')
    : path.join(__dirname, '../build/native/receipt-analyzer')

  if (!fs.existsSync(helperPath)) return null

  return new Promise((resolve) => {
    const helper = spawn(helperPath, [], { stdio: ['pipe', 'pipe', 'ignore'] })
    let output = ''

    helper.stdout.on('data', chunk => {
      output += chunk.toString()
    })
    helper.once('error', () => resolve(null))
    helper.once('close', () => {
      try {
        resolve(JSON.parse(output.trim()))
      } catch {
        resolve(null)
      }
    })

    helper.stdin.write(`${JSON.stringify({ imageBase64 })}\n`)
    helper.stdin.end()
  })
})

// IPC Handlers for Wi-Fi Sync
ipcMain.handle('get-sync-server-info', () => {
  return getSyncServerInfo()
})

ipcMain.handle('refresh-sync-token', () => {
  syncToken = generateSyncPin()
  const info = getSyncServerInfo()
  if (win && !win.isDestroyed()) {
    win.webContents.send('sync-server-status-changed', info)
  }
  return info
})

// Renderer sends back response for a pending sync request
ipcMain.on('sync-bridge-response', (_event, { requestId, error, data }) => {
  const pending = pendingSyncRequests.get(requestId)
  if (pending) {
    clearTimeout(pending.timeout)
    pendingSyncRequests.delete(requestId)
    if (error) {
      pending.reject(new Error(error))
    } else {
      pending.resolve(data)
    }
  }
})

// IPC channel to get initial theme
ipcMain.handle('get-system-theme', () => {
  return nativeTheme.shouldUseDarkColors ? 'dark' : 'light'
})
