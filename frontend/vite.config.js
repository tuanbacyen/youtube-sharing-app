import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

export default defineConfig({
  plugins: [react()],
  server: {
    port: 3001,
    proxy: {
      '/api': { target: process.env.VITE_BACKEND_URL || 'http://localhost:3969', changeOrigin: true },
      '/cable': { target: process.env.VITE_WS_URL || 'ws://localhost:3969', ws: true, changeOrigin: true }
    }
  }
})
