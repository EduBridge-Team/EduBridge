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
      viewBox="-4 0 148 116"
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

      <ellipse className="noor-pet-shadow" cx="70" cy="108" rx="39" ry="5" filter={`url(#${shadowId})`} />
      <circle className="noor-pet-glow" cx="70" cy="58" r="48" filter={`url(#${glowId})`} />

      <g className="noor-pet-character" ref={characterRef}>
        <g className="noor-pet-ears">
          <path className="noor-pet-ear" style={{ fill: `url(#${bodyGradientId})` }} d="M43 35 C28 34 20 24 23 13 C26 3 42 8 53 22 Z" />
          <path className="noor-pet-ear-inner" style={{ fill: `url(#${blueGradientId})` }} d="M39 29 C32 27 29 21 31 16 C34 12 42 17 47 23 Z" />
          <path className="noor-pet-ear" style={{ fill: `url(#${bodyGradientId})` }} d="M92 25 C104 12 119 11 123 21 C127 31 119 40 106 42 Z" />
          <path className="noor-pet-ear-inner" style={{ fill: `url(#${blueGradientId})` }} d="M101 26 C108 19 116 18 118 23 C120 28 115 34 108 36 Z" />
        </g>

        <path className="noor-pet-headset-band" d="M104 38 C115 41 121 49 120 59" />

        <path
          className="noor-pet-body"
          style={{ fill: `url(#${bodyGradientId})` }}
          d="M40 24 C50 14 61 10 74 10 C91 10 105 18 113 32 C121 47 120 73 111 90 C103 104 88 111 70 111 C51 111 35 104 27 89 C18 73 19 47 27 34 C30 29 35 26 40 24 Z"
        />

        <path className="noor-pet-body-highlight" d="M35 35 C45 21 61 15 77 16 C61 19 48 26 40 38 C31 52 30 71 35 86 C25 70 26 49 35 35 Z" />

        <g className="noor-pet-arm-group">
          <ellipse className="noor-pet-arm" style={{ fill: `url(#${bodyGradientId})` }} cx="25" cy="80" rx="11" ry="17" transform="rotate(-28 25 80)" />
          <path className="noor-pet-arm-shade" d="M27 66 C23 75 25 86 32 93" />
          <ellipse className="noor-pet-arm" style={{ fill: `url(#${bodyGradientId})` }} cx="116" cy="80" rx="11" ry="17" transform="rotate(28 116 80)" />
          <path className="noor-pet-arm-shade" d="M113 66 C117 75 115 86 108 93" />
        </g>

        <g className="noor-pet-head">
          <ellipse className="noor-pet-face-rim" cx="70" cy="61" rx="38" ry="31" />
          <ellipse className="noor-pet-face" style={{ fill: `url(#${faceGradientId})` }} cx="70" cy="61" rx="36" ry="29" />

          <g className="noor-pet-eyes">
            <ellipse style={{ fill: `url(#${blueGradientId})` }} cx="56" cy="57" rx="5.8" ry="7" />
            <ellipse style={{ fill: `url(#${blueGradientId})` }} cx="84" cy="57" rx="5.8" ry="7" />
            <circle className="noor-pet-eye-shine" cx="58" cy="53.8" r="1.8" />
            <circle className="noor-pet-eye-shine" cx="86" cy="53.8" r="1.8" />
          </g>
          <g className="noor-pet-blink">
            <path d="M50 58 H62" />
            <path d="M78 58 H90" />
          </g>

          <circle className="noor-pet-cheek" cx="46" cy="70" r="4.8" />
          <circle className="noor-pet-cheek" cx="94" cy="70" r="4.8" />

          <path className="noor-pet-mouth" style={{ fill: `url(#${blueGradientId})` }} d="M61 70 C67 72 74 72 80 70 C79 80 76 85 70 85 C64 85 61 80 61 70 Z" />
          <path className="noor-pet-mouth-inner" d="M65 79 C68 76 73 76 76 79 C75 82 73 83 70 83 C68 83 66 82 65 79 Z" />
        </g>

        <g className="noor-pet-mitten-group">
          <path className="noor-pet-mitten" transform="translate(-3 -1)" d="M17 79 C10 79 4 75 4 69 C4 64 9 64 13 68 C10 60 13 55 18 56 C22 57 23 63 23 67 C27 62 32 63 34 67 C37 73 31 79 26 82 C23 84 20 83 17 79 Z" />
          <path className="noor-pet-mitten" d="M113 79 C108 74 106 68 110 64 C114 61 118 64 120 68 C120 62 123 58 127 59 C132 60 132 66 129 71 C134 67 139 69 140 74 C141 80 134 84 128 85 C122 87 117 84 113 79 Z" />
        </g>

        <g className="noor-pet-headset">
          <path className="noor-pet-headset-mic" d="M115 70 C114 79 107 86 99 89" />
          <ellipse className="noor-pet-headset-cup-back" cx="114" cy="64" rx="7.5" ry="9.5" />
          <ellipse className="noor-pet-headset-cup-pad" cx="116" cy="64" rx="4.6" ry="6.8" />
          <circle className="noor-pet-badge" style={{ fill: `url(#${blueGradientId})` }} cx="91" cy="88" r="13" />
          <g className="noor-pet-brain">
            <path d="M85 91 C80 91 79 86 82 83 C80 79 84 76 88 78 C90 74 95 75 96 79 C100 78 103 82 101 85 C104 89 100 93 96 92" />
            <path d="M88 82 V96 M95 80 V96 M88 86 H95 M88 92 H94" />
            <circle cx="85" cy="86" r="1.2" />
            <circle cx="97" cy="83" r="1.2" />
            <circle cx="97" cy="91" r="1.2" />
          </g>
        </g>

        <g className="noor-pet-attention">
          <rect x="119" y="10" width="5.5" height="14" rx="2.75" transform="rotate(27 121.75 17)" />
          <rect x="127" y="22" width="5.5" height="13" rx="2.75" transform="rotate(56 129.75 28.5)" />
          <rect x="128" y="37" width="5.5" height="13" rx="2.75" transform="rotate(77 130.75 43.5)" />
        </g>
      </g>
    </svg>
  )
}
