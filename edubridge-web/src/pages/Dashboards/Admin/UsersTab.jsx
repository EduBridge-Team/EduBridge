import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { deleteChild, deleteUser, fetchChildren, fetchUsers, getUser } from '../../../api'
import AdminChildrenSection from './AdminChildrenSection'
import AdminRoleSection from './AdminRoleSection'
import EditUserModal from './EditUserModal'
import { ADMIN_ROLE_SECTIONS, countChildrenForUser } from './adminUsersConfig'

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

  const grouped = ADMIN_ROLE_SECTIONS.map((section) => ({
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
                childrenForUser={(user) => countChildrenForUser(children, user)}
                onEdit={setEditing}
                onDelete={remove}
              />
            )
          ))}

          <AdminChildrenSection
            children={filteredChildren}
            onDelete={removeChild}
            onEdit={(childId) => navigate(`/children/${childId}/edit`)}
          />
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

