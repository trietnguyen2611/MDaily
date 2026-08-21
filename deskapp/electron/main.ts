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
let syncToken = ''
let syncServer: http.Server | null = null
let syncServerActive = false
const sseClients = new Set<http.ServerResponse>()

function getSyncSettingsPath(): string {
  // Keep the token stable between Electron dev mode and packaged app mode.
  return path.join(app.getPath('appData'), 'deskapp', 'sync-server.json')
}

function loadSyncToken() {
  try {
    const settings = JSON.parse(fs.readFileSync(getSyncSettingsPath(), 'utf8'))
    syncToken = typeof settings.token === 'string' && settings.token.length > 0
      ? settings.token
      : generateSyncPin()
  } catch {
    try {
      const legacyPath = path.join(app.getPath('appData'), 'Electron', 'sync-server.json')
      const legacySettings = JSON.parse(fs.readFileSync(legacyPath, 'utf8'))
      syncToken = typeof legacySettings.token === 'string' && legacySettings.token.length > 0
        ? legacySettings.token
        : generateSyncPin()
    } catch {
      syncToken = generateSyncPin()
    }
  }
}

function saveSyncToken() {
  try {
    fs.mkdirSync(path.dirname(getSyncSettingsPath()), { recursive: true })
    fs.writeFileSync(getSyncSettingsPath(), JSON.stringify({ token: syncToken }), 'utf8')
  } catch (err) {
    console.error('[MDaily Sync] Failed to persist sync token:', err)
  }
}

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
  const physicalIps: string[] = []
  const otherIps: string[] = []

  for (const name of Object.keys(interfaces)) {
    const isVirtual = /^(vboxnet|vmnet|docker|utun|tun|tap|virbr|veth|vEthernet)/i.test(name)
    for (const iface of interfaces[name] || []) {
      if (iface.family === 'IPv4' && !iface.internal) {
        if (isVirtual || iface.address.startsWith('192.168.56.') || iface.address.startsWith('172.17.')) {
          otherIps.push(iface.address)
        } else {
          // Prefer en0 (macOS Wi-Fi) or wlan / eth interfaces
          if (/^(en0|wlan0|wi-fi|ethernet)/i.test(name)) {
            physicalIps.unshift(iface.address)
          } else {
            physicalIps.push(iface.address)
          }
        }
      }
    }
  }
  const combined = [...new Set([...physicalIps, ...otherIps])]
  return combined.length > 0 ? combined : ['127.0.0.1']
}

function getPrimaryIp(): string {
  const ips = getLocalIps()
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
    allIps,
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
    allIps,
    connectedClients: sseClients.size
  }
}

function broadcastSyncEvent(event = 'data_changed', meta?: any) {
  const payload = JSON.stringify({ event, timestamp: Date.now(), ...(meta || {}) })
  for (const client of sseClients) {
    try {
      client.write(`data: ${payload}\n\n`)
    } catch {
      sseClients.delete(client)
    }
  }
}

// Heartbeat for SSE streams
setInterval(() => {
  for (const client of sseClients) {
    try {
      client.write(`: ping\n\n`)
    } catch {
      sseClients.delete(client)
    }
  }
}, 15000)

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

    const checkAuth = (bodyToken?: string): boolean => {
      const authHeader = req.headers['authorization'] || ''
      const bearerToken = authHeader.startsWith('Bearer ') ? authHeader.substring(7) : ''
      const customHeader = (req.headers['x-sync-token'] as string) || ''
      const queryToken = urlObj.searchParams.get('token') || ''
      const received = (bearerToken || customHeader || queryToken || bodyToken || '').trim().toUpperCase()
      return received === syncToken.toUpperCase()
    }

    // 1. Health check / Ping
    if ((pathname === '/api/ping' || pathname === '/api/sync/discover') && req.method === 'GET') {
      res.writeHead(200, {
        'Content-Type': 'application/json',
        'Access-Control-Allow-Origin': '*'
      })
      res.end(JSON.stringify({
        app: 'MDaily',
        version: '2.4.0',
        deviceName: os.hostname(),
        status: 'ready',
        port: syncPort,
        allIps: getLocalIps(),
        timestamp: Date.now()
      }))
      return
    }

    // 2. Real-time Event Stream (SSE) for Auto-Sync
    if (pathname === '/api/sync/stream' && req.method === 'GET') {
      if (!checkAuth()) {
        res.writeHead(401, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' })
        res.end(JSON.stringify({ success: false, error: 'Unauthorized: Invalid token' }))
        return
      }

      res.writeHead(200, {
        'Content-Type': 'text/event-stream; charset=utf-8',
        'Cache-Control': 'no-cache, no-transform',
        'Connection': 'keep-alive',
        'X-Accel-Buffering': 'no',
        'Access-Control-Allow-Origin': '*'
      })
      res.write(`data: ${JSON.stringify({ event: 'connected', timestamp: Date.now() })}\n\n`)
      sseClients.add(res)

      req.on('close', () => {
        sseClients.delete(res)
      })
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

    try {
      // 3. Pull from Desktop -> Phone
      if (pathname === '/api/sync/pull' && req.method === 'POST') {
        const body = await readBody()
        if (!checkAuth(body.token)) {
          res.writeHead(401, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' })
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
        res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' })
        res.end(JSON.stringify({
          success: true,
          expenses: data.expenses || [],
          categories: data.categories || [],
          deletedExpenseIds: data.deletedExpenseIds || [],
          deletedCategoryValues: data.deletedCategoryValues || [],
          timestamp: Date.now()
        }))
        return
      }

      // 4. Push from Phone -> Desktop
      if (pathname === '/api/sync/push' && req.method === 'POST') {
        const body = await readBody()
        if (!checkAuth(body.token)) {
          res.writeHead(401, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' })
          res.end(JSON.stringify({ success: false, error: 'Unauthorized: Invalid token' }))
          return
        }

        const result = await sendRendererSyncRequest('import', {
          expenses: body.expenses || [],
          categories: body.categories || [],
          deletedExpenseIds: body.deletedExpenseIds || [],
          deletedCategoryValues: body.deletedCategoryValues || []
        })

        if (win && !win.isDestroyed()) {
          win.webContents.send('sync-event-notification', {
            type: 'push',
            source: 'phone',
            message: `Đã nhận ${body.expenses?.length || 0} chi tiêu từ Điện thoại`,
            timestamp: Date.now()
          })
        }

        // Notify other clients
        broadcastSyncEvent('data_changed', { source: 'phone_push' })

        res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' })
        res.end(JSON.stringify({
          success: true,
          count: body.expenses?.length || 0,
          details: result,
          timestamp: Date.now()
        }))
        return
      }

      // 5. Two-Way Smart Merge
      if (pathname === '/api/sync/merge' && req.method === 'POST') {
        const body = await readBody()
        if (!checkAuth(body.token)) {
          res.writeHead(401, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' })
          res.end(JSON.stringify({ success: false, error: 'Unauthorized: Invalid token' }))
          return
        }

        const mergeResult = await sendRendererSyncRequest('merge', {
          expenses: body.expenses || [],
          categories: body.categories || [],
          deletedExpenseIds: body.deletedExpenseIds || [],
          deletedCategoryValues: body.deletedCategoryValues || []
        })

        const stats = mergeResult.stats || { added: 0, updated: 0 }
        const hasMutations = (stats.added || 0) > 0 || (stats.updated || 0) > 0

        // Only notify Deskapp UI if there were actual changes
        if (hasMutations && win && !win.isDestroyed()) {
          win.webContents.send('sync-event-notification', {
            type: 'merge',
            source: 'phone',
            message: `Đã đồng bộ: +${stats.added || 0} mới, ~${stats.updated || 0} cập nhật`,
            timestamp: Date.now()
          })
        }

        res.writeHead(200, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' })
        res.end(JSON.stringify({
          success: true,
          expenses: mergeResult.expenses || [],
          categories: mergeResult.categories || [],
          deletedExpenseIds: mergeResult.deletedExpenseIds || [],
          deletedCategoryValues: mergeResult.deletedCategoryValues || [],
          timestamp: Date.now()
        }))
        return
      }

      // 404 for other routes
      res.writeHead(404, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' })
      res.end(JSON.stringify({ error: 'Endpoint not found' }))
    } catch (err: any) {
      console.error('Sync Server Error:', err)
      res.writeHead(500, { 'Content-Type': 'application/json', 'Access-Control-Allow-Origin': '*' })
      res.end(JSON.stringify({ success: false, error: err?.message || 'Internal server error' }))
    }
  })

  server.listen(portToTry, '0.0.0.0', () => {
    syncPort = portToTry
    syncServerActive = true
    syncServer = server
    console.log(`[MDaily Sync Server] Running at http://${getPrimaryIp()}:${syncPort}`)
    if (win && !win.isDestroyed()) {
      win.webContents.send('sync-server-status-changed', getSyncServerInfo())
    }
  })

  server.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      console.warn(`Port ${portToTry} in use, trying ${portToTry + 1}...`)
      startSyncServer(portToTry + 1)
    } else {
      console.error('[MDaily Sync Server Error]', err)
      syncServerActive = false
      if (win && !win.isDestroyed()) {
        win.webContents.send('sync-server-status-changed', getSyncServerInfo())
      }
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
      backgroundThrottling: false, // Ensure real-time sync works reliably when window is in background
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
  // On macOS, keep the sync server running in background even if window is closed
  if (process.platform !== 'darwin') {
    if (syncServer) {
      try { syncServer.close() } catch { /* ignore */ }
      syncServer = null
    }
    syncServerActive = false
    app.quit()
    win = null
  }
})

app.on('activate', () => {
  if (!syncServer || !syncServerActive) {
    startSyncServer()
  }
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow()
  }
})

app.whenReady().then(() => {
  loadSyncToken()
  saveSyncToken()
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
  saveSyncToken()
  const info = getSyncServerInfo()
  if (win && !win.isDestroyed()) {
    win.webContents.send('sync-server-status-changed', info)
  }
  return info
})

// Broadcast data mutation event to mobile clients
ipcMain.on('broadcast-sync-event', (_event, data) => {
  broadcastSyncEvent('data_changed', data)
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
