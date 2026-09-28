export function VerificationBadge({ status }) {
  const map = {
    verified: { text: 'موثّق ✓', color: 'green' },
    pending: { text: 'معلّق', color: 'orange' },
    rejected: { text: 'مرفوض', color: 'red' },
  }
  const item = map[status] || map.pending
  return <span className={`vbadge ${item.color}`}>{item.text}</span>
}
