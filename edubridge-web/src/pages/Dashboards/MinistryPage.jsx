import { useEffect, useState } from 'react'
import { Navigate } from 'react-router-dom'
import {
  BarChart3,
  BookOpen,
  CheckCircle2,
  ClipboardCheck,
  Landmark,
  Users,
} from 'lucide-react'
import {
  approveMinistryApproval,
  fetchMinistryApprovals,
  fetchMinistryChildren,
  fetchMinistryLessons,
  fetchMinistryProgressStatistics,
  fetchMinistryStatistics,
  fetchMinistryStats,
  fetchMinistryUsers,
  getUser,
  rejectMinistryApproval,
  reviewLessonCurriculum,
} from '../../api'

const TABS = [
  ['lessons', 'المناهج', BookOpen],
  ['approvals', 'الموافقات', ClipboardCheck],
  ['stats', 'الإحصائيات', BarChart3],
  ['users', 'المستخدمون', Users],
  ['children', 'الأطفال', CheckCircle2],
]

function Badge({ status }) {
  const map = {
    approved: { t: 'معتمد ✓', c: 'green' },
    pending: { t: 'بانتظار المراجعة', c: 'orange' },
    rejected: { t: 'مرفوض', c: 'red' },
    assigned: { t: 'مُسند', c: 'green' },
    evaluated: { t: 'مُقيّم', c: 'green' },
  }
  const s = map[status] || { t: status || 'غير محدد', c: 'orange' }
  return <span className={`vbadge ${s.c}`}>{s.t}</span>
}

export default function MinistryPage() {
  const me = getUser()
  const [tab, setTab] = useState('lessons')
  const [filter, setFilter] = useState('pending')
  const [data, setData] = useState({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  const load = async () => {
    setLoading(true)
    setError('')
    try {
      if (tab === 'lessons') {
        const result = await fetchMinistryLessons(filter)
        setData({ lessons: result.lessons || [] })
      } else if (tab === 'approvals') {
        const result = await fetchMinistryApprovals(filter)
        setData({ approvals: result.approvals || [] })
      } else if (tab === 'users') {
        const result = await fetchMinistryUsers()
        setData({ users: result.users || [] })
      } else if (tab === 'children') {
        const result = await fetchMinistryChildren()
        setData({ children: result.children || [] })
      } else {
        const [summary, statistics, progress] = await Promise.all([
          fetchMinistryStats(),
          fetchMinistryStatistics(),
          fetchMinistryProgressStatistics(),
        ])
        setData({ summary, statistics, progress })
      }
    } catch (err) {
      setError(err.message || 'تعذّر تحميل بيانات الوزارة')
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    load()
  }, [tab, filter])

  if (!me || !['ministry', 'admin'].includes(me.role)) {
    return <Navigate to="/" replace />
  }

  const decideLesson = async (id, status) => {
    const note = status === 'rejected' ? prompt('سبب عدم المطابقة (اختياري):') || '' : ''
    try {
      await reviewLessonCurriculum(id, status, note)
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  const decideApproval = async (id, status) => {
    const reason = status === 'rejected' ? prompt('سبب الرفض (اختياري):') || '' : ''
    try {
      if (status === 'approved') await approveMinistryApproval(id)
      else await rejectMinistryApproval(id, reason)
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  const statusFilters = (
    <div className="tabs">
      {['pending', 'approved', 'rejected'].map((status) => (
        <button
          key={status}
          className={filter === status ? 'tab on' : 'tab'}
          onClick={() => setFilter(status)}
        >
          {{ pending: 'معلّقة', approved: 'معتمدة', rejected: 'مرفوضة' }[status]}
        </button>
      ))}
    </div>
  )

  return (
    <div className="container role-dashboard role-ministry">
      <div className="page-title">
        <h2 style={{ display: 'flex', alignItems: 'center', gap: 8 }}>
          <Landmark size={21} /> بوابة الوزارة
        </h2>
      </div>
      <p className="dash-sub">
        إدارة مراجعة المناهج والخطط، متابعة المستخدمين والأطفال، وقراءة مؤشرات التقدّم من مصدر واحد.
      </p>

      <div className="tabs">
        {TABS.map(([key, label, Icon]) => (
          <button key={key} className={tab === key ? 'tab on' : 'tab'} onClick={() => setTab(key)}>
            <Icon size={16} /> {label}
          </button>
        ))}
      </div>

      {(tab === 'lessons' || tab === 'approvals') && statusFilters}
      {error && <div className="error-box">{error}</div>}

      {loading ? (
        <div className="state"><div className="spinner" />جارِ التحميل...</div>
      ) : tab === 'lessons' ? (
        <LessonsSection lessons={data.lessons || []} onDecide={decideLesson} />
      ) : tab === 'approvals' ? (
        <ApprovalsSection approvals={data.approvals || []} onDecide={decideApproval} />
      ) : tab === 'stats' ? (
        <StatsSection data={data} />
      ) : tab === 'users' ? (
        <UsersSection users={data.users || []} />
      ) : (
        <ChildrenSection children={data.children || []} />
      )}
    </div>
  )
}

function LessonsSection({ lessons, onDecide }) {
  if (!lessons.length) return <div className="state">لا توجد دروس في هذه الحالة</div>
  return lessons.map((lesson) => (
    <div key={lesson.id} className="card">
      <div className="ticket-head">
        <h3 style={{ display: 'flex', alignItems: 'center', gap: 6 }}>
          <BookOpen size={17} /> {lesson.title}
        </h3>
        <Badge status={lesson.curriculum_status} />
      </div>
      {lesson.content && <p className="content">{lesson.content}</p>}
      <div className="meta">
        {lesson.education_level && `المستوى: ${lesson.education_level} · `}
        {lesson.disability_name && `الفئة: ${lesson.disability_name} · `}
        {lesson.teacher_name && `المعلّم: ${lesson.teacher_name}`}
      </div>
      {lesson.review_note && <div className="meta">ملاحظة المراجعة: {lesson.review_note}</div>}
      {lesson.curriculum_status !== 'approved' && (
        <div className="actions">
          <button className="btn small success" onClick={() => onDecide(lesson.id, 'approved')}>اعتماد</button>
          {lesson.curriculum_status !== 'rejected' && (
            <button className="btn small danger" onClick={() => onDecide(lesson.id, 'rejected')}>رفض</button>
          )}
        </div>
      )}
    </div>
  ))
}

function ApprovalsSection({ approvals, onDecide }) {
  if (!approvals.length) return <div className="state">لا توجد طلبات موافقة في هذه الحالة</div>
  return approvals.map((approval) => (
    <div key={approval.id} className="card">
      <div className="ticket-head">
        <h3>{approval.child_name || `الطفل #${approval.child_id}`}</h3>
        <Badge status={approval.status} />
      </div>
      <p className="content">{approval.educational_plan}</p>
      <div className="meta">
        مقدّم الطلب: {approval.submitted_by_name || '—'}
        {approval.teacher_name ? ` · المعلّم: ${approval.teacher_name}` : ''}
      </div>
      {approval.review_reason && <div className="meta">سبب المراجعة: {approval.review_reason}</div>}
      {approval.status === 'pending' && (
        <div className="actions">
          <button className="btn small success" onClick={() => onDecide(approval.id, 'approved')}>اعتماد الخطة</button>
          <button className="btn small danger" onClick={() => onDecide(approval.id, 'rejected')}>رفض</button>
        </div>
      )}
    </div>
  ))
}

function StatsSection({ data }) {
  const summary = data.summary || {}
  const stats = data.statistics || {}
  const progress = data.progress || {}
  const cards = [
    ['الأطفال', summary.children_count ?? stats.total_children ?? 0],
    ['المستخدمون', summary.users_count ?? 0],
    ['المدارس/المؤسسات', summary.schools_count ?? 0],
    ['مراجعات المناهج المعلّقة', summary.pending_approvals ?? 0],
    ['الأطفال النشطون', stats.active_children ?? 0],
    ['إنجاز الواجبات', `${stats.homework_completion_rate ?? 0}%`],
    ['جلسات الدعم التعليمي', stats.learning_support_meetings_count ?? 0],
    ['متوسط نتائج الدروس', `${progress.average_score ?? 0}%`],
  ]

  return (
    <>
      <div className="stats-grid">
        {cards.map(([label, value]) => (
          <div className="card" key={label}><div className="meta">{label}</div><h2>{value}</h2></div>
        ))}
      </div>
      <div className="card">
        <h3>حالة التقدّم</h3>
        <p className="meta">
          مكتمل: {progress.completed ?? 0} · قيد التقدّم: {progress.in_progress ?? 0} · لم يبدأ: {progress.not_started ?? 0}
        </p>
      </div>
      <div className="card">
        <h3>حسب نوع الإعاقة</h3>
        {Object.entries(stats.by_disability_type || {}).map(([label, total]) => (
          <div className="meta" key={label}>{label}: {total}</div>
        ))}
      </div>
    </>
  )
}

function UsersSection({ users }) {
  if (!users.length) return <div className="state">لا يوجد مستخدمون</div>
  return users.map((user) => (
    <div className="card" key={user.id}>
      <div className="ticket-head"><h3>{user.name}</h3><span className="vbadge">{user.role}</span></div>
      <div className="meta">{user.email}{user.phone ? ` · ${user.phone}` : ''}</div>
      <div className="meta">التوثيق: {user.verification_status || 'غير محدد'}</div>
    </div>
  ))
}

function ChildrenSection({ children }) {
  if (!children.length) return <div className="state">لا يوجد أطفال</div>
  return children.map((child) => (
    <div className="card" key={child.id}>
      <div className="ticket-head"><h3>{child.name}</h3><Badge status={child.status} /></div>
      <div className="meta">
        العمر: {child.age ?? '—'} · الحالة: {child.disability_type || child.disability_name || 'غير محددة'}
      </div>
      <div className="meta">المعلّم: {child.assigned_teacher_name || 'غير مُسند'}</div>
    </div>
  ))
}
