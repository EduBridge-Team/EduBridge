import { useCallback, useEffect, useMemo, useState } from 'react'
import {
  addCareTeamMember,
  fetchCareTeam,
  fetchChildren,
  fetchUsers,
  getUser,
  removeCareTeamMember,
} from '../../api'
import {
  CareTeamHeader,
  CareTeamMemberForm,
  CareTeamMembers,
} from './CareTeamSections'
import '../../feature-parity.css'

const EMPTY_TEAM = { members: [] }

export default function CareTeamPage() {
  const me = getUser()
  const canManage = ['specialist', 'admin'].includes(me?.role)

  const [children, setChildren] = useState([])
  const [childId, setChildId] = useState('')
  const [team, setTeam] = useState(EMPTY_TEAM)
  const [users, setUsers] = useState([])
  const [draft, setDraft] = useState({
    user_id: '',
    role: 'teacher',
    specialty: 'learning_support',
    subject: '',
  })
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)

  const loadTeam = useCallback(async (selectedChildId) => {
    if (!selectedChildId) {
      setTeam(EMPTY_TEAM)
      return
    }

    const data = await fetchCareTeam(selectedChildId)
    setTeam(data.care_team || EMPTY_TEAM)
  }, [])

  const loadChildren = useCallback(async () => {
    try {
      const childrenData = await fetchChildren()
      const childList = childrenData.children || []

      setChildren(childList)
      setChildId((current) => current || (childList[0] ? String(childList[0].id) : ''))

      if (canManage) {
        const usersData = await fetchUsers()
        setUsers(
          (usersData.users || []).filter((user) => (
            ['teacher', 'specialist'].includes(user.role)
          )),
        )
      }
      setError('')
    } catch (err) {
      setError(err.message)
    }
  }, [canManage])

  useEffect(() => {
    loadChildren()
  }, [loadChildren])

  useEffect(() => {
    loadTeam(childId).catch((err) => setError(err.message))
  }, [childId, loadTeam])

  const add = async (event) => {
    event.preventDefault()
    setBusy(true)
    setError('')

    try {
      await addCareTeamMember(childId, {
        user_id: Number(draft.user_id),
        role: draft.role,
        specialty: draft.role === 'specialist' ? draft.specialty : null,
        subject: draft.role === 'teacher' ? draft.subject : null,
      })
      await loadTeam(childId)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const remove = async (userId) => {
    setBusy(true)

    try {
      await removeCareTeamMember(childId, userId)
      await loadTeam(childId)
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const availableUsers = useMemo(
    () => users.filter((user) => user.role === draft.role),
    [draft.role, users],
  )

  return (
    <div className="fp-page">
      <CareTeamHeader
        childId={childId}
        children={children}
        onChildChange={setChildId}
      />

      {error && <div className="fp-error">{error}</div>}

      {canManage && childId && (
        <CareTeamMemberForm
          availableUsers={availableUsers}
          busy={busy}
          draft={draft}
          onChange={setDraft}
          onSubmit={add}
        />
      )}

      <CareTeamMembers
        busy={busy}
        canManage={canManage}
        members={team.members || []}
        onRemove={remove}
      />
    </div>
  )
}
