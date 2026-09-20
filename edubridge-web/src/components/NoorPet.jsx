import { useEffect, useId, useRef } from 'react'

const MAX_ROTATE = 5
const MAX_SHIFT = 4
const TRACK_RADIUS = 420

export default function NoorPet({ size = 76, className = '', trackMouse = false }) {
  const instanceId = useId().replaceAll(':', '')
  const glowId = `noor-glow-${instanceId}`
  const shadowId = `noor-shadow-${instanceId}`
  const bodyGradientId = `noor-body-${instanceId}`
  const blueGradientId = `noor-blue-${instanceId}`
  const faceGradientId = `noor-face-${instanceId}`
  const svgRef = useRef(null)
  const characterRef = useRef(null)

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
      const radius = Math.max(260, Math.min(TRACK_RADIUS, Math.min(window.innerWidth, window.innerHeight) * 0.55))
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
  }, [trackMouse])

  return (
    <svg
      ref={svgRef}
      className={`noor-pet ${className}`.trim()}
      width={size}
      height={size}
      viewBox="0 0 120 104"
      role="img"
      aria-label="نور، المساعد الذكي"
    >
      <defs>
        <filter id={glowId} x="-35%" y="-35%" width="170%" height="170%">
          <feGaussianBlur stdDeviation="6" />
        </filter>
        <filter id={shadowId} x="-30%" y="-80%" width="160%" height="260%">
          <feGaussianBlur stdDeviation="3" />
        </filter>
        <linearGradient id={bodyGradientId} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#58ddd2" />
          <stop offset="1" stopColor="#20b7c9" />
        </linearGradient>
        <linearGradient id={blueGradientId} x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#176dcc" />
          <stop offset="1" stopColor="#0b3f96" />
        </linearGradient>
        <radialGradient id={faceGradientId} cx="42%" cy="32%" r="75%">
          <stop offset="0" stopColor="#ffffff" />
          <stop offset="1" stopColor="#f2f9fd" />
        </radialGradient>
      </defs>

      <ellipse className="noor-pet-shadow" cx="59" cy="96" rx="35" ry="5" filter={`url(#${shadowId})`} />
      <circle className="noor-pet-glow" cx="59" cy="51" r="43" filter={`url(#${glowId})`} />

      <g className="noor-pet-character" ref={characterRef}>
        <g className="noor-pet-ears">
          <path className="noor-pet-ear" style={{ fill: `url(#${bodyGradientId})` }} d="M31 29 C18 27 13 18 17 10 C22 2 34 8 43 18 Z" />
          <path className="noor-pet-ear-inner" style={{ fill: `url(#${blueGradientId})` }} d="M29 24 C23 22 20 16 22 12 C25 8 31 12 37 18 Z" />
          <path className="noor-pet-ear" style={{ fill: `url(#${bodyGradientId})` }} d="M82 22 C92 12 103 9 108 17 C112 24 107 33 95 36 Z" />
          <path className="noor-pet-ear-inner" style={{ fill: `url(#${blueGradientId})` }} d="M89 23 C95 17 101 16 103 20 C105 24 101 29 95 31 Z" />
        </g>

        <path
          className="noor-pet-body"
          style={{ fill: `url(#${bodyGradientId})` }}
          d="M31 19 C41 10 53 7 66 8 C80 8 91 15 97 26 C104 39 104 64 94 79 C85 93 71 99 57 99 C42 99 27 93 20 80 C12 66 13 42 20 30 C23 25 26 22 31 19 Z"
        />

      <g className="noor-pet-arm-group">
        <ellipse className="noor-pet-arm" style={{ fill: `url(#${bodyGradientId})` }} cx="18" cy="69" rx="10" ry="15" transform="rotate(-26 18 69)" />
        <path className="noor-pet-mitten" d="M12 66 C7 65 3 61 4 56 C5 52 9 53 12 56 C10 49 12 45 16 45 C20 45 21 51 21 55 C23 51 27 50 30 53 C34 58 29 64 25 68 C21 72 17 73 12 66 Z" />
        <ellipse className="noor-pet-arm" style={{ fill: `url(#${bodyGradientId})` }} cx="101" cy="70" rx="10" ry="15" transform="rotate(24 101 70)" />
        <path className="noor-pet-mitten" d="M97 67 C93 63 90 58 93 54 C96 50 100 52 102 56 C102 51 104 47 108 47 C112 47 113 52 111 57 C114 54 118 54 120 58 C122 63 117 68 112 70 C106 73 101 72 97 67 Z" />
      </g>

      <g className="noor-pet-head">
        <ellipse className="noor-pet-face" style={{ fill: `url(#${faceGradientId})` }} cx="58" cy="53" rx="33" ry="27" />

        <g className="noor-pet-eyes">
          <circle style={{ fill: `url(#${blueGradientId})` }} cx="46" cy="50" r="5" />
          <circle style={{ fill: `url(#${blueGradientId})` }} cx="70" cy="50" r="5" />
          <circle className="noor-pet-eye-shine" cx="48" cy="47.5" r="1.6" />
          <circle className="noor-pet-eye-shine" cx="72" cy="47.5" r="1.6" />
        </g>
        <g className="noor-pet-blink">
          <path d="M41 51 H51" />
          <path d="M65 51 H75" />
        </g>

        <circle className="noor-pet-cheek" cx="38.5" cy="61" r="4.2" />
        <circle className="noor-pet-cheek" cx="77.5" cy="61" r="4.2" />

        <path className="noor-pet-mouth" style={{ fill: `url(#${blueGradientId})` }} d="M50 63 C53 67 56 68 59 68 C62 68 65 67 68 63 C67 72 64 76 59 76 C54 76 51 72 50 63 Z" />
        <path className="noor-pet-mouth-inner" d="M54 70 C57 68 61 68 64 70 C63 73 61 74 59 74 C57 74 55 73 54 70 Z" />
      </g>

      <g className="noor-pet-headset">
        <path className="noor-pet-headset-band" d="M89 39 C101 44 105 55 102 66 C100 71 97 75 93 78" />
        <path className="noor-pet-headset-band noor-pet-headset-thin" d="M93 62 C97 67 94 72 89 76" />
        <circle className="noor-pet-headset-cup" cx="97" cy="57" r="6.2" />
        <path className="noor-pet-headset-mic" d="M97 68 C93 72 88 75 84 77" />
        <circle className="noor-pet-badge" style={{ fill: `url(#${blueGradientId})` }} cx="80" cy="78" r="11.5" />
        <g className="noor-pet-brain">
          <path d="M75 80 C71 80 70 76 72 74 C70 71 73 68 76 69 C78 66 82 67 83 70 C86 69 89 71 88 74 C90 77 87 80 84 80" />
          <path d="M77 73 V83 M83 72 V83 M77 76 H83 M77 81 H82" />
          <circle cx="75" cy="76" r="1.1" />
          <circle cx="84" cy="74" r="1.1" />
          <circle cx="84" cy="81" r="1.1" />
        </g>
      </g>

      <g className="noor-pet-attention">
        <rect x="102" y="8" width="5" height="12" rx="2.5" transform="rotate(26 104.5 14)" />
        <rect x="109" y="18" width="5" height="11" rx="2.5" transform="rotate(55 111.5 23.5)" />
        <rect x="109" y="31" width="5" height="11" rx="2.5" transform="rotate(77 111.5 36.5)" />
      </g>
      </g>
    </svg>
  )
}
