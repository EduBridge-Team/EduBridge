export function SpecialistSummary({ doneToday, pending, totalChildren }) {
  return (
    <div className="summary-grid specialist-summary-grid">
      <div className="summary-card specialist-summary-card">
        <div className="num" style={{ color: 'var(--coral-deep)' }}>{pending}</div>
        <div className="lbl">مهام قيد الانتظار</div>
      </div>
      <div className="summary-card specialist-summary-card">
        <div className="num" style={{ color: 'var(--green-deep)' }}>{doneToday}</div>
        <div className="lbl">مهام منجزة (اليوم)</div>
      </div>
      <div className="summary-card specialist-summary-card">
        <div className="num" style={{ color: 'var(--navy)' }}>{totalChildren}</div>
        <div className="lbl">إجمالي الأطفال</div>
      </div>
    </div>
  )
}

function SpecialistChildRow({ approvingId, onApprove, onOpenProgress, row }) {
  const { child, stats } = row
  const hasCurrent = Boolean(stats.current)

  return (
    <div className="progress-row specialist-progress-card">
      <div className="pr-child">
        <div className="avatar specialist-child-avatar">{(child.name || '؟').trim().charAt(0)}</div>
        <div>
          <h3
            className="pr-name clickable"
            onClick={() => onOpenProgress(child)}
          >
            {child.name}
          </h3>
          {child.disability_name && (
            <div className="meta">احتياج: {child.disability_name}</div>
          )}
        </div>
      </div>

      <div className="pr-mid">
        {hasCurrent && (
          <span className="status-chip in_progress">
            🕒 {stats.current.lesson_title}
          </span>
        )}
        <span className="pr-pct">{stats.pct}% ⭐</span>
        {stats.inProgress > 0 && (
          <span className="pr-count orange">{stats.inProgress}</span>
        )}
        {stats.done > 0 && <span className="pr-count green">{stats.done} ✅</span>}
      </div>

      <div className="pr-action">
        {hasCurrent ? (
          <button
            className="btn small specialist-approve-btn"
            disabled={approvingId === child.id}
            onClick={() => onApprove(row)}
          >
            {approvingId === child.id ? 'جارٍ...' : '✔ اعتماد كمنجز'}
          </button>
        ) : (
          <button className="btn small outline" disabled>
            ⏳ بانتظار البدء
          </button>
        )}
      </div>
    </div>
  )
}

export function SpecialistChildrenList({
  approvingId,
  error,
  loading,
  onApprove,
  onOpenProgress,
  onRetry,
  rows,
}) {
  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ تحميل بيانات الأطفال...
      </div>
    )
  }

  if (error) {
    return (
      <div className="state">
        <div className="error-box">{error}</div>
        <button className="btn" style={{ marginTop: 16 }} onClick={onRetry}>
          إعادة المحاولة
        </button>
      </div>
    )
  }

  if (rows.length === 0) return <div className="state">لا يوجد أطفال بعد</div>

  return rows.map((row) => (
    <SpecialistChildRow
      key={row.child.id}
      approvingId={approvingId}
      onApprove={onApprove}
      onOpenProgress={onOpenProgress}
      row={row}
    />
  ))
}
