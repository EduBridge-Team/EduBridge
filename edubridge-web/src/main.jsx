// نقطة تشغيل واجهة الويب
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './index.css'
import './identity.css'
import './brand-wordmark.css'
import App from './App.jsx'
import { applyTheme, getTheme } from './theme'

applyTheme(getTheme(), { persist: false, notify: false })

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <BrowserRouter>
      <App />
    </BrowserRouter>
  </StrictMode>,
)
