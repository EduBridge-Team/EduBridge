// صفحة قائمة الأطفال
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchChildSummary, fetchChildren, getUser } from '../../api'
import GeneralChildrenView from './GeneralChildrenView'
import ParentChildrenView from './ParentChildrenView'
import { useListPage } from '../../hooks/useListPage'
import ListPagination from '../../components/ListPagination'

export default function ChildrenPage() {
  const navigate = useNavigate()
  const me = getUser()
  const isParent = me?.role === 'parent'
  const canAddChild = isParent
  const [summaries, setSummaries] = useState({})
  const [query, setQuery] = useState('')
  const [scope, setScope] = useState('mine')
  const [activeOnly, setActiveOnly] = useState(false)
  const { items: children, loading, error, meta, summary, setPage, reload: load } = useListPage(fetchChildren, 'children', { q: query, active_only: activeOnly ? '1' : '0', ...(me?.role === 'specialist' ? { assigned_only: scope === 'mine' ? '1' : '0', waiting_only: scope === 'waiting' ? '1' : '0' } : {}) })

  useEffect(() => {
    let cancelled = false
    setSummaries({})
    if (isParent && !loading && children.length) {
      Promise.all(children.map(async child => {
        try { return [child.id, (await fetchChildSummary(child.id)).summary || {}] }
        catch { return [child.id, {}] }
      })).then(entries => { if (!cancelled) setSummaries(Object.fromEntries(entries)) })
    }
    return () => { cancelled = true }
  }, [isParent, children, loading])

  if (!isParent) {
    return (
      <div>
        {me?.role === 'specialist' && <div className="toolbar" role="group" aria-label="عرض الطلاب">
          <button className={`btn ${scope === 'mine' ? '' : 'outline'}`} aria-pressed={scope === 'mine'} onClick={() => setScope('mine')}>الطلاب المعيّنون لي</button>
          <button className={`btn ${scope === 'waiting' ? '' : 'outline'}`} aria-pressed={scope === 'waiting'} onClick={() => setScope('waiting')}>قائمة الانتظار</button>
        </div>}
        <label className="pc-search">
          <input value={query} onChange={event => setQuery(event.target.value)} placeholder="ابحث عن طفل أو معلّم..." aria-label="ابحث عن طفل أو معلّم" />
        </label>
        {loading ? <div className="state">جارِ تحميل الأطفال...</div> : error ? (
          <div className="state"><div className="error-box">{error}</div><button className="btn" onClick={load}>إعادة المحاولة</button></div>
        ) : <GeneralChildrenView canAddChild={canAddChild} children={children} navigate={navigate} hasQuery={Boolean(query.trim())} />}
        <ListPagination meta={meta} loading={loading} onPage={setPage} />
      </div>
    )
  }

  return (
    <div>
    <ParentChildrenView
      activeOnly={activeOnly}
      children={children}
      navigate={navigate}
      onToggleActive={() => setActiveOnly((value) => !value)}
      query={query}
      setQuery={setQuery}
      summaries={summaries}
      visibleChildren={children}
      directorySummary={summary}
      loading={loading}
      error={error}
      onRetry={load}
    />
    <ListPagination meta={meta} loading={loading} onPage={setPage} />
    </div>
  )
}
