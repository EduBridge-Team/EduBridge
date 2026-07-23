// صفحة قائمة الأطفال
import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { fetchChildren } from '../api'

export default function ChildrenPage() {
  const navigate = useNavigate()
  const [children, setChildren] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchChildren()
      setChildren(data.children || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  // معالجة الحالات: تحميل / خطأ / فارغ
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
  if (children.length === 0) {
    return <div className="state">لا يوجد أطفال بعد</div>
  }

  return (
    <div>
      <div className="page-title">
        <h2>الأطفال</h2>
      </div>
      {children.map((child) => (
        <div
          key={child.id}
          className="card clickable"
          onClick={() =>
            navigate(`/children/${child.id}/lessons`, {
              state: { childName: child.name },
            })
          }
        >
          <div className="card-row">
            <div className="avatar">🧒</div>
            <div>
              <h3>{child.name}</h3>
              {child.notes && <div className="meta">{child.notes}</div>}
            </div>
          </div>
        </div>
      ))}
    </div>
  )
}
