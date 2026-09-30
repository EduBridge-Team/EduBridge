(() => {
  const root = document.documentElement
  let theme = 'light'
  try { theme = localStorage.getItem('edubridge_theme') === 'dark' ? 'dark' : 'light' } catch { /* Storage may be unavailable. */ }
  const apply = () => {
    root.dataset.theme = theme
    const button = document.querySelector('[data-theme-toggle]')
    if (button) { button.dataset.icon = theme === 'dark' ? '☀' : '☾'; button.textContent = theme === 'dark' ? 'الوضع الفاتح' : 'الوضع الداكن'; button.setAttribute('aria-label', `تفعيل ${button.textContent}`) }
  }
  apply()
  document.querySelector('[data-theme-toggle]')?.addEventListener('click', () => {
    theme = theme === 'dark' ? 'light' : 'dark'
    try { localStorage.setItem('edubridge_theme', theme) } catch { /* Keep the current page usable. */ }
    apply()
  })
})()
