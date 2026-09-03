// لوحة التحكم الإدارية — أدمن فقط
// ثلاثة تبويبات: جميع المستخدمين · ربط طفل بولي أمر · جميع الدروس
import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import {
  getUser,
  fetchUsers,
  updateUser,
  fetchChildren,
  fetchLessons,
  linkParent,
  deleteUser,
} from '../api'
import { ROLE_NAMES } from '../roles'
import Footer from '../components/Footer'

// أيقونة وصنف لون لكل دور — لتلوين الشارات كما في التصميم
const ROLE_META = {
  admin: { icon: '🛡️', cls: 'role-admin' },
  teacher: { icon: '📚', cls: 'role-teacher' },
  specialist: { icon: '🧩', cls: 'role-specialist' },
  parent: { icon: '👪', cls: 'role-parent' },
  ministry: { icon: '🏛️', cls: 'role-admin' },
  institution: { icon: '🏢', cls: 'role-specialist' },
}

const TABS = [
  { id: 'users', label: '👥 جميع المستخدمين' },
  { id: 'link', label: '🔗 ربط طفل بولي أمر' },
  { id: 'lessons', label: '📚 جميع الدروس' },
]

export default function AdminPage() {
  const me = getUser()
  const [tab, setTab] = useState('users')

  // الحماية: غير الأدمن يُحوّل للصفحة الرئيسية
  if (!me || me.role !== 'admin') {
    return <Navigate to="/" replace />
  }

  return (
    <div>
      <main className="container">
        <div className="page-title">
          <h2>⚙️ لوحة التحكم الإدارية</h2>
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
        {tab === 'link' && <LinkTab />}
        {tab === 'lessons' && <LessonsTab />}
      </main>

      <Footer />
    </div>
  )
}

/* ============ تبويب: جميع المستخدمين ============ */
function UsersTab() {
  const [users, setUsers] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [search, setSearch] = useState('')
  const [editing, setEditing] = useState(null) // المستخدم قيد التعديل

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const data = await fetchUsers()
      setUsers(data.users || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  // بعد حفظ التعديل: نحدّث القائمة محلياً
  const onSaved = (updated) => {
    setUsers((list) => list.map((u) => (u.id === updated.id ? updated : u)))
    setEditing(null)
  }

  // حذف مستخدم (البطاقة 11)
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

  const term = search.trim().toLowerCase()
  const filtered = term
    ? users.filter(
        (u) =>
          (u.name || '').toLowerCase().includes(term) ||
          (u.email || '').toLowerCase().includes(term)
      )
    : users

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

  return (
    <section className="admin-panel">
      <div className="admin-panel-head">
        <h3>👥 إدارة المستخدمين</h3>
        <input
          className="admin-search"
          type="search"
          placeholder="🔍 ابحث عن مستخدم..."
          value={search}
          onChange={(e) => setSearch(e.target.value)}
        />
      </div>

      {filtered.length === 0 ? (
        <div className="state">لا يوجد مستخدمون مطابقون</div>
      ) : (
        <div className="user-grid">
          {filtered.map((u) => {
            const meta = ROLE_META[u.role] || { icon: '👤', cls: 'role-parent' }
            return (
              <div key={u.id} className="user-card">
                <div className="user-card-top">
                  <span className={`role-pill ${meta.cls}`}>
                    {meta.icon} {ROLE_NAMES[u.role] || u.role}
                  </span>
                  <div className="user-avatar">{(u.name || '؟').trim().charAt(0)}</div>
                </div>
                <h4 className="user-name">{u.name}</h4>
                <div className="user-email">{u.email}</div>
                {u.phone && <div className="user-phone">📞 {u.phone}</div>}
                {u.verification_status && (
                  <div className={`user-verify ${u.verification_status}`}>
                    {u.verification_status === 'verified'
                      ? 'موثّق ✓'
                      : u.verification_status === 'rejected'
                        ? 'توثيق مرفوض'
                        : 'بانتظار التوثيق'}
                  </div>
                )}
                <div className="user-card-actions">
                  <button className="btn outline small" onClick={() => setEditing(u)}>
                    تعديل
                  </button>
                  {me?.id !== u.id && (
                    <button className="btn danger small" onClick={() => remove(u)}>
                      حذف
                    </button>
                  )}
                </div>
              </div>
            )
          })}
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
            ✕
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

/* ============ تبويب: ربط طفل بولي أمر ============ */
function LinkTab() {
  const [children, setChildren] = useState([])
  const [parents, setParents] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

  const [childId, setChildId] = useState('')
  const [parentId, setParentId] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const [result, setResult] = useState(null) // {ok, msg}

  const load = async () => {
    setLoading(true)
    setError(null)
    try {
      const [c, p] = await Promise.all([fetchChildren(), fetchUsers('parent')])
      setChildren(c.children || [])
      setParents(p.users || [])
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [])

  const submit = async (e) => {
    e.preventDefault()
    setResult(null)
    if (!childId || !parentId) {
      setResult({ ok: false, msg: 'اختر الطفل وولي الأمر أولاً' })
      return
    }
    setSubmitting(true)
    try {
      await linkParent(childId, parentId)
      const childName = children.find((c) => String(c.id) === String(childId))?.name
      const parentName = parents.find((p) => String(p.id) === String(parentId))?.name
      setResult({ ok: true, msg: `تم ربط «${childName}» بولي الأمر «${parentName}»` })
      setChildId('')
      setParentId('')
    } catch (err) {
      setResult({ ok: false, msg: err.message })
    } finally {
      setSubmitting(false)
    }
  }

  if (loading) {
    return (
      <div className="state">
        <div className="spinner" />
        جارِ التحميل...
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

  return (
    <section className="admin-panel">
      <div className="admin-panel-head">
        <h3>🔗 ربط طفل بولي أمر</h3>
      </div>

      <div className="card" style={{ maxWidth: 560 }}>
        <form onSubmit={submit}>
          <label>الطفل</label>
          <select value={childId} onChange={(e) => setChildId(e.target.value)}>
            <option value="">— اختر الطفل —</option>
            {children.map((c) => (
              <option key={c.id} value={c.id}>
                {c.name}
              </option>
            ))}
          </select>

          <label>ولي الأمر</label>
          <select value={parentId} onChange={(e) => setParentId(e.target.value)}>
            <option value="">— اختر ولي الأمر —</option>
            {parents.map((p) => (
              <option key={p.id} value={p.id}>
                {p.name} ({p.email})
              </option>
            ))}
          </select>

          {result && (
            <div className={result.ok ? 'success-box' : 'error-box'}>{result.msg}</div>
          )}

          <button type="submit" className="btn full" disabled={submitting}>
            {submitting ? 'جارِ الربط...' : '🔗 ربط'}
          </button>
        </form>
      </div>

      {children.length === 0 && (
        <div className="state">لا يوجد أطفال بعد لربطهم.</div>
      )}
      {parents.length === 0 && (
        <div className="state">لا يوجد أولياء أمور مسجّلون بعد.</div>
      )}
    </section>
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
        <h3>📚 جميع الدروس</h3>
      </div>
      {lessons.map((l) => (
        <div key={l.id} className="card">
          <div className="card-row">
            <div className="avatar">📖</div>
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
