import { Link } from 'react-router-dom'
import { Inbox } from 'lucide-react'

export default function EmptyState({ title, description, actionLabel, onAction, actionHref }) {
  return (
    <div className="portal-empty">
      <span className="portal-empty-icon" aria-hidden="true"><Inbox size={28} /></span>
      <h3>{title}</h3>
      {description && <p>{description}</p>}
      {actionLabel && actionHref && <Link className="btn outline" to={actionHref}>{actionLabel}</Link>}
      {actionLabel && !actionHref && onAction && <button className="btn outline" type="button" onClick={onAction}>{actionLabel}</button>}
    </div>
  )
}
