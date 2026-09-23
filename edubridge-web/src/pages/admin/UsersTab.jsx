import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Pencil, Trash2 } from 'lucide-react'
import { deleteChild, deleteUser, fetchChildren, fetchUsers, getUser } from '../../api'
import AdminRoleSection from './AdminRoleSection'
import EditUserModal from './EditUserModal'

const ROLE_SECTIONS = [
  { role: 'teacher', label: 'المعلمون', icon: '👨‍🏫', tone: 'teacher' },
  { role: 'specialist', label: 'المختصون', icon: '🧩', tone: 'specialist' },
  { role: 'parent', label: 'أولياء الأمور', icon: '👪', tone: 'parent' },
  { role: 'ministry', label: 'الوزارة', icon: '🏛️', tone: 'ministry' },
  { role: 'institution', label: 'المؤسسات', icon: '🏢', tone: 'institution' },
  { role: 'admin', label: 'الإدارة', icon: '🛡️', tone: 'admin' },
]

export default function UsersTab() {
  const navigate = useNavigate()
  const [users, setUsers] = useState([])
  const [children, setChildren] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [search, setSearch] = useState('')
  const [editing, setEditing] = useState(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [userData, childData] = await Promise.all([
        fetchUsers(),
        fetchChildren().catch(() => ({ children: [] })),
      ])
      setUsers(userData.users || [])
      setChildren(childData.children || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  const onSaved = (updated) => {
    setUsers((list) => list.map((u) => (u.id === updated.id ? updated : u)))
    setEditing(null)
  }

  const me = getUser()
  const remove = async (u) => {
    if (!window.confirm(`حذف المستخدم "${u.name}" نهائياً؟`)) return
    try {
      await deleteUser(u.id)
      setUsers((list) => list.filter((x) => x.id !== u.id))
    } catch (err) {
      setError(err.message)
    }
  }

  const removeChild = async (child) => {
    if (!window.confirm(`حذف الطفل "${child.name}" نهائياً؟`)) return
    try {
      await deleteChild(child.id)
      setChildren((list) => list.filter((item) => item.id !== child.id))
    } catch (err) {
      setError(err.message)
    }
  }

  const term = search.trim().toLowerCase()
  const matches = (value) => (value || '').toString().toLowerCase().includes(term)
  const filteredUsers = term
    ? users.filter((u) => matches(u.name) || matches(u.email) || matches(u.phone))
    : users
  const filteredChildren = term
    ? children.filter((child) => matches(child.name))
    : children

  const childrenForUser = (user) => {
    const role = user.role
    const id = user.id
    return children.filter((child) => {
      if (role === 'teacher') return child.assigned_teacher_id === id
      if (role === 'specialist') {
        return child.assigned_specialist_id === id || child.specialist_id === id
      }
      if (role === 'parent') {
        return child.parent_id === id || child.user_id === id
      }
      return false
    }).length
  }

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ تحميل المستخدمين...
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

  const grouped = ROLE_SECTIONS.map((section) => ({
    ...section,
    items: filteredUsers.filter((u) => u.role === section.role),
  }))

  const hasResults = grouped.some((section) => section.items.length > 0) || filteredChildren.length > 0

  return (
    <section className="admin-panel admin-users-panel">
      <div className="admin-panel-head admin-users-head">
        <div>
          <h3>👥 إدارة المستخدمين</h3>
        </div>
        <label className="admin-search-wrap">
          <span aria-hidden="true">⌕</span>
          <input
            className="admin-search"
            type="search"
            placeholder="ابحث بالاسم أو البريد..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </label>
      </div>

      {!hasResults ? (
        <div className="state">لا توجد نتائج مطابقة</div>
      ) : (
        <div className="admin-group-list">
          {grouped.map((section) => (
            section.items.length > 0 && (
              <AdminRoleSection
                key={section.role}
                section={section}
                users={section.items}
                currentUserId={me?.id}
                childrenForUser={childrenForUser}
                onEdit={setEditing}
                onDelete={remove}
              />
            )
          ))}

          {filteredChildren.length > 0 && (
            <section className="admin-role-section tone-children">
              <div className="admin-role-heading">
                <div className="admin-role-heading-title">
                  <span className="admin-role-heading-icon">🧒</span>
                  <h4>الأطفال</h4>
                </div>
                <span className="admin-role-count">{filteredChildren.length}</span>
              </div>
              <div className="admin-children-grid">
                {filteredChildren.map((child) => (
                  <article className="admin-child-card" key={child.id}>
                    <div className="admin-child-avatar">
                      {(child.name || '؟').trim().charAt(0)}
                    </div>
                    <div className="admin-child-copy">
                      <strong>{child.name || 'طفل'}</strong>
                      <small>
                        {child.age ? `العمر: ${child.age} سنوات` : 'العمر غير محدد'}
                        {child.disability_name ? ` • ${child.disability_name}` : child.status ? ` • ${child.status}` : ''}
                      </small>
                      {child.assigned_teacher_name && (
                        <small className="admin-child-teacher">👨‍🏫 {child.assigned_teacher_name}</small>
                      )}
                    </div>
                    <div className="admin-child-actions">
                      <button
                        className="admin-icon-action edit"
                        onClick={() => navigate(`/children/${child.id}/edit`)}
                        aria-label={`تعديل ${child.name || 'الطفل'}`}
                        title="تعديل الطفل"
                      >
                        <Pencil size={19} strokeWidth={2.35} />
                      </button>
                      <button
                        className="admin-icon-action delete"
                        onClick={() => removeChild(child)}
                        aria-label={`حذف ${child.name || 'الطفل'}`}
                        title="حذف الطفل"
                      >
                        <Trash2 size={19} strokeWidth={2.35} />
                      </button>
                    </div>
                  </article>
                ))}
              </div>
            </section>
          )}
        </div>
      )}

      {editing && (
        <EditUserModal
          user={editing}
          onClose={() => setEditing(null)}
          onSaved={onSaved}
        />
      )}
    </section>
  )
}

