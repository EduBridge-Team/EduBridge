import { Pause, Play, RotateCcw } from 'lucide-react'
import { useEffect, useMemo, useRef, useState } from 'react'

const SPEEDS = [0.5, 0.75, 1, 1.25]
const DEMO_GLB = 'https://threejs.org/examples/models/gltf/RobotExpressive/RobotExpressive.glb'

export default function PSLAvatarPrototype({ sign }) {
  const viewerRef = useRef(null)
  const [playing, setPlaying] = useState(false)
  const [speed, setSpeed] = useState(1)

  const isTriangle = useMemo(
    () => String(sign?.english_label || '').toLowerCase() === 'triangle',
    [sign?.english_label],
  )

  const verifiedMotion = Boolean(
    sign?.animation_url
    && sign?.animation_status === 'verified'
    && ['glb', 'gltf'].includes(String(sign?.animation_format || '').toLowerCase()),
  )

  const source = verifiedMotion ? sign.animation_url : DEMO_GLB
  const animationName = verifiedMotion ? undefined : 'Wave'

  useEffect(() => {
    const viewer = viewerRef.current
    if (!viewer) return

    viewer.timeScale = speed
    if (playing) {
      viewer.play?.({ repetitions: Infinity })
    } else {
      viewer.pause?.()
    }
  }, [playing, speed, source])

  if (!isTriangle && !verifiedMotion) return null

  const restart = () => {
    const viewer = viewerRef.current
    if (!viewer) return
    viewer.currentTime = 0
    viewer.timeScale = speed
    viewer.play?.({ repetitions: Infinity })
    setPlaying(true)
  }

  return (
    <section className="psl-avatar-prototype" aria-label="مشغل شخصية لغة الإشارة ثلاثية الأبعاد">
      <div className="psl-avatar-copy">
        <span className={verifiedMotion ? 'psl-avatar-badge verified' : 'psl-avatar-badge'}>{verifiedMotion ? 'PSL' : '3D Prototype'}</span>
        <div>
          <strong>شخصية EduBridge ثلاثية الأبعاد</strong>
          {verifiedMotion
            ? <p>هذه الحركة مرتبطة بملف GLB موثّق لهذا المدخل.</p>
            : <p>هذا ملف GLB حقيقي لاختبار المشغّل والـrig فقط. حركة العرض ليست إشارة «{sign?.arabic_label}» ولا تُستخدم كمحتوى تعليمي.</p>}
        </div>
      </div>

      <div className="psl-avatar-stage">
        <model-viewer
          ref={viewerRef}
          src={source}
          animation-name={animationName}
          camera-controls
          disable-zoom
          shadow-intensity="1"
          exposure="1"
          interaction-prompt="none"
          aria-label={verifiedMotion ? `شخصية تؤدي إشارة ${sign?.arabic_label}` : 'شخصية ثلاثية الأبعاد تجريبية'}
        />
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
