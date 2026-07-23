import { defineConfig } from 'vite'
import react from '@vitejs/plugin-react'

// https://vite.dev/config/
export default defineConfig({
  plugins: [react()],
  server: {
    host: true, // الاستماع على كل الواجهات ليمكن الوصول من أجهزة الشبكة
  },
})
