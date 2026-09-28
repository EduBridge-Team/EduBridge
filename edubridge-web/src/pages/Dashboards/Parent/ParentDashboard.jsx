import { useCallback, useEffect, useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import {
  BarChart3, Bell, BookOpen, CalendarDays, CheckCircle2, ChevronDown, Home,
  MessageCircle, Search, Settings, Users,
} from 'lucide-react'
import {
  fetchChildLessons,
  fetchChildSummary,
  fetchChildren,
  fetchConversations,
  fetchUnreadNotificationsCount,
  getUser,
} from '../../../api'
import ParentChildrenSection from './ParentChildrenSection'
import ParentLowerSections from './ParentLowerSections'
import ParentNavigation from './ParentNavigation'
import ParentProgressSection from './ParentProgressSection'
import { useDashboardSidebarSync, useParentDashboardPageClass, useSharedSidebarSync } from './hooks'
import { clampPercent } from './utils'
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
  const todayLabel = useMemo(() => new Intl.DateTimeFormat('ar', {
    weekday: 'long', day: 'numeric', month: 'long',
  }).format(new Date()), [])

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
    {
      label: 'التقدم',
      icon: <BarChart3 size={21} />,
      onClick: () => children[0] && navigate(`/children/${children[0].id}/progress`, { state: { childName: children[0].name } }),
      disabled: !children[0],
    },
    {
      label: 'المحادثات',
      icon: <MessageCircle size={21} />,
      onClick: () => navigate('/conversations'),
      badge: conversations.length,
    },
    { label: 'الإعدادات', icon: <Settings size={21} />, onClick: () => navigate('/accessibility') },
  ]

  return (
    <div className="parent-dashboard-v2" dir="rtl">
      <ParentNavigation navItems={navItems} onHome={() => navigate('/parent')} />

      <div className="pd-main">
        <header className="pd-toolbar">
          <label className="pd-search">
            <Search size={20} />
            <input
              aria-label="البحث في لوحة ولي الأمر"
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
            <span className="pd-profile-copy">
              <strong>أهلاً {user?.name || 'ولي الأمر'}</strong>
              <small>ولي أمر</small>
            </span>
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
              <div className="pd-hero-status" aria-label="ملخص اليوم">
                <span><CalendarDays size={15} /> {todayLabel}</span>
                <span><CheckCircle2 size={15} /> تم تحديث بيانات التقدم</span>
              </div>
            </div>
            <div className="pd-hero-art" aria-hidden="true">
              <img src="/edubridge-hero-child.webp" alt="" />
            </div>
            <span className="pd-deco pd-deco-a" aria-hidden="true">✦</span>
            <span className="pd-deco pd-deco-b" aria-hidden="true">✦</span>
            <span className="pd-deco pd-deco-c" aria-hidden="true">+</span>
          </section>

          <ParentChildrenSection
            childrenCount={children.length}
            error={error}
            load={load}
            loading={loading}
            navigate={navigate}
            normalizedQuery={normalizedQuery}
            summaries={summaries}
            visibleChildren={visibleChildren}
          />

          <ParentProgressSection dashboardStats={dashboardStats} childCount={children.length} />

          <ParentLowerSections
            children={children}
            conversations={conversations}
            navigate={navigate}
            openNoor={openNoor}
            visibleLessons={visibleLessons}
          />
        </main>
      </div>
    </div>
  )
}
