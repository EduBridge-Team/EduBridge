import { useEffect, useRef, useState } from 'react'
import { getToken, getUser } from '../api'
import NoorPet from './NoorPet'

const SIZE = 94
const MARGIN = 14
const DANGER_RADIUS = 250
const CRUISE_SPEED = 0.42

function clamp(value, min, max) {
  return Math.min(Math.max(value, min), max)
}

export default function NoorRunnerWidget() {
  const signedIn = Boolean(getToken() && getUser())
  const [enabled, setEnabled] = useState(false)
  const [position, setPosition] = useState({ x: 0, y: 0 })
  const positionRef = useRef(position)
  const cursorRef = useRef(null)
  const velocityRef = useRef({ x: 0.36, y: -0.28 })
  const frameRef = useRef(0)
  const lastTimeRef = useRef(0)
  const focusedRef = useRef(false)

  useEffect(() => {
    positionRef.current = position
  }, [position])

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
      if (focusedRef.current) {
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
          const fleeSpeed = 0.7 + pressure * 2.8
          velocity = {
            x: velocity.x * 0.72 + (awayX / safeDistance) * fleeSpeed,
            y: velocity.y * 0.72 + (awayY / safeDistance) * fleeSpeed,
          }
        } else {
          velocity = {
            x: velocity.x * 0.985,
            y: velocity.y * 0.985,
          }
        }
      }

      const speed = Math.hypot(velocity.x, velocity.y)
      if (speed < CRUISE_SPEED) {
        velocity = {
          x: velocity.x + 0.035,
          y: velocity.y - 0.018,
        }
      }

      const maxSpeed = 3.8
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
    <button
      type="button"
      className="noor-runner-widget"
      style={{ transform: `translate3d(${position.x}px, ${position.y}px, 0)` }}
      onClick={openAssistant}
      onFocus={() => { focusedRef.current = true }}
      onBlur={() => { focusedRef.current = false }}
      aria-label="نور المتحركة — افتح المساعد"
      title="نور — تحاول الابتعاد عن مؤشر الماوس"
    >
      <NoorPet size={SIZE} trackMouse />
    </button>
  )
}
