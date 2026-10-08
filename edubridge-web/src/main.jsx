// نقطة تشغيل واجهة الويب
import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import { BrowserRouter } from 'react-router-dom'
import './styles/fonts.css'
import './styles/theme/tokens.css'
import './index.css'
import './identity.css'
import './brand-wordmark.css'
import './styles/institution.css'
import App from './App.jsx'
import './styles/identity/dark-refinements.css'
import './styles/identity/shared-shell.css'
import { applyTheme, getTheme } from './theme'
import { InstitutionProvider } from './institutionContext'

applyTheme(getTheme(), { persist: false, notify: false })

createRoot(document.getElementById('root')).render(
  <StrictMode>
    <InstitutionProvider>
      <BrowserRouter>
        <App />
      </BrowserRouter>
    </InstitutionProvider>
  </StrictMode>,
)
