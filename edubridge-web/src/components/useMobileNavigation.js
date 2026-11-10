import { useEffect, useState } from 'react'

const focusable = 'a[href], button:not(:disabled), input:not(:disabled), select:not(:disabled), textarea:not(:disabled), [tabindex="0"]'

// Shared behavior for the public menu and the role portal's mobile drawer.
export function useMobileNavigation({ open, setOpen, panelRef, triggerRef, query, focusOnOpen = false }) {
  const [mobile, setMobile] = useState(() => typeof window !== 'undefined' && Boolean(window.matchMedia?.(query).matches))

  useEffect(() => {
    const media = window.matchMedia(query)
    const update = () => {
      setMobile(media.matches)
      if (!media.matches) setOpen(false)
    }
    update()
    media.addEventListener('change', update)
    return () => media.removeEventListener('change', update)
  }, [query, setOpen])

  useEffect(() => {
    if (!mobile || !open) return
    const panel = panelRef.current
    const trigger = triggerRef.current
    const previousOverflow = document.body.style.overflow
    document.body.style.overflow = 'hidden'
    const controls = () => [...panel.querySelectorAll(focusable)].filter(element => element.getClientRects().length && getComputedStyle(element).visibility !== 'hidden')
    // Disclosure menus keep focus on their trigger; drawers move it inside.
    const focusFrame = focusOnOpen ? window.requestAnimationFrame(() => controls()[0]?.focus()) : null
    const onKeyDown = (event) => {
      if (event.key === 'Escape') {
        event.preventDefault()
        setOpen(false)
        trigger?.focus()
      }
      if (event.key !== 'Tab') return
      const items = controls()
      const first = items[0]
      const last = items.at(-1)
      if (!first) return
      if (event.shiftKey && (document.activeElement === first || !panel.contains(document.activeElement))) {
        event.preventDefault()
        last.focus()
      } else if (!event.shiftKey && (document.activeElement === last || !panel.contains(document.activeElement))) {
        event.preventDefault()
        first.focus()
      }
    }
    document.addEventListener('keydown', onKeyDown)
    return () => {
      if (focusFrame !== null) window.cancelAnimationFrame(focusFrame)
      document.body.style.overflow = previousOverflow
      document.removeEventListener('keydown', onKeyDown)
      if (window.matchMedia(query).matches && panel.contains(document.activeElement)) trigger?.focus()
    }
  }, [focusOnOpen, mobile, open, panelRef, query, setOpen, triggerRef])

  return mobile
}
