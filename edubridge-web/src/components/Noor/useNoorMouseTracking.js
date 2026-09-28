import { useEffect } from 'react'

const MAX_ROTATE = 5
const MAX_SHIFT = 4
const TRACK_RADIUS = 420

export function useNoorMouseTracking({ characterRef, svgRef, trackMouse }) {
  useEffect(() => {
    if (!trackMouse) return undefined
    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) return undefined

    const svgEl = svgRef.current
    const characterEl = characterRef.current
    if (!svgEl || !characterEl) return undefined

    let frame = 0

    const handleMove = (event) => {
      const rect = svgEl.getBoundingClientRect()
      const centerX = rect.left + rect.width / 2
      const centerY = rect.top + rect.height / 2
      const radius = Math.max(
        260,
        Math.min(TRACK_RADIUS, Math.min(window.innerWidth, window.innerHeight) * 0.55),
      )
      const dx = Math.max(-1, Math.min(1, (event.clientX - centerX) / radius))
      const dy = Math.max(-1, Math.min(1, (event.clientY - centerY) / radius))

      window.cancelAnimationFrame(frame)
      frame = window.requestAnimationFrame(() => {
        characterEl.style.transform =
          `translate(${(dx * MAX_SHIFT).toFixed(2)}px, ${(dy * MAX_SHIFT).toFixed(2)}px) rotate(${(dx * MAX_ROTATE).toFixed(2)}deg)`
      })
    }

    const handleLeave = () => {
      window.cancelAnimationFrame(frame)
      characterEl.style.transform = ''
    }

    window.addEventListener('pointermove', handleMove, { passive: true })
    window.addEventListener('mouseleave', handleLeave)

    return () => {
      window.cancelAnimationFrame(frame)
      window.removeEventListener('pointermove', handleMove)
      window.removeEventListener('mouseleave', handleLeave)
    }
  }, [characterRef, svgRef, trackMouse])
}
