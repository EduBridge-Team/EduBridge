import { useMemo, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getUser } from '../../../api'
import ParentChildrenSection from './ParentChildrenSection'
import ParentDashboardHeader from './ParentDashboardHeader'
import ParentLowerSections from './ParentLowerSections'
import ParentProgressSection from './ParentProgressSection'
import { useDashboardSidebarSync, useParentDashboardPageClass, useSharedSidebarSync } from './hooks'
import useParentDashboardData from './useParentDashboardData'
import './ParentDashboard.css'

export default function ParentDashboard() {
  const navigate = useNavigate()
  const user = getUser()
  const [query, setQuery] = useState('')

  const {
    children,
    conversations,
    dashboardStats,
    error,
    lessons,
    load,
    loading,
    summaries,
  } = useParentDashboardData()

  useParentDashboardPageClass()
  useDashboardSidebarSync({ loading, childrenCount: children.length, summaries })
  useSharedSidebarSync({ loading, childrenCount: children.length, summaries })

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

  return (
    <div className="parent-dashboard-v2" dir="rtl">
      <ParentDashboardHeader
        query={query}
        setQuery={setQuery}
        todayLabel={todayLabel}
        user={user}
      />

        <main className="pd-content">
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
  )
}
