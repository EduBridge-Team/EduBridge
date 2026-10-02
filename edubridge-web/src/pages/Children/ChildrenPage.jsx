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
  const isAdmin = me?.role === 'admin'
  const canAddChild = isParent || isAdmin
  const [summaries, setSummaries] = useState({})
  const [query, setQuery] = useState('')
  const [activeOnly, setActiveOnly] = useState(false)
  const { items: children, loading, error, meta, summary, setPage, reload: load } = useListPage(fetchChildren, 'children', { q: query, active_only: activeOnly ? '1' : '0' })

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
        <label className="pc-search">
          <input value={query} onChange={event => setQuery(event.target.value)} placeholder="ابحث عن طفل أو معلّم..." aria-label="ابحث عن طفل أو معلّم" />
        </label>
        {loading ? <div className="state">جارِ تحميل الأطفال...</div> : error ? (
          <div className="state"><div className="error-box">{error}</div><button className="btn" onClick={load}>إعادة المحاولة</button></div>
        ) : <GeneralChildrenView canAddChild={canAddChild} children={children} navigate={navigate} />}
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
