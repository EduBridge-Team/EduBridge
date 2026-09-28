import { useId, useRef } from 'react'
import NoorPetArtwork from './NoorPetArtwork'
import { useNoorMouseTracking } from './useNoorMouseTracking'


export default function NoorPet({ size = 76, className = '', trackMouse = false }) {
  const instanceId = useId().replaceAll(':', '')
  const glowId = `noor-glow-${instanceId}`
  const shadowId = `noor-shadow-${instanceId}`
  const bodyGradientId = `noor-body-${instanceId}`
  const blueGradientId = `noor-blue-${instanceId}`
  const faceGradientId = `noor-face-${instanceId}`
  const svgRef = useRef(null)
  const characterRef = useRef(null)

  useNoorMouseTracking({ characterRef, svgRef, trackMouse })

  return (
    <svg
      ref={svgRef}
      className={`noor-pet ${className}`.trim()}
      width={size}
      height={size}
      viewBox="0 0 140 116"
      role="img"
      aria-label="نور، المساعد الذكي"
    >
      <NoorPetArtwork
        blueGradientId={blueGradientId}
        bodyGradientId={bodyGradientId}
        characterRef={characterRef}
        faceGradientId={faceGradientId}
        glowId={glowId}
        shadowId={shadowId}
      />
    </svg>
  )
}
