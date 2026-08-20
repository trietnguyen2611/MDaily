import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'
import electron from 'vite-plugin-electron'
import renderer from 'vite-plugin-electron-renderer'

// https://vitejs.dev/config/
export default defineConfig({
  server: {
    host: '127.0.0.1',
    proxy: {
      '/jan-api': {
        target: 'http://127.0.0.1:1337',
        changeOrigin: true,
        rewrite: (path) => path.replace(/^\/jan-api/, '')
      }
    }
  },
  plugins: [
    react(),
    electron([
      {
        entry: 'electron/main.ts',
      },
      {
        entry: 'electron/preload.ts',
        onstart(options) {
          options.reload()
        },
      },
    ]),
    renderer(),
  ],
})
