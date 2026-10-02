import { useSearchParams } from 'react-router-dom'
import FormDisclosure from '../../components/FormDisclosure'
import { useCallback, useEffect, useState } from 'react'
import {
  acceptSpecialistSuggestion,
  createSpecialistSuggestion,
  evaluateEducationalPlan,
  fetchChildren,
  fetchMyProfile,
  fetchSpecialistSuggestions,
  fetchUsers,
  getUser,
  rejectSpecialistSuggestion,
  setMySpecialty,
} from '../../api'
import {
  PlanEvaluationSection,
  SpecialistProfileCard,
  SpecialistSuggestionForm,
  SpecialistSuggestionList,
  SpecialistWorkflowHeader,
} from './SpecialistWorkflowSections'

export default function SpecialistWorkflowPage() {
  const [planOpen, setPlanOpen] = useState(false)
  const [createOpen, setCreateOpen] = useState(false)
  const [params] = useSearchParams()
  const selectedChild = params.get('child_id') || ''
  const me = getUser()
  const role = me?.role
  const isSpecialist = role === 'specialist'
  const canSuggest = ['specialist', 'admin'].includes(role)

  const [profile, setProfile] = useState(null)
  const [items, setItems] = useState([])
  const [children, setChildren] = useState([])
  const [specialists, setSpecialists] = useState([])
  const [filter, setFilter] = useState('pending')
  const [specialty, setSpecialty] = useState('learning_support')
  const [draft, setDraft] = useState({
    child_id: selectedChild,
    specialist_id: '',
    specialty: 'learning_support',
    reason: '',
  })
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [planDraft, setPlanDraft] = useState({
    child_id: selectedChild,
    is_plan_appropriate: true,
    notes_for_teacher: '',
    recommended_changes: '',
  })

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

      const childList = (childrenData.children || []).filter(child => !selectedChild || String(child.id) === selectedChild)

      setItems((suggestionsData.suggestions || []).filter(item => !selectedChild || String(item.child_id) === selectedChild))
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

      const evaluable = childList.find((child) => {
        if (!child.current_plan_id) return false
        if (role === 'admin') return true
        return (child.assigned_specialist_ids || []).map(Number).includes(Number(me?.id))
      })
      if (evaluable) {
        setPlanDraft((current) => (
          current.child_id
            ? current
            : { ...current, child_id: String(evaluable.id) }
        ))
      }

      setError('')
    } catch (err) {
      setError(err.message)
    }
  }, [filter, isSpecialist, role, selectedChild, me?.id])

  useEffect(() => {
    setDraft(current => ({ ...current, child_id: selectedChild }))
    setPlanDraft(current => ({ ...current, child_id: selectedChild }))
    load()
  }, [load, selectedChild])

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
      setCreateOpen(false)
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

  const evaluatePlan = async (event) => {
    event.preventDefault()
    const child = children.find((item) => String(item.id) === String(planDraft.child_id))
    if (!child?.current_plan_id) {
      setError('لا توجد خطة معتمدة لهذا الطفل')
      return
    }

    setBusy(true)
    try {
      await evaluateEducationalPlan(child.current_plan_id, {
        child_id: Number(child.id),
        is_plan_appropriate: Boolean(planDraft.is_plan_appropriate),
        notes_for_teacher: planDraft.notes_for_teacher.trim() || null,
        recommended_changes: planDraft.recommended_changes
          .split('\n')
          .map((item) => item.trim())
          .filter(Boolean),
      })
      setPlanDraft((current) => ({
        ...current,
        notes_for_teacher: '',
        recommended_changes: '',
      }))
      setPlanOpen(false)
      setError('')
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

  const evaluableChildren = children.filter((child) => child.current_plan_id && (role === 'admin' || (child.assigned_specialist_ids || []).map(Number).includes(Number(me?.id))))

  return (
    <div className="fp-page specialist-workflow-page-v2">
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

      {['specialist', 'admin'].includes(role) && evaluableChildren.length > 0 && (
        <FormDisclosure label="تقييم خطة تعليمية" open={planOpen} onToggle={setPlanOpen}>
          <PlanEvaluationSection
            busy={busy}
            children={evaluableChildren}
            draft={planDraft}
            onChange={setPlanDraft}
            onSubmit={evaluatePlan}
          />
        </FormDisclosure>
      )}

      {canSuggest && (
        <FormDisclosure label="اقتراح مختص لطفل" open={createOpen} onToggle={setCreateOpen}>
          <SpecialistSuggestionForm
            busy={busy}
            children={children}
            draft={draft}
            onChange={setDraft}
            onSubmit={suggest}
            specialists={specialists}
          />
        </FormDisclosure>
      )}

      <SpecialistSuggestionList
        busy={busy}
        isSpecialist={isSpecialist}
        items={items}
        onAccept={accept}
        onReject={reject}
        onCreate={canSuggest ? () => setCreateOpen(true) : undefined}
      />
    </div>
  )
}
