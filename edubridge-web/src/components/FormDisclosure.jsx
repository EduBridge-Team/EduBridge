import { useEffect, useRef } from 'react'
import { ChevronDown, Plus } from 'lucide-react'

export default function FormDisclosure({ label, open, onToggle, children }) {
  const panel = useRef(null)
  useEffect(() => {
    if (!open) return
    panel.current?.scrollIntoView({ block: 'start', behavior: 'instant' })
    panel.current?.querySelector('input, select, textarea')?.focus({ preventScroll: true })
  }, [open])
  return (
    <details ref={panel} className="form-disclosure" open={open} onToggle={(event) => onToggle(event.currentTarget.open)}>
      <summary><Plus size={18} aria-hidden="true" /><span>{label}</span><ChevronDown size={18} aria-hidden="true" /></summary>
      <div className="form-disclosure-content">{children}</div>
    </details>
  )
}
