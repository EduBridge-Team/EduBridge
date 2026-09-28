import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  fetchChildLessons,
  fetchChildSummary,
  fetchChildren,
  fetchConversations,
  fetchUnreadNotificationsCount,
} from '../../../api'
import { clampPercent } from './utils'

export default function useParentDashboardData() {
  const [children, setChildren] = useState([])
  const [unread, setUnread] = useState(0)
  const [summaries, setSummaries] = useState({})
  const [conversations, setConversations] = useState([])
  const [lessons, setLessons] = useState([])
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)

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

  return {
    children,
    conversations,
    dashboardStats,
    error,
    lessons,
    load,
    loading,
    summaries,
    unread,
  }
}
