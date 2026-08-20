import { app, BrowserWindow, ipcMain, nativeTheme } from 'electron'
import { spawn } from 'node:child_process'
import fs from 'node:fs'
import path from 'node:path'
import { fileURLToPath } from 'node:url'

const __dirname = path.dirname(fileURLToPath(import.meta.url))

// The built directory structure
//
// ├─┬─┬ dist
// │ │ └── index.html
// │ │
// │ ├─┬ dist-electron
// │ │ ├── main.js
// │ │ └── preload.js
// │
process.env.DIST = path.join(__dirname, '../dist')
process.env.VITE_PUBLIC = app.isPackaged ? process.env.DIST : path.join(process.env.DIST, '../public')

let win: BrowserWindow | null
// 🚧 Use ['ENV_NAME'] avoid vite:define plugin - Vite@2.x
const VITE_DEV_SERVER_URL = process.env['VITE_DEV_SERVER_URL']

function createWindow() {
  win = new BrowserWindow({
    icon: path.join(process.env.VITE_PUBLIC, 'icon.png'),
    title: 'MDaily Desktop v2.1',
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
      contextIsolation: false, // For simplicity in this demo, though contextIsolation: true is recommended for prod
      webSecurity: false, // Allow cross-origin requests to local AI server
    },
  })

  // Test active push message to Renderer-process.
  win.webContents.on('did-finish-load', () => {
    win?.webContents.send('main-process-message', (new Date).toLocaleString())
  })

  if (VITE_DEV_SERVER_URL) {
    win.loadURL(VITE_DEV_SERVER_URL)
  } else {
    // win.loadFile('dist/index.html')
    win.loadFile(path.join(process.env.DIST, 'index.html'))
  }

  // Set system dark mode preference changes listener
  nativeTheme.on('updated', () => {
    win?.webContents.send('theme-changed', nativeTheme.shouldUseDarkColors ? 'dark' : 'light')
  })
}

// Quit when all windows are closed, except on macOS. There, it's common
// for applications and their menu bar to stay active until the user quits
// explicitly with Cmd + Q.
app.on('window-all-closed', () => {
  if (process.platform !== 'darwin') {
    app.quit()
    win = null
  }
})

app.on('activate', () => {
  // On OS X it's common to re-create a window in the app when the
  // dock icon is clicked and there are no other windows open.
  if (BrowserWindow.getAllWindows().length === 0) {
    createWindow()
  }
})

app.whenReady().then(createWindow)

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

// IPC channel to get initial theme
ipcMain.handle('get-system-theme', () => {
  return nativeTheme.shouldUseDarkColors ? 'dark' : 'light'
})
