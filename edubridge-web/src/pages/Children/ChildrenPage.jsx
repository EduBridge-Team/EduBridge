// صفحة قائمة الأطفال
import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchChildSummary, fetchChildren, getUser } from '../../api'
import GeneralChildrenView from './GeneralChildrenView'
import ParentChildrenView from './ParentChildrenView'

export default function ChildrenPage() {
  const navigate = useNavigate()
  const me = getUser()
  const isParent = me?.role === 'parent'
  const isAdmin = me?.role === 'admin'
  const canAddChild = isParent || isAdmin
  const [children, setChildren] = useState([])
  const [summaries, setSummaries] = useState({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [query, setQuery] = useState('')
  const [activeOnly, setActiveOnly] = useState(false)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchChildren()
      const kids = data.children || []
      setChildren(kids)

      if (isParent && kids.length) {
        const entries = await Promise.all(kids.map(async (child) => {
          try {
            const result = await fetchChildSummary(child.id)
            return [child.id, result.summary || {}]
          } catch {
            return [child.id, {}]
          }
        }))
        setSummaries(Object.fromEntries(entries))
      }
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [isParent])

  useEffect(() => {
    load()
  }, [load])

  const visibleChildren = useMemo(() => {
    const normalizedQuery = query.trim().toLowerCase()
    return children.filter((child) => {
      const matchesQuery = !normalizedQuery || [
        child.name,
        child.assigned_teacher_name,
        child.disability_name,
        child.disability_type,
      ].filter(Boolean).some((value) => String(value).toLowerCase().includes(normalizedQuery))

      const matchesStatus = !activeOnly || ['assigned', 'evaluated'].includes(child.status)
      return matchesQuery && matchesStatus
    })
  }, [children, query, activeOnly])

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ تحميل الأطفال...
      </div>
    )
  }

  if (error) {
    return (
      <div className="state">
        <div className="error-box">{error}</div>
        <button className="btn" style={{ marginTop: 16 }} onClick={load}>
          إعادة المحاولة
        </button>
      </div>
    )
  }

  if (!isParent) {
    return (
      <GeneralChildrenView
        canAddChild={canAddChild}
        children={children}
        navigate={navigate}
      />
    )
  }

  return (
    <ParentChildrenView
      activeOnly={activeOnly}
      children={children}
      navigate={navigate}
      onToggleActive={() => setActiveOnly((value) => !value)}
      query={query}
      setQuery={setQuery}
      summaries={summaries}
      visibleChildren={visibleChildren}
    />
  )
}
