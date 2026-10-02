import { Pause, Play, RotateCcw } from 'lucide-react'
import { useMemo, useState } from 'react'

const SPEEDS = [0.5, 0.75, 1, 1.25]

export default function PSLAvatarPrototype({ sign }) {
  const [playing, setPlaying] = useState(false)
  const [speed, setSpeed] = useState(1)
  const [cycle, setCycle] = useState(0)

  const isTriangle = useMemo(
    () => String(sign?.english_label || '').toLowerCase() === 'triangle',
    [sign?.english_label],
  )

  if (!isTriangle) return null

  const restart = () => {
    setPlaying(false)
    window.requestAnimationFrame(() => {
      setCycle((value) => value + 1)
      setPlaying(true)
    })
  }

  return (
    <section className="psl-avatar-prototype" aria-label="نموذج شخصية لغة الإشارة">
      <div className="psl-avatar-copy">
        <span className="psl-avatar-badge">Prototype</span>
        <div>
          <strong>شخصية EduBridge للإشارة</strong>
          <p>نموذج حركة تقني فقط لإثبات المشغّل. الحركة الحالية ليست توثيقاً معتمداً لإشارة «مثلث».</p>
        </div>
      </div>

      <div
        key={cycle}
        className={`psl-avatar-stage ${playing ? 'is-playing' : 'is-paused'}`}
        style={{ '--psl-avatar-duration': `${2.4 / speed}s` }}
      >
        <svg viewBox="0 0 300 300" role="img" aria-label="شخصية تجريبية متحركة">
          <defs>
            <linearGradient id="avatar-shirt" x1="0" y1="0" x2="1" y2="1">
              <stop offset="0%" stopColor="#0e8f84" />
              <stop offset="100%" stopColor="#0b6678" />
            </linearGradient>
          </defs>
          <circle cx="150" cy="72" r="35" className="psl-avatar-head" />
          <circle cx="137" cy="68" r="3" className="psl-avatar-eye" />
          <circle cx="163" cy="68" r="3" className="psl-avatar-eye" />
          <path d="M137 86 Q150 94 163 86" className="psl-avatar-mouth" />
          <rect x="111" y="108" width="78" height="102" rx="34" fill="url(#avatar-shirt)" />
          <g className="psl-avatar-arm psl-avatar-arm-right">
            <rect x="176" y="116" width="28" height="86" rx="14" />
            <circle cx="190" cy="207" r="16" className="psl-avatar-hand" />
          </g>
          <g className="psl-avatar-arm psl-avatar-arm-left">
            <rect x="96" y="116" width="28" height="86" rx="14" />
            <circle cx="110" cy="207" r="16" className="psl-avatar-hand" />
          </g>
          <rect x="124" y="205" width="20" height="60" rx="10" className="psl-avatar-leg" />
          <rect x="156" y="205" width="20" height="60" rx="10" className="psl-avatar-leg" />
        </svg>
      </div>

      <div className="psl-avatar-controls">
        <button type="button" onClick={() => setPlaying((value) => !value)}>
          {playing ? <Pause size={18} /> : <Play size={18} />}
          {playing ? 'إيقاف' : 'تشغيل'}
        </button>
        <button type="button" onClick={restart}>
          <RotateCcw size={18} />
          إعادة
        </button>
        <label>
          السرعة
          <select value={speed} onChange={(event) => setSpeed(Number(event.target.value))}>
            {SPEEDS.map((value) => <option key={value} value={value}>{value}x</option>)}
          </select>
        </label>
      </div>
    </section>
  )
}
