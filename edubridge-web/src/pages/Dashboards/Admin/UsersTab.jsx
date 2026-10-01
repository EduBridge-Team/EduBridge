import AdminOrganizationAccountForm from './AdminOrganizationAccountForm'
import EmptyState from '../../../components/EmptyState'
import { useCallback, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { Search, UsersRound } from 'lucide-react'
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
  const [activeRole, setActiveRole] = useState('teacher')
  const [editing, setEditing] = useState(null)

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)
    try {
      const [userData, childData] = await Promise.all([
        fetchUsers(),
        fetchChildren(),
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
    total: users.filter((u) => u.role === section.role).length,
  }))

  const visibleGroups = grouped.filter((section) => activeRole === 'all' || section.role === activeRole)
  const showChildren = ['all', 'children'].includes(activeRole)
  const hasResults = visibleGroups.some((section) => section.items.length > 0) || (showChildren && filteredChildren.length > 0)

  return (
    <section className="admin-panel admin-users-panel">
      <div className="admin-overview" aria-label="ملخص الحسابات">
        <article><span>المستخدمون</span><strong>{users.length}</strong></article>
        <article><span>الأطفال</span><strong>{children.length}</strong></article>
        <article><span>بانتظار التوثيق</span><strong>{users.filter((user) => user.verification_status === 'pending').length}</strong></article>
        <article><span>حسابات موثّقة</span><strong>{users.filter((user) => user.verification_status === 'verified').length}</strong></article>
      </div>
      <div className="admin-panel-head admin-users-head">
        <div className="admin-panel-title">
          <span><UsersRound size={20} /></span>
          <div>
            <h3>إدارة المستخدمين</h3>
            <p>استعرض الحسابات والأطفال المرتبطين وعدّل البيانات من نفس الصفحة.</p>
          </div>
        </div>
        <label className="admin-search-wrap">
          <Search size={17} aria-hidden="true" />
          <input
            className="admin-search"
            type="search"
            aria-label="البحث في القائمة الحالية"
            placeholder="ابحث في القائمة الحالية..."
            value={search}
            onChange={(e) => setSearch(e.target.value)}
          />
        </label>
      </div>

      <AdminOrganizationAccountForm onCreated={(user) => {
        setUsers((list) => [...list, user])
        setActiveRole(user.role)
        setSearch('')
      }} />
      <div className="admin-role-filters" role="group" aria-label="عرض حسب الدور">
        {grouped.map((section) => <button key={section.role} type="button" aria-pressed={activeRole === section.role} onClick={() => setActiveRole(section.role)}>{section.label}<span>{section.total}</span></button>)}
        <button type="button" aria-pressed={activeRole === 'children'} onClick={() => setActiveRole('children')}>الأطفال<span>{children.length}</span></button>
        <button type="button" aria-pressed={activeRole === 'all'} onClick={() => setActiveRole('all')}>الكل</button>
      </div>
      {!hasResults ? (
        <EmptyState title="لا توجد نتائج في هذه القائمة" description="امسح البحث أو اختر دورًا آخر لاستعراض الحسابات." actionLabel="عرض جميع الحسابات" onAction={() => { setSearch(''); setActiveRole('all') }} />
      ) : (
        <div className="admin-group-list">
          {visibleGroups.map((section) => (
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

          {showChildren && <AdminChildrenSection
            children={filteredChildren}
            onDelete={removeChild}
            onEdit={(childId) => navigate(`/children/${childId}/edit`)}
          />}
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

