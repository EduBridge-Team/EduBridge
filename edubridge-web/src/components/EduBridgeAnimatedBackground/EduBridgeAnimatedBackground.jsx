import { useEffect, useRef } from 'react'
import {
  Accessibility,
  Award,
  BookOpen,
  Ear,
  GraduationCap,
  Hand,
  HeartHandshake,
  Laptop,
  Lightbulb,
  Network,
  Pencil,
  School,
  Share2,
  Tablet,
  Users,
  Waypoints,
} from 'lucide-react'
import './EduBridgeAnimatedBackground.css'

const FLOATING_ITEMS = [
  { Icon: BookOpen, label: 'كتاب مفتوح', x: 7, y: 16, size: 48, depth: 0.55, motion: 'float-a', tone: 'blue' },
  { Icon: Accessibility, label: 'إمكانية الوصول', x: 91, y: 14, size: 46, depth: 0.8, motion: 'float-b', tone: 'green' },
  { Icon: GraduationCap, label: 'التعليم', x: 12, y: 40, size: 40, depth: 0.42, motion: 'float-c', tone: 'cyan' },
  { Icon: Ear, label: 'دعم السمع', x: 94, y: 39, size: 38, depth: 0.62, motion: 'float-d', tone: 'blue' },
  { Icon: Pencil, label: 'التعلم', x: 4, y: 66, size: 36, depth: 0.74, motion: 'float-b', tone: 'green' },
  { Icon: Hand, label: 'التواصل والإشارة', x: 88, y: 67, size: 42, depth: 0.48, motion: 'float-a', tone: 'cyan' },
  { Icon: School, label: 'المدرسة', x: 17, y: 82, size: 42, depth: 0.5, motion: 'float-d', tone: 'blue' },
  { Icon: Laptop, label: 'التعلم الرقمي', x: 81, y: 86, size: 44, depth: 0.7, motion: 'float-c', tone: 'green' },
  { Icon: Lightbulb, label: 'المعرفة', x: 27, y: 8, size: 34, depth: 0.35, motion: 'float-d', tone: 'cyan', secondary: true },
  { Icon: Tablet, label: 'التقنية المساندة', x: 73, y: 7, size: 34, depth: 0.38, motion: 'float-b', tone: 'blue', secondary: true },
  { Icon: HeartHandshake, label: 'الدعم الشامل', x: 24, y: 91, size: 34, depth: 0.44, motion: 'float-a', tone: 'green', secondary: true },
  { Icon: Award, label: 'الإنجاز', x: 69, y: 92, size: 32, depth: 0.52, motion: 'float-d', tone: 'cyan', secondary: true },
  { Icon: Network, label: 'الاتصال', x: 2, y: 29, size: 30, depth: 0.32, motion: 'float-c', tone: 'blue', tertiary: true },
  { Icon: Users, label: 'طلاب متصلون', x: 97, y: 27, size: 30, depth: 0.34, motion: 'float-a', tone: 'green', tertiary: true },
  { Icon: Share2, label: 'مشاركة المعرفة', x: 8, y: 53, size: 29, depth: 0.3, motion: 'float-d', tone: 'cyan', tertiary: true },
  { Icon: Waypoints, label: 'مسار التعلم', x: 96, y: 54, size: 29, depth: 0.36, motion: 'float-c', tone: 'blue', tertiary: true },
]

export default function EduBridgeAnimatedBackground({ className = '' }) {
  const rootRef = useRef(null)

  useEffect(() => {
    const root = rootRef.current
    if (!root) return undefined

    const reducedMotion = window.matchMedia?.('(prefers-reduced-motion: reduce)')
    const compact = window.matchMedia?.('(max-width: 900px), (pointer: coarse)')

    if (reducedMotion?.matches || compact?.matches) return undefined

    const nodes = Array.from(root.querySelectorAll('[data-parallax-depth]'))
    let frame = 0
    let targetX = 0
    let targetY = 0
    let currentX = 0
    let currentY = 0

    const render = () => {
      currentX += (targetX - currentX) * 0.08
      currentY += (targetY - currentY) * 0.08

      nodes.forEach((node) => {
        const depth = Number(node.dataset.parallaxDepth || 0)
        node.style.setProperty('--parallax-x', `${(currentX * depth).toFixed(2)}px`)
        node.style.setProperty('--parallax-y', `${(currentY * depth).toFixed(2)}px`)
      })

      if (Math.abs(targetX - currentX) > 0.05 || Math.abs(targetY - currentY) > 0.05) {
        frame = window.requestAnimationFrame(render)
      } else {
        frame = 0
      }
    }

    const queueRender = () => {
      if (!frame) frame = window.requestAnimationFrame(render)
    }

    const handlePointerMove = (event) => {
      const rect = root.getBoundingClientRect()
      const centerX = rect.left + rect.width / 2
      const centerY = rect.top + rect.height / 2
      targetX = ((event.clientX - centerX) / Math.max(rect.width / 2, 1)) * 9
      targetY = ((event.clientY - centerY) / Math.max(rect.height / 2, 1)) * 7
      queueRender()
    }

    const reset = () => {
      targetX = 0
      targetY = 0
      queueRender()
    }

    window.addEventListener('pointermove', handlePointerMove, { passive: true })
    window.addEventListener('blur', reset)

    return () => {
      window.removeEventListener('pointermove', handlePointerMove)
      window.removeEventListener('blur', reset)
      if (frame) window.cancelAnimationFrame(frame)
    }
  }, [])

  return (
    <div
      ref={rootRef}
      className={`edubridge-animated-background ${className}`.trim()}
      aria-hidden="true"
    >
      <div className="edubridge-bg-glow edubridge-bg-glow-a" />
      <div className="edubridge-bg-glow edubridge-bg-glow-b" />

      <svg className="edubridge-bg-connections" viewBox="0 0 1200 620" preserveAspectRatio="none">
        <path d="M 20 118 C 120 58, 220 68, 300 130" />
        <path d="M 1180 112 C 1080 58, 980 72, 900 138" />
        <path d="M 18 500 C 120 552, 220 550, 300 492" />
        <path d="M 1180 490 C 1080 548, 980 544, 900 486" />
        <circle cx="300" cy="130" r="4" />
        <circle cx="900" cy="138" r="4" />
        <circle cx="300" cy="492" r="4" />
        <circle cx="900" cy="486" r="4" />
      </svg>

      <div className="edubridge-bg-field">
        {FLOATING_ITEMS.map((item, index) => {
          const { Icon } = item
          const classes = [
            'edubridge-bg-node',
            item.secondary ? 'is-secondary' : '',
            item.tertiary ? 'is-tertiary' : '',
          ].filter(Boolean).join(' ')

          return (
            <span
              className={classes}
              key={item.label}
              data-parallax-depth={item.depth}
              style={{
                '--node-x': `${item.x}%`,
                '--node-y': `${item.y}%`,
                '--node-size': `${item.size}px`,
                '--node-delay': `${-(index * 1.37)}s`,
              }}
            >
              <span className={`edubridge-bg-icon ${item.motion} tone-${item.tone}`}>
                <Icon strokeWidth={1.7} />
              </span>
            </span>
          )
        })}
      </div>
    </div>
  )
}
