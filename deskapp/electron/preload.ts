import { ipcRenderer } from 'electron'

// Since we set contextIsolation: false, we can attach to window directly
window.ipcRenderer = ipcRenderer
