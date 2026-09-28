import { Pause, Play } from 'lucide-react'
import { getToken, getUser } from '../../api'
import NoorPet from './NoorPet'
import { SIZE, useNoorRunnerMotion } from './useNoorRunnerMotion'

export default function NoorRunnerWidget() {
  const signedIn = Boolean(getToken() && getUser())
  const {
    enabled,
    focusedRef,
    paused,
    position,
    togglePaused,
  } = useNoorRunnerMotion({ signedIn })

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
          togglePaused()
        }}
        aria-label={paused ? 'استئناف حركة نور' : 'إيقاف حركة نور'}
        title={paused ? 'استئناف حركة نور' : 'إيقاف حركة نور'}
      >
        {paused ? <Play size={16} /> : <Pause size={16} />}
      </button>
    </div>
  )
}
