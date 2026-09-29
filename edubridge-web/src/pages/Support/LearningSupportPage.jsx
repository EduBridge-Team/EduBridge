import { useCallback, useEffect, useState } from 'react'
import {
  cancelLearningSupportRequestWeb,
  completeLearningSupportMeetingWeb,
  createLearningSupportRequestWeb,
  fetchChildren,
  fetchLearningSupportMeetings,
  fetchLearningSupportRequests,
  getUser,
  scheduleLearningSupportRequestWeb,
} from '../../api'
import {
  LearningSupportRequestForm,
  LearningSupportRequests,
  LearningSupportSessions,
} from './LearningSupportSections'
import '../../feature-parity.css'

export default function LearningSupportPage() {
  const me = getUser()
  const isParent = me?.role === 'parent'
  const isSpecialist = ['specialist', 'admin'].includes(me?.role)

  const [children, setChildren] = useState([])
  const [requests, setRequests] = useState([])
  const [sessions, setSessions] = useState([])
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [request, setRequest] = useState({
    child_id: '',
    reason: '',
    description: '',
    urgency: 'medium',
  })
  const [schedule, setSchedule] = useState({})
  const [complete, setComplete] = useState({})

  const load = useCallback(async () => {
    try {
      const [childrenData, requestsData, meetingsData] = await Promise.all([
        fetchChildren(),
        fetchLearningSupportRequests(),
        fetchLearningSupportMeetings(),
      ])
      const childList = childrenData.children || []

      setChildren(childList)
      setRequests(requestsData.requests || [])
      setSessions(meetingsData.sessions || [])
      setRequest((current) => (
        current.child_id || !childList[0]
          ? current
          : { ...current, child_id: String(childList[0].id) }
      ))
      setError('')
    } catch (err) {
      setError(err.message)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  const create = async (event) => {
    event.preventDefault()
    setBusy(true)

    try {
      await createLearningSupportRequestWeb({
        ...request,
        child_id: Number(request.child_id),
      })
      setRequest((current) => ({
        ...current,
        reason: '',
        description: '',
      }))
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const scheduleOne = async (id) => {
    const draft = schedule[id] || {}
    setBusy(true)

    try {
      await scheduleLearningSupportRequestWeb(id, {
        scheduled_at: draft.scheduled_at,
        meeting_link: draft.meeting_link,
        specialist_notes: draft.notes,
      })
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const finish = async (id) => {
    const draft = complete[id] || {}
    setBusy(true)

    try {
      await completeLearningSupportMeetingWeb(id, {
        notes: draft.notes || '',
        recommendations: draft.recommendations || '',
        mood_rating: draft.mood ? Number(draft.mood) : null,
        tags: [],
      })
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const cancelOne = async (id) => {
    try {
      await cancelLearningSupportRequestWeb(id)
      await load()
    } catch (err) {
      setError(err.message)
    }
  }

  return (
    <div className="fp-page learning-support-page-v2">
      <section className="fp-hero learning-support-hero">
        <div>
          <span className="fp-eyebrow">الدعم التعليمي</span>
          <h1>الدعم والاجتماعات التعليمية</h1>
          <p>تابع طلبات الدعم والمواعيد وسجل الجلسات من مساحة واحدة.</p>
        </div>
        <button className="btn outline" onClick={load}>تحديث</button>
      </section>

      {error && <div className="fp-error">{error}</div>}

      {isParent && (
        <LearningSupportRequestForm
          busy={busy}
          children={children}
          onChange={setRequest}
          onSubmit={create}
          request={request}
        />
      )}

      <LearningSupportRequests
        busy={busy}
        onCancel={cancelOne}
        onSchedule={scheduleOne}
        onScheduleChange={setSchedule}
        requests={requests}
        schedule={schedule}
        specialist={isSpecialist}
      />

      <LearningSupportSessions
        complete={complete}
        onComplete={finish}
        onCompleteChange={setComplete}
        sessions={sessions}
        specialist={isSpecialist}
      />
    </div>
  )
}
