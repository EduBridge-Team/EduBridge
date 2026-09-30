// Wait for the routed page to mount before scrolling beneath the sticky header.
export function scheduleHashScroll(hash, { window: browser = window, document: page = document } = {}) {
  if (!hash || hash === '#') return () => {}
  let id
  try { id = decodeURIComponent(hash.slice(1)) } catch { return () => {} }
  let frame
  let attempts = 0
  let cancelled = false
  const scroll = () => {
    if (cancelled) return
    const target = page.getElementById(id)
    if (!target) {
      if (++attempts < 60) frame = browser.requestAnimationFrame(scroll)
      return
    }
    const headerHeight = page.querySelector('.topbar')?.getBoundingClientRect().height || 0
    const top = Math.max(0, target.getBoundingClientRect().top + browser.scrollY - headerHeight - 16)
    const reducedMotion = browser.matchMedia?.('(prefers-reduced-motion: reduce)').matches
    browser.scrollTo({ top, behavior: reducedMotion ? 'instant' : 'smooth' })
  }
  frame = browser.requestAnimationFrame(scroll)
  return () => { cancelled = true; browser.cancelAnimationFrame(frame) }
}
