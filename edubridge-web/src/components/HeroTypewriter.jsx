import { useEffect, useLayoutEffect, useRef } from 'react'

const PHRASES = [
  { lead: 'تعليم ذكي وشامل ', highlight: 'لكل طفل' },
  { lead: 'دعم متخصص وفعّال ', highlight: 'لكل قدرة' },
  { lead: 'محتوى تفاعلي ممتع ', highlight: 'لكل عائلة' },
  { lead: 'رفيقك الذكي نور ', highlight: 'بأي وقت' },
]

const TYPE_SPEED = 55
const ERASE_SPEED = 30
const PAUSE_AFTER = 2200
const PAUSE_BEFORE = 450
const START_DELAY = 600

const MAX_FONT_SIZE = 44
const MIN_FONT_SIZE = 16
const MEASURE_FONT_SIZE = 100
const FIT_SAFETY_MARGIN = 0.94

let measureCanvas = null
function measureTextWidth(text, font) {
  if (!measureCanvas) measureCanvas = document.createElement('canvas')
  const context = measureCanvas.getContext('2d')
  context.font = font
  return context.measureText(text).width
}

export default function HeroTypewriter() {
  const h1Ref = useRef(null)
  const leadRef = useRef(null)
  const highlightRef = useRef(null)
  const cursorRef = useRef(null)

  useLayoutEffect(() => {
    const h1El = h1Ref.current
    if (!h1El) return undefined

    const fitFontSize = () => {
      const computed = window.getComputedStyle(h1El)
      const font = `${computed.fontWeight} ${MEASURE_FONT_SIZE}px ${computed.fontFamily}`
      const longestText = PHRASES.reduce((longest, phrase) => {
        const text = phrase.lead + phrase.highlight
        return text.length > longest.length ? text : longest
      }, '')
      const widthAtMeasureSize = measureTextWidth(longestText, font)
      const available = h1El.parentElement.clientWidth * FIT_SAFETY_MARGIN
      const fitted = (available / widthAtMeasureSize) * MEASURE_FONT_SIZE
      const clamped = Math.max(MIN_FONT_SIZE, Math.min(MAX_FONT_SIZE, fitted))
      h1El.style.fontSize = `${clamped}px`
    }

    fitFontSize()

    let resizeTimeout = 0
    const onResize = () => {
      window.clearTimeout(resizeTimeout)
      resizeTimeout = window.setTimeout(fitFontSize, 120)
    }
    window.addEventListener('resize', onResize)

    return () => {
      window.clearTimeout(resizeTimeout)
      window.removeEventListener('resize', onResize)
    }
  }, [])

  useEffect(() => {
    const leadEl = leadRef.current
    const highlightEl = highlightRef.current
    const cursorEl = cursorRef.current
    if (!leadEl || !highlightEl || !cursorEl) return undefined

    if (window.matchMedia('(prefers-reduced-motion: reduce)').matches) {
      leadEl.textContent = PHRASES[0].lead
      highlightEl.textContent = PHRASES[0].highlight
      return undefined
    }

    let phraseIndex = 0
    let leadCount = 0
    let highlightCount = 0
    let timeoutId = 0

    const schedule = (fn, delay) => {
      timeoutId = window.setTimeout(fn, delay)
    }
    const placeCursor = (target) => target.appendChild(cursorEl)

    const tick = (phase) => {
      const phrase = PHRASES[phraseIndex]

      if (phase === 'typing-lead') {
        placeCursor(leadEl)
        if (leadCount < phrase.lead.length) {
          leadCount += 1
          leadEl.textContent = phrase.lead.slice(0, leadCount)
          schedule(() => tick('typing-lead'), TYPE_SPEED)
        } else {
          schedule(() => tick('typing-highlight'), TYPE_SPEED)
        }
        return
      }

      if (phase === 'typing-highlight') {
        placeCursor(highlightEl)
        if (highlightCount < phrase.highlight.length) {
          highlightCount += 1
          highlightEl.textContent = phrase.highlight.slice(0, highlightCount)
          schedule(() => tick('typing-highlight'), TYPE_SPEED)
        } else {
          schedule(() => tick('pause-after'), PAUSE_AFTER)
        }
        return
      }

      if (phase === 'pause-after') {
        schedule(() => tick('erasing-highlight'), 0)
        return
      }

      if (phase === 'erasing-highlight') {
        placeCursor(highlightEl)
        if (highlightCount > 0) {
          highlightCount -= 1
          highlightEl.textContent = phrase.highlight.slice(0, highlightCount)
          schedule(() => tick('erasing-highlight'), ERASE_SPEED)
        } else {
          schedule(() => tick('erasing-lead'), 0)
        }
        return
      }

      if (phase === 'erasing-lead') {
        placeCursor(leadEl)
        if (leadCount > 0) {
          leadCount -= 1
          leadEl.textContent = phrase.lead.slice(0, leadCount)
          schedule(() => tick('erasing-lead'), ERASE_SPEED)
        } else {
          schedule(() => tick('pause-before'), PAUSE_BEFORE)
        }
        return
      }

      phraseIndex = (phraseIndex + 1) % PHRASES.length
      schedule(() => tick('typing-lead'), 0)
    }

    placeCursor(leadEl)
    schedule(() => tick('typing-lead'), START_DELAY)

    return () => window.clearTimeout(timeoutId)
  }, [])

  const fullText = `${PHRASES[0].lead}${PHRASES[0].highlight}`

  return (
    <h1 className="hero-typewriter" ref={h1Ref}>
      <span className="sr-only">{fullText}</span>
      <span aria-hidden="true">
        <span ref={leadRef} />
        <span className="hero-typewriter-highlight" ref={highlightRef} />
        <span ref={cursorRef} className="hero-typewriter-cursor" />
      </span>
    </h1>
  )
}
