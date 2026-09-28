import { useCallback, useEffect, useState } from 'react'
import {
  acceptSpecialistSuggestion,
  createSpecialistSuggestion,
  fetchChildren,
  fetchMyProfile,
  fetchSpecialistSuggestions,
  fetchUsers,
  getUser,
  rejectSpecialistSuggestion,
  setMySpecialty,
} from '../../api'
import {
  SpecialistProfileCard,
  SpecialistSuggestionForm,
  SpecialistSuggestionList,
  SpecialistWorkflowHeader,
} from './SpecialistWorkflowSections'
import '../../feature-parity.css'

export default function SpecialistWorkflowPage() {
  const me = getUser()
  const role = me?.role
  const isSpecialist = role === 'specialist'
  const canSuggest = ['teacher', 'specialist', 'admin'].includes(role)

  const [profile, setProfile] = useState(null)
  const [items, setItems] = useState([])
  const [children, setChildren] = useState([])
  const [specialists, setSpecialists] = useState([])
  const [filter, setFilter] = useState('pending')
  const [specialty, setSpecialty] = useState('learning_support')
  const [draft, setDraft] = useState({
    child_id: '',
    specialist_id: '',
    specialty: 'learning_support',
    reason: '',
  })
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  const load = useCallback(async () => {
    try {
      const canListSuggestions = ['specialist', 'admin'].includes(role)
      const suggestionsRequest = canListSuggestions
        ? fetchSpecialistSuggestions(filter === 'all' ? undefined : filter)
        : Promise.resolve({ suggestions: [] })
      const profileRequest = isSpecialist
        ? fetchMyProfile()
        : Promise.resolve(null)

      const [suggestionsData, profileData, childrenData, usersData] = await Promise.all([
        suggestionsRequest,
        profileRequest,
        fetchChildren(),
        fetchUsers('specialist'),
      ])

      const childList = childrenData.children || []

      setItems(suggestionsData.suggestions || [])
      setProfile(profileData)
      setChildren(childList)
      setSpecialists(
        (usersData.users || []).filter((user) => user.role === 'specialist'),
      )

      if (profileData?.specialty) {
        setSpecialty(profileData.specialty)
      }

      if (childList[0]) {
        setDraft((current) => (
          current.child_id
            ? current
            : { ...current, child_id: String(childList[0].id) }
        ))
      }

      setError('')
    } catch (err) {
      setError(err.message)
    }
  }, [filter, isSpecialist, role])

  useEffect(() => {
    load()
  }, [load])

  const saveSpecialty = async () => {
    setBusy(true)

    try {
      await setMySpecialty(specialty)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const suggest = async (event) => {
    event.preventDefault()
    setBusy(true)

    try {
      await createSpecialistSuggestion(draft.child_id, {
        specialist_id: Number(draft.specialist_id),
        specialty: draft.specialty,
        reason: draft.reason,
      })
      setDraft((current) => ({
        ...current,
        specialist_id: '',
        reason: '',
      }))
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const accept = async (id) => {
    setBusy(true)

    try {
      await acceptSpecialistSuggestion(id)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const reject = async (id) => {
    const reason = window.prompt('سبب الرفض (اختياري)') || ''
    setBusy(true)

    try {
      await rejectSpecialistSuggestion(id, reason)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fp-page">
      <SpecialistWorkflowHeader
        filter={filter}
        onFilterChange={setFilter}
      />

      {error && <div className="fp-error">{error}</div>}

      {isSpecialist && (
        <SpecialistProfileCard
          busy={busy}
          profile={profile}
          specialty={specialty}
          onSave={saveSpecialty}
          onSpecialtyChange={setSpecialty}
        />
      )}

      {canSuggest && (
        <SpecialistSuggestionForm
          busy={busy}
          children={children}
          draft={draft}
          onChange={setDraft}
          onSubmit={suggest}
          specialists={specialists}
        />
      )}

      <SpecialistSuggestionList
        busy={busy}
        isSpecialist={isSpecialist}
        items={items}
        onAccept={accept}
        onReject={reject}
      />
    </div>
  )
}
