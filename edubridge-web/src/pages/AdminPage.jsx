// لوحة التحكم الإدارية — أدمن فقط
// تبويبان: المستخدمون المصنّفون · جميع الدروس
import { useEffect, useState } from 'react'
import { Navigate, useNavigate } from 'react-router-dom'
import {
  getUser,
  fetchUsers,
  updateUser,
  fetchChildren,
  fetchLessons,
  deleteUser,
  deleteChild,
} from '../api'
import { ROLE_NAMES } from '../roles'
import { Settings, Library, Phone, X, BookOpen, Pencil, Trash2 } from 'lucide-react'
import Footer from '../components/Footer'

const ROLE_META = {
  admin: { icon: '🛡️', cls: 'role-admin' },
  teacher: { icon: '👨‍🏫', cls: 'role-teacher' },
  specialist: { icon: '🧩', cls: 'role-specialist' },
  parent: { icon: '👪', cls: 'role-parent' },
  ministry: { icon: '🏛️', cls: 'role-ministry' },
  institution: { icon: '🏢', cls: 'role-institution' },
}

const ROLE_SECTIONS = [
  { role: 'teacher', label: 'المعلمون', icon: '👨‍🏫', tone: 'teacher' },
  { role: 'specialist', label: 'المختصون', icon: '🧩', tone: 'specialist' },
  { role: 'parent', label: 'أولياء الأمور', icon: '👪', tone: 'parent' },
  { role: 'ministry', label: 'الوزارة', icon: '🏛️', tone: 'ministry' },
  { role: 'institution', label: 'المؤسسات', icon: '🏢', tone: 'institution' },
  { role: 'admin', label: 'الإدارة', icon: '🛡️', tone: 'admin' },
]

const TABS = [
  { id: 'users', label: 'المستخدمون' },
  { id: 'lessons', label: 'الدروس' },
]

export default function AdminPage() {
  const me = getUser()
  const [tab, setTab] = useState('users')

  // الحماية: غير الأدمن يُحوّل للصفحة الرئيسية
  if (!me || me.role !== 'admin') {
    return <Navigate to="/" replace />
  }

  return (
    <div className="role-page role-admin">
      <main className="container role-dashboard">
        <div className="page-title">
          <h2 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
            <Settings size={22} /> لوحة التحكم الإدارية
          </h2>
        </div>

        {/* شريط التبويبات */}
        <div className="admin-tabs" role="tablist">
          {TABS.map((t) => (
            <button
              key={t.id}
              role="tab"
              aria-selected={tab === t.id}
              className={`admin-tab ${tab === t.id ? 'active' : ''}`}
              onClick={() => setTab(t.id)}
            >
              {t.label}
            </button>
          ))}
        </div>

        {tab === 'users' && <UsersTab />}
        {tab === 'lessons' && <LessonsTab />}
      </main>

      <Footer />
    </div>
  )
}

/* ============ تبويب: المستخدمون المصنّفون ============ */
function UsersTab() {
  const navigate = useNavigate()
  const [users, setUsers] = useState([])
  const [children, setChildren] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [search, setSearch] = useState('')
  const [editing, setEditing] = useState(null)

  const load = async () => {
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
  }

  useEffect(() => {
    load()
  }, [])

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
          <p>مصنّفون حسب الدور مثل تطبيق EduBridge</p>
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

function AdminRoleSection({ section, users, currentUserId, childrenForUser, onEdit, onDelete }) {
  return (
    <section className={`admin-role-section tone-${section.tone}`}>
      <div className="admin-role-heading">
        <div className="admin-role-heading-title">
          <span className="admin-role-heading-icon">{section.icon}</span>
          <h4>{section.label}</h4>
        </div>
        <span className="admin-role-count">{users.length}</span>
      </div>

      <div className="admin-role-users">
        {users.map((user) => {
          const meta = ROLE_META[user.role] || { icon: '👤', cls: 'role-parent' }
          const linkedChildren = childrenForUser(user)
          return (
            <article key={user.id} className="admin-user-row">
              <div className="admin-user-avatar">
                {(user.name || '؟').trim().charAt(0)}
              </div>

              <div className="admin-user-main">
                <div className="admin-user-title">
                  <strong>{user.name}</strong>
                  <span className={`role-pill ${meta.cls}`}>
                    {ROLE_NAMES[user.role] || user.role}
                  </span>
                </div>
                <span className="admin-user-email">{user.email}</span>
                {user.phone && (
                  <span className="admin-user-phone">
                    <Phone size={13} /> {user.phone}
                  </span>
                )}
                {user.verification_status && (
                  <span className={`user-verify ${user.verification_status}`}>
                    {user.verification_status === 'verified'
                      ? 'موثّق ✓'
                      : user.verification_status === 'rejected'
                        ? 'توثيق مرفوض'
                        : 'بانتظار التوثيق'}
                  </span>
                )}
              </div>

              {['teacher', 'specialist', 'parent'].includes(user.role) && (
                <span className="admin-linked-count" title="عدد الأطفال المرتبطين">
                  {linkedChildren} 👶
                </span>
              )}

              <div className="admin-user-actions">
                <button
                  className="admin-icon-action edit"
                  onClick={() => onEdit(user)}
                  aria-label={`تعديل ${user.name}`}
                  title="تعديل"
                >
                  <Pencil size={19} strokeWidth={2.35} />
                </button>
                {currentUserId !== user.id && (
                  <button
                    className="admin-icon-action delete"
                    onClick={() => onDelete(user)}
                    aria-label={`حذف ${user.name}`}
                    title="حذف"
                  >
                    <Trash2 size={19} strokeWidth={2.35} />
                  </button>
                )}
              </div>
            </article>
          )
        })}
      </div>
    </section>
  )
}

/* ============ نافذة تعديل مستخدم ============ */
function EditUserModal({ user, onClose, onSaved }) {
  const [name, setName] = useState(user.name || '')
  const [email, setEmail] = useState(user.email || '')
  const [role, setRole] = useState(user.role || 'parent')
  const [phone, setPhone] = useState(user.phone || '')
  const [saving, setSaving] = useState(false)
  const [error, setError] = useState(null)

  const save = async (e) => {
    e.preventDefault()
    setSaving(true)
    setError(null)
    try {
      const data = await updateUser(user.id, { name, email, role, phone })
      onSaved(data.user)
    } catch (err) {
      setError(err.message)
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="modal-overlay" onClick={onClose}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <div className="modal-head">
          <h3>تعديل المستخدم</h3>
          <button className="modal-close" onClick={onClose} aria-label="إغلاق">
            <X size={20} />
          </button>
        </div>
        <form onSubmit={save}>
          <label>الاسم</label>
          <input value={name} onChange={(e) => setName(e.target.value)} required />

          <label>البريد الإلكتروني</label>
          <input
            type="email"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
            required
          />

          <label>الدور</label>
          <select value={role} onChange={(e) => setRole(e.target.value)}>
            {Object.entries(ROLE_NAMES).map(([value, label]) => (
              <option key={value} value={value}>
                {label}
              </option>
            ))}
          </select>

          <label>رقم الهاتف</label>
          <input
            value={phone}
            onChange={(e) => setPhone(e.target.value)}
            placeholder="اختياري"
          />

          {error && <div className="error-box">{error}</div>}

          <div className="modal-actions">
            <button type="button" className="btn outline" onClick={onClose}>
              إلغاء
            </button>
            <button type="submit" className="btn success" disabled={saving}>
              {saving ? 'جارِ الحفظ...' : 'حفظ'}
            </button>
          </div>
        </form>
      </div>
    </div>
  )
}

/* ============ تبويب: جميع الدروس ============ */
function LessonsTab() {
  const [lessons, setLessons] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchLessons()
      setLessons(data.lessons || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ تحميل الدروس...
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
  if (lessons.length === 0) {
    return <div className="state">لا توجد دروس بعد</div>
  }

  return (
    <section className="admin-panel">
      <div className="admin-panel-head">
        <h3 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Library size={20} /> جميع الدروس
        </h3>
      </div>
      {lessons.map((l) => (
        <div key={l.id} className="card">
          <div className="card-row">
            <div className="avatar"><BookOpen size={22} /></div>
            <div>
              <h3>{l.title}</h3>
              {l.content && <div className="meta">{l.content}</div>}
            </div>
          </div>
        </div>
      ))}
    </section>
  )
}
