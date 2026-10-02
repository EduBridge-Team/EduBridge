import { useSearchParams } from 'react-router-dom'
import FormDisclosure from '../../components/FormDisclosure'
import { useCallback, useEffect, useState } from 'react'
import {
  createCaseDiscussionWeb,
  fetchCaseDiscussion,
  fetchCaseDiscussions,
  fetchChildren,
  fetchUsers,
  getUser,
  resolveCaseDiscussionWeb,
  sendCaseDiscussionMessage,
} from '../../api'
import {
  CaseDiscussionCreateForm,
  CaseDiscussionDetail,
  CaseDiscussionList,
} from './CaseDiscussionSections'

export default function CaseDiscussionsPage() {
  const [createOpen, setCreateOpen] = useState(false)
  const [params] = useSearchParams()
  const childId = params.get('child_id') || ''
  const me = getUser()
  const meId = me?.id
  const [items, setItems] = useState([])
  const [selected, setSelected] = useState(null)
  const [children, setChildren] = useState([])
  const [users, setUsers] = useState([])
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [draft, setDraft] = useState({
    child_id: childId,
    topic: '',
    description: '',
    participant_ids: [],
  })
  const [message, setMessage] = useState({ content: '', type: 'text' })

  const load = useCallback(async () => {
    try {
      const [discussionsData, childrenData, usersData] = await Promise.all([
        fetchCaseDiscussions(),
        fetchChildren(),
        fetchUsers(),
      ])
      const childList = (childrenData.children || []).filter(child => !childId || String(child.id) === childId)

      setItems((discussionsData.discussions || []).filter(item => !childId || String(item.child_id) === childId))
      setChildren(childList)
      setUsers(
        (usersData.users || []).filter(
          (user) => ['teacher', 'specialist'].includes(user.role) && user.id !== meId,
        ),
      )
      setError('')

      if (childList[0]) {
        setDraft((current) => (
          current.child_id
            ? current
            : { ...current, child_id: String(childList[0].id) }
        ))
      }
    } catch (err) {
      setError(err.message)
    }
  }, [meId, childId])

  useEffect(() => {
    setSelected(null)
    setDraft(current => ({ ...current, child_id: childId }))
    load()
  }, [load, childId])

  const open = async (id) => {
    try {
      const data = await fetchCaseDiscussion(id)
      setSelected(data.discussion)
    } catch (err) {
      setError(err.message)
    }
  }

  const create = async (event) => {
    event.preventDefault()
    setBusy(true)

    try {
      await createCaseDiscussionWeb({
        child_id: Number(draft.child_id),
        topic: draft.topic,
        description: draft.description,
        participant_ids: draft.participant_ids,
      })
      setDraft((current) => ({
        ...current,
        topic: '',
        description: '',
        participant_ids: [],
      }))
      setCreateOpen(false)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const send = async (event) => {
    event.preventDefault()
    if (!selected) return

    setBusy(true)
    try {
      await sendCaseDiscussionMessage(selected.id, message.content, message.type)
      setMessage({ content: '', type: 'text' })
      await open(selected.id)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const resolve = async () => {
    if (!selected) return

    setBusy(true)
    try {
      await resolveCaseDiscussionWeb(selected.id)
      await open(selected.id)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  return (
    <div className="fp-page case-discussions-page-v2">
      <section className="fp-hero case-discussions-hero">
        <div>
          <span className="fp-eyebrow">التعاون المهني</span>
          <h1>دراسات الحالة</h1>
          <p>ناقش حالة الطفل مع المعلمين والمختصين ووثّق القرارات والملاحظات.</p>
        </div>
        <button className="btn outline" onClick={load}>تحديث</button>
      </section>

      {error && <div className="fp-error">{error}</div>}

      <FormDisclosure label="إضافة دراسة حالة" open={createOpen} onToggle={setCreateOpen}>
        <CaseDiscussionCreateForm
          busy={busy}
          children={children}
          draft={draft}
          onChange={setDraft}
          onSubmit={create}
          users={users}
        />
      </FormDisclosure>

      <div className="fp-two">
        <CaseDiscussionList items={items} onOpen={open} onCreate={() => setCreateOpen(true)} />
        <CaseDiscussionDetail
          busy={busy}
          message={message}
          onMessageChange={setMessage}
          onResolve={resolve}
          onSend={send}
          selected={selected}
        />
      </div>
    </div>
  )
}
