import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  ArrowLeft, BarChart3, Bell, BookOpen, CalendarDays, ChevronDown, Home, MessageCircle,
  PlayCircle, Plus, Search, Settings, Sparkles, Users,
} from 'lucide-react'
import {
  fetchChildLessons,
  fetchChildSummary,
  fetchChildren,
  fetchConversations,
  fetchUnreadNotificationsCount,
  getUser,
} from '../api'
import NoorPet from '../components/NoorPet'
import ParentProgressSection from './parent-dashboard/ParentProgressSection'
import { useDashboardSidebarSync, useParentDashboardPageClass, useSharedSidebarSync } from './parent-dashboard/hooks'
import { KID_COLORS, STATUS, clampPercent, lessonTimeLabel } from './parent-dashboard/utils'
import './ParentDashboard.css'

export default function ParentDashboard() {
  const navigate = useNavigate()
  const user = getUser()

  const [children, setChildren] = useState([])
  const [unread, setUnread] = useState(0)
  const [summaries, setSummaries] = useState({})
  const [conversations, setConversations] = useState([])
  const [lessons, setLessons] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [query, setQuery] = useState('')

  const load = useCallback(async () => {
    setLoading(true)
    setError(null)

    try {
      const [childrenData, unreadData, conversationData] = await Promise.all([
        fetchChildren(),
        fetchUnreadNotificationsCount().catch(() => ({ count: 0 })),
        fetchConversations().catch(() => ({ conversations: [] })),
      ])

      const kids = childrenData.children || []
      setChildren(kids)
      setUnread(unreadData.count || 0)
      setConversations(conversationData.conversations || [])

      const summaryEntries = await Promise.all(
        kids.map(async (child) => {
          try {
            const data = await fetchChildSummary(child.id)
            return [child.id, data.summary || {}]
          } catch {
            return [child.id, {}]
          }
        }),
      )
      setSummaries(Object.fromEntries(summaryEntries))

      if (kids[0]) {
        try {
          const data = await fetchChildLessons(kids[0].id)
          setLessons(data.lessons || [])
        } catch {
          setLessons([])
        }
      } else {
        setLessons([])
      }
    } catch (err) {
      setError(err.message)
    } finally {
      setLoading(false)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  useParentDashboardPageClass()
  useDashboardSidebarSync({ loading, childrenCount: children.length, summaries })
  useSharedSidebarSync({ loading, childrenCount: children.length, summaries })

  const dashboardStats = useMemo(() => {
    let done = 0
    let inProgress = 0
    let notStarted = 0
    const scores = []

    Object.values(summaries).forEach((summary) => {
      done += Number(summary.done || 0)
      inProgress += Number(summary.in_progress || 0)
      notStarted += Number(summary.not_started || 0)
      if (summary.avg_score != null && Number.isFinite(Number(summary.avg_score))) {
        scores.push(Number(summary.avg_score))
      }
    })

    const totalLessons = done + inProgress + notStarted
    const completion = totalLessons ? (done / totalLessons) * 100 : 0
    const engagement = totalLessons ? ((done + inProgress) / totalLessons) * 100 : 0
    const avgScore = scores.length ? scores.reduce((sum, score) => sum + score, 0) / scores.length : 0
    const supported = children.filter((child) => ['assigned', 'evaluated'].includes(child.status)).length
    const supportRate = children.length ? (supported / children.length) * 100 : 0

    return {
      completion: clampPercent(completion),
      engagement: clampPercent(engagement),
      avgScore: clampPercent(avgScore),
      supportRate: clampPercent(supportRate),
      done,
      totalLessons,
    }
  }, [children, summaries])

  const normalizedQuery = query.trim().toLowerCase()
  const visibleChildren = normalizedQuery
    ? children.filter((child) => [child.name, child.assigned_teacher_name, child.disability_name, child.disability_type]
        .filter(Boolean)
        .some((value) => String(value).toLowerCase().includes(normalizedQuery)))
    : children

  const visibleLessons = normalizedQuery
    ? lessons.filter((lesson) => String(lesson.title || '').toLowerCase().includes(normalizedQuery))
    : lessons

  const openNoor = () => {
    const launcher = document.querySelector('.noor-launcher')
    if (launcher) {
      launcher.click()
      return
    }
    navigate('/support')
  }

  const navItems = [
    { label: 'الرئيسية', icon: <Home size={21} />, onClick: () => navigate('/parent'), active: true },
    { label: 'أطفالي', icon: <Users size={21} />, onClick: () => navigate('/children') },
    { label: 'الدروس', icon: <BookOpen size={21} />, onClick: () => navigate('/lessons') },
    { label: 'التقدم', icon: <BarChart3 size={21} />, onClick: () => children[0] && navigate(`/children/${children[0].id}/progress`, { state: { childName: children[0].name } }) },
    { label: 'المحادثات', icon: <MessageCircle size={21} />, onClick: () => navigate('/conversations'), badge: conversations.length },
    { label: 'الإعدادات', icon: <Settings size={21} />, onClick: () => navigate('/accessibility') },
  ]

  return (
    <div className="parent-dashboard-v2" dir="rtl">
      <aside className="pd-sidebar" aria-label="قائمة ولي الأمر">
        <button className="pd-brand" onClick={() => navigate('/parent')} aria-label="EduBridge">
          <img src="/edubridge-icon.png" alt="" />
          <span>EduBridge</span>
        </button>

        <nav className="pd-side-nav">
          {navItems.map((item) => (
            <button
              key={item.label}
              className={item.active ? 'active' : ''}
              onClick={item.onClick}
              title={item.label}
              aria-label={item.label}
              disabled={item.label === 'التقدم' && !children[0]}
            >
              {item.icon}
              <span>{item.label}</span>
              {item.badge > 0 && <em>{Math.min(item.badge, 99)}</em>}
            </button>
          ))}
        </nav>

      </aside>

      <div className="pd-main">
        <header className="pd-toolbar">
          <label className="pd-search">
            <Search size={20} />
            <input
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="ابحث عن طفل أو درس..."
            />
          </label>

          <button className="pd-notification" onClick={() => navigate('/notifications')} aria-label="الإشعارات">
            <Bell size={20} />
            {unread > 0 && <span>{Math.min(unread, 99)}</span>}
          </button>

          <button className="pd-profile" onClick={() => navigate('/profile')} aria-label="الملف الشخصي">
            <span className="pd-user-avatar">{(user?.name || 'و').charAt(0)}</span>
            <span className="pd-profile-copy"><strong>أهلاً {user?.name || 'ولي الأمر'}</strong><small>ولي أمر</small></span>
            <ChevronDown size={16} className="pd-profile-chevron" aria-hidden="true" />
          </button>
        </header>

        <main className="pd-content">
          <section className="pd-hero">
            <div className="pd-hero-copy">
              <span>لوحة ولي الأمر</span>
              <h1>مرحباً {user?.name || 'ولي الأمر'} <b>👋</b></h1>
              <h2>من الرائع رؤيتك مجدداً!</h2>
              <p>هنا نظرة سريعة على رحلة أبنائك التعليمية اليوم.</p>
            </div>
            <div className="pd-hero-art" aria-hidden="true">
              <img src="/edubridge-hero-child.webp" alt="" />
            </div>
            <span className="pd-deco pd-deco-a" aria-hidden="true">✦</span>
            <span className="pd-deco pd-deco-b" aria-hidden="true">✦</span>
            <span className="pd-deco pd-deco-c" aria-hidden="true">+</span>
          </section>

          <section className="pd-section pd-children-section">
            <div className="pd-section-head">
              <div><h2>أطفالي</h2></div>
              <div className="pd-head-actions">
                <button className="pd-link-btn" onClick={() => navigate('/children')}>عرض الكل <ArrowLeft size={15} /></button>
                <button className="pd-primary-mini" onClick={() => navigate('/children/new')}><Plus size={16} /> إضافة طفل</button>
              </div>
            </div>

            {loading ? (
              <div className="pd-state"><div className="spinner" /> جارِ تحميل البيانات...</div>
            ) : error ? (
              <div className="pd-state"><div className="error-box">{error}</div><button className="btn" onClick={load}>إعادة المحاولة</button></div>
            ) : visibleChildren.length === 0 ? (
              <div className="pd-empty">
                <Users size={34} />
                <h3>{normalizedQuery ? 'لا توجد نتائج مطابقة' : 'لا يوجد أطفال مرتبطون بحسابك بعد'}</h3>
                <p>{normalizedQuery ? 'جرّب كلمة بحث مختلفة.' : 'أضف طفلاً للبدء بمتابعة رحلته التعليمية.'}</p>
                {!normalizedQuery && <button onClick={() => navigate('/children/new')}><Plus size={17} /> إضافة طفل</button>}
              </div>
            ) : (
              <div className="pd-children-grid">
                {visibleChildren.slice(0, 2).map((child, index) => {
                  const status = STATUS[child.status] || STATUS.pending
                  const summary = summaries[child.id] || {}
                  const childTotal = Number(summary.done || 0) + Number(summary.in_progress || 0) + Number(summary.not_started || 0)
                  const childPct = childTotal ? clampPercent((Number(summary.done || 0) / childTotal) * 100) : 0

                  return (
                    <article className={`pd-child-card pd-child-card-${index % 2 ? 'pink' : 'blue'}`} key={child.id}>
                      <button
                        className="pd-child-arrow"
                        onClick={() => navigate(`/children/${child.id}`, { state: { childName: child.name } })}
                        aria-label={`عرض تفاصيل ${child.name}`}
                      >
                        <ArrowLeft size={18} />
                      </button>
                      <div className="pd-kid-avatar" style={{ '--kid-color': KID_COLORS[index % KID_COLORS.length] }}>
                        <span>{(child.name || 'ط').charAt(0)}</span>
                      </div>
                      <div className="pd-child-main">
                        <div className="pd-child-title">
                          <h3>{child.name}</h3>
                          <span className="pd-gender-symbol" aria-hidden="true">
                            {String(child.gender || '').toLowerCase() === 'female' ? '♀' : '♂'}
                          </span>
                          <span className={`status-chip ${status.cls}`}>{status.label}</span>
                        </div>
                        <p>{typeof child.age === 'number' ? `${child.age} سنوات` : 'العمر غير محدد'}</p>
                        <div className="pd-child-meta">
                          <span><small>المستوى الحالي</small><b>{child.disability_name || child.disability_type || 'برنامج تعليمي مخصص'}</b></span>
                          <span><small>المعلّم</small><b>{child.assigned_teacher_name || 'بانتظار التعيين'}</b></span>
                        </div>
                        <div className="pd-child-progress"><i style={{ width: `${childPct}%` }} /></div>
                        <button onClick={() => navigate(`/children/${child.id}`, { state: { childName: child.name } })}>عرض التفاصيل <ArrowLeft size={15} /></button>
                      </div>
                    </article>
                  )
                })}
              </div>
            )}
          </section>

          <ParentProgressSection dashboardStats={dashboardStats} children={children} />

          <div className="pd-fullwidth-lower">
          <div className="pd-lower-grid">
            <section className="pd-section pd-today">
              <div className="pd-section-head">
                <div>
                  <div className="pd-title-with-icon"><CalendarDays size={23} /><h2>دروس ومهام اليوم</h2></div>
                  <p>{children[0] ? `المحتوى التعليمي المتاح لـ ${children[0].name}` : 'أضف طفلاً لعرض الدروس والمهام'}</p>
                </div>
              </div>
              <div className="pd-schedule-list">
                {visibleLessons.slice(0, 3).length ? visibleLessons.slice(0, 3).map((lesson, index) => (
                  <article key={lesson.id} className="pd-schedule-row">
                    <div className="pd-schedule-time">
                      <span>{lessonTimeLabel(lesson, index)}</span>
                    </div>
                    <span className={`pd-schedule-icon pd-schedule-icon-${index % 3}`}>
                      {index === 1 ? '🎨' : index === 2 ? '🏠' : '📘'}
                    </span>
                    <div className="pd-schedule-copy">
                      <strong>{lesson.title}</strong>
                      <small>{children[0]?.name || 'الطفل'} · محتوى تعليمي</small>
                    </div>
                    <button onClick={() => children[0] && navigate(`/children/${children[0].id}/lessons`, { state: { childName: children[0].name } })}>
                      {index === 0 ? 'ابدأ الآن' : 'عرض الدرس'}
                    </button>
                  </article>
                )) : <div className="pd-mini-empty">لا توجد دروس أو مهام متاحة حالياً.</div>}
              </div>
            </section>

            <section className="pd-section pd-conversations">
              <div className="pd-section-head">
                <div><h2>المحادثات الأخيرة</h2><p>آخر تواصل مع الفريق التعليمي.</p></div>
                <button className="pd-link-btn" onClick={() => navigate('/conversations')}>عرض الكل <ArrowLeft size={15} /></button>
              </div>
              <div className="pd-list">
                {conversations.slice(0, 3).length ? conversations.slice(0, 3).map((conversation) => (
                  <article key={conversation.id} className="pd-chat-row">
                    <span className="pd-chat-avatar">{(conversation.other_user_name || 'م').charAt(0)}</span>
                    <div><strong>{conversation.other_user_name || 'فريق EduBridge'}</strong><small>{conversation.last_message || 'ابدأ المحادثة الآن'}</small></div>
                    <span className="pd-chat-dot" />
                  </article>
                )) : <div className="pd-mini-empty">لا توجد محادثات بعد.</div>}
              </div>
            </section>
          </div>

          <section className="pd-quick-actions">
            <h2>إجراءات سريعة</h2>
            <button className="primary" onClick={() => children[0] ? navigate(`/children/${children[0].id}/lessons`, { state: { childName: children[0].name } }) : navigate('/lessons')}><PlayCircle size={20} /> بدء درس</button>
            <button onClick={() => children[0] ? navigate(`/children/${children[0].id}/progress`, { state: { childName: children[0].name } }) : navigate('/children')}><BarChart3 size={19} /> عرض التقرير</button>
            <button onClick={() => navigate('/conversations')}><MessageCircle size={19} /> التواصل مع المعلم</button>
            <button onClick={openNoor}><Sparkles size={19} /> التحدث مع نور</button>
          </section>

          <section className="pd-noor-banner">
            <div className="pd-noor-copy">
              <span>مساعدك الذكي</span>
              <h2><b>نور</b> معك في كل خطوة</h2>
              <p>اسأل عن تقدم طفلك، أو احصل على نصائح تعليمية مخصصة لدعم تعلمه.</p>
              <button onClick={openNoor}>ابدأ المحادثة الآن <ArrowLeft size={16} /></button>
            </div>
            <NoorPet size={150} trackMouse />
            <div className="pd-noor-bubbles" aria-hidden="true">
              <span>ما هي أنشطة اليوم؟ 💡</span>
              <span>كيف يمكنني دعم طفلي في المنزل؟ 💬</span>
              <span>أريد تقريراً عن تقدم عمر 📊</span>
            </div>
          </section>
          </div>
        </main>
      </div>

      <nav className="pd-mobile-nav" aria-label="تنقل ولي الأمر">
        {navItems.slice(0, 5).map((item) => (
          <button
            key={item.label}
            className={item.active ? 'active' : ''}
            onClick={item.onClick}
            title={item.label}
            aria-label={item.label}
          >
            {item.icon}
            <span>{item.label}</span>
          </button>
        ))}
      </nav>

    </div>
  )
}
