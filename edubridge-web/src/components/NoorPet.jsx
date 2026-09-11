import { useId } from 'react'

export default function NoorPet({ size = 76, className = '' }) {
  const instanceId = useId().replaceAll(':', '')
  const glowId = `noor-glow-${instanceId}`
  const shadowId = `noor-shadow-${instanceId}`

  return (
    <svg
      className={`noor-pet ${className}`.trim()}
      width={size}
      height={size}
      viewBox="0 0 76 76"
      role="img"
      aria-label="نور، المساعد الذكي"
    >
      <defs>
        <filter id={glowId} x="-35%" y="-35%" width="170%" height="170%">
          <feGaussianBlur stdDeviation="4" />
        </filter>
        <filter id={shadowId} x="-30%" y="-80%" width="160%" height="260%">
          <feGaussianBlur stdDeviation="2.5" />
        </filter>
      </defs>

      <ellipse className="noor-pet-shadow" cx="38" cy="68" rx="24" ry="4" filter={`url(#${shadowId})`} />
      <circle className="noor-pet-glow" cx="38" cy="35" r="31" filter={`url(#${glowId})`} />

      <path
        className="noor-pet-body"
        d="M13 30 Q8 13 25 16 Q38 4 51 16 Q68 13 63 30 Q70 54 54 64 Q38 72 22 64 Q6 54 13 30 Z"
      />
      <path className="noor-pet-ear" d="M16 28 L13 10 L28 20 Z" />
      <path className="noor-pet-ear" d="M60 28 L63 10 L48 20 Z" />
      <ellipse className="noor-pet-face" cx="38" cy="39.5" rx="18" ry="15.5" />

      <g className="noor-pet-eyes">
        <circle cx="30" cy="36" r="2.8" />
        <circle cx="46" cy="36" r="2.8" />
      </g>
      <g className="noor-pet-blink">
        <path d="M27 37 H33" />
        <path d="M43 37 H49" />
      </g>

      <path className="noor-pet-beak" d="M34 42 L42 42 L38 47 Z" />
      <circle className="noor-pet-badge" cx="38" cy="58" r="7" />
      <g className="noor-pet-bridge">
        <path d="M33 57.5 A5 3.5 0 0 1 43 57.5" />
        <path d="M32 59 H44" />
      </g>
      <circle className="noor-pet-sparkle" cx="68" cy="13" r="2.2" />
    </svg>
  )
}
