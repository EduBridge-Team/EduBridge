import { useEffect, useRef, useState } from 'react'
import { Pause, Play } from 'lucide-react'
import { getToken, getUser } from '../api'
import NoorPet from './NoorPet'

const SIZE = 94
const MARGIN = 14
const DANGER_RADIUS = 250
const CRUISE_SPEED = 0.14

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max)
}

export default function NoorRunnerWidget() {
  const signedIn = Boolean(getToken() && getUser())
  const [enabled, setEnabled] = useState(false)
  const [position, setPosition] = useState({ x: 0, y: 0 })
  const [paused, setPaused] = useState(false)
  const positionRef = useRef(position)
  const cursorRef = useRef(null)
  const velocityRef = useRef({ x: 0.12, y: -0.09 })
  const frameRef = useRef(0)
  const lastTimeRef = useRef(0)
  const focusedRef = useRef(false)
  const pausedRef = useRef(false)

  useEffect(() => {
    positionRef.current = position
  }, [position])

  useEffect(() => {
    pausedRef.current = paused
  }, [paused])

  useEffect(() => {
    if (!signedIn || typeof window === 'undefined') return undefined

    const finePointer = window.matchMedia('(hover: hover) and (pointer: fine)')
    const syncEnabled = () => {
      const active = finePointer.matches
      setEnabled(active)
      if (active) {
        const next = {
          x: clamp(window.innerWidth * 0.58, MARGIN, Math.max(MARGIN, window.innerWidth - SIZE - MARGIN)),
          y: clamp(window.innerHeight * 0.62, MARGIN, Math.max(MARGIN, window.innerHeight - SIZE - MARGIN)),
        }
        positionRef.current = next
        setPosition(next)
      }
    }

    syncEnabled()
    finePointer.addEventListener?.('change', syncEnabled)
    return () => finePointer.removeEventListener?.('change', syncEnabled)
  }, [signedIn])

  useEffect(() => {
    if (!enabled || typeof window === 'undefined') return undefined

    const onPointerMove = (event) => {
      if (event.pointerType && event.pointerType !== 'mouse') return
      cursorRef.current = { x: event.clientX, y: event.clientY }
    }

    const clearCursor = () => {
      cursorRef.current = null
    }

    const keepInsideViewport = () => {
      const current = positionRef.current
      const next = {
        x: clamp(current.x, MARGIN, Math.max(MARGIN, window.innerWidth - SIZE - MARGIN)),
        y: clamp(current.y, MARGIN, Math.max(MARGIN, window.innerHeight - SIZE - MARGIN)),
      }
      positionRef.current = next
      setPosition(next)
    }

    const animate = (time) => {
      frameRef.current = window.requestAnimationFrame(animate)
      if (focusedRef.current || pausedRef.current) {
        lastTimeRef.current = time
        return
      }

      const previous = lastTimeRef.current || time
      const dt = Math.min(32, time - previous)
      lastTimeRef.current = time

      const current = positionRef.current
      let velocity = velocityRef.current
      const centerX = current.x + SIZE / 2
      const centerY = current.y + SIZE / 2
      const cursor = cursorRef.current

      if (cursor) {
        const awayX = centerX - cursor.x
        const awayY = centerY - cursor.y
        const distance = Math.hypot(awayX, awayY)

        if (distance < DANGER_RADIUS) {
          const safeDistance = Math.max(distance, 1)
          const pressure = (DANGER_RADIUS - distance) / DANGER_RADIUS
          const fleeSpeed = 0.24 + pressure * 1.05
          velocity = {
            x: velocity.x * 0.9 + (awayX / safeDistance) * fleeSpeed,
            y: velocity.y * 0.9 + (awayY / safeDistance) * fleeSpeed,
          }
        } else {
          velocity = {
            x: velocity.x * 0.993,
            y: velocity.y * 0.993,
          }
        }
      }

      const speed = Math.hypot(velocity.x, velocity.y)
      if (speed < CRUISE_SPEED) {
        velocity = {
          x: velocity.x + 0.01,
          y: velocity.y - 0.006,
        }
      }

      const maxSpeed = 1.35
      const normalizedSpeed = Math.hypot(velocity.x, velocity.y)
      if (normalizedSpeed > maxSpeed) {
        velocity = {
          x: (velocity.x / normalizedSpeed) * maxSpeed,
          y: (velocity.y / normalizedSpeed) * maxSpeed,
        }
      }

      let nextX = current.x + velocity.x * dt
      let nextY = current.y + velocity.y * dt
      const maxX = Math.max(MARGIN, window.innerWidth - SIZE - MARGIN)
      const maxY = Math.max(MARGIN, window.innerHeight - SIZE - MARGIN)

      if (nextX <= MARGIN || nextX >= maxX) {
        velocity.x *= -0.92
        nextX = clamp(nextX, MARGIN, maxX)
      }
      if (nextY <= MARGIN || nextY >= maxY) {
        velocity.y *= -0.92
        nextY = clamp(nextY, MARGIN, maxY)
      }

      velocityRef.current = velocity
      const next = { x: nextX, y: nextY }
      positionRef.current = next
      setPosition(next)
    }

    window.addEventListener('pointermove', onPointerMove, { passive: true })
    window.addEventListener('blur', clearCursor)
    window.addEventListener('resize', keepInsideViewport)
    document.addEventListener('mouseleave', clearCursor)
    frameRef.current = window.requestAnimationFrame(animate)

    return () => {
      window.removeEventListener('pointermove', onPointerMove)
      window.removeEventListener('blur', clearCursor)
      window.removeEventListener('resize', keepInsideViewport)
      document.removeEventListener('mouseleave', clearCursor)
      if (frameRef.current) window.cancelAnimationFrame(frameRef.current)
      frameRef.current = 0
    }
  }, [enabled])

  if (!signedIn || !enabled) return null

  const openAssistant = () => {
    document.querySelector('.noor-launcher')?.click()
  }

  return (
    <div
      className={`noor-runner-wrap${paused ? ' is-paused' : ''}`}
      style={{ transform: `translate3d(${position.x}px, ${position.y}px, 0)` }}
      onFocusCapture={() => { focusedRef.current = true }}
      onBlurCapture={(event) => {
        if (!event.currentTarget.contains(event.relatedTarget)) focusedRef.current = false
      }}
    >
      <button
        type="button"
        className="noor-runner-widget"
        onClick={openAssistant}
        aria-label="نور المتحركة — افتح المساعد"
        title={paused ? 'نور متوقفة — اضغط لفتح المساعد' : 'نور — تحاول الابتعاد عن مؤشر الماوس'}
      >
        <NoorPet size={SIZE} trackMouse />
      </button>

      <button
        type="button"
        className="noor-runner-toggle"
        onClick={(event) => {
          event.stopPropagation()
          setPaused((value) => !value)
        }}
        aria-label={paused ? 'استئناف حركة نور' : 'إيقاف حركة نور'}
        title={paused ? 'استئناف حركة نور' : 'إيقاف حركة نور'}
      >
        {paused ? <Play size={16} /> : <Pause size={16} />}
      </button>
    </div>
  )
}
