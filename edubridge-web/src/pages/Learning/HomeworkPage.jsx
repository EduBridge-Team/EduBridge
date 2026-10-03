import { useSearchParams } from 'react-router-dom'
import { homeworkGradePayload } from './homeworkGrading'
import FormDisclosure from '../../components/FormDisclosure'
import { useCallback, useEffect, useMemo, useRef, useState } from 'react'
import { unsubmittedHomeworkChildren } from './homeworkChildren'
import {
  createHomeworkWeb,
  fetchChildren,
  fetchHomeworks,
  getUser,
  gradeHomeworkWeb,
  submitHomeworkWeb,
} from '../../api'
import {
  HomeworkCreateForm,
  HomeworkGrid,
  HomeworkSubmissionForm,
} from './HomeworkSections'

const EMPTY_SUBMISSION = {
  homework_id: null,
  child_id: '',
  text_answer: '',
  files: [],
}

export default function HomeworkPage() {
  const [createOpen, setCreateOpen] = useState(false)
  const [params] = useSearchParams()
  const childId = params.get('child_id') || ''
  const [success, setSuccess] = useState('')
  const me = getUser()
  const isStaff = ['teacher', 'specialist', 'admin'].includes(me?.role)

  const [children, setChildren] = useState([])
  const [items, setItems] = useState([])
  const [error, setError] = useState('')
  const [busy, setBusy] = useState(false)
  const [draft, setDraft] = useState({
    title: '',
    description: '',
    subject: '',
    due_date: '',
    assigned_child_ids: childId ? [Number(childId)] : [],
  })
  const [attachments, setAttachments] = useState([])
  const [submission, setSubmission] = useState(EMPTY_SUBMISSION)
  const [grades, setGrades] = useState({})
  const [loading, setLoading] = useState(true)
  const [loadedChildId, setLoadedChildId] = useState(null)
  const requestId = useRef(0)

  const load = useCallback(async () => {
    const currentRequest = ++requestId.current
    setLoading(true)
    try {
      const [childrenData, homeworkData] = await Promise.all([
        fetchChildren(),
        fetchHomeworks(childId),
      ])

      if (currentRequest !== requestId.current) return
      setChildren((childrenData.children || []).filter(child => !childId || String(child.id) === childId))
      setItems(homeworkData.homeworks || [])
      setError('')
    } catch (err) {
      if (currentRequest !== requestId.current) return
      setError(err.message)
    } finally {
      if (currentRequest === requestId.current) {
        setLoadedChildId(childId)
        setLoading(false)
      }
    }
  }, [childId])

  useEffect(() => {
    load()
    setSubmission(EMPTY_SUBMISSION)
    return () => { requestId.current += 1 }
  }, [load])

  const defaultDueDate = useMemo(() => {
    const date = new Date(Date.now() + 7 * 86_400_000)
    return date.toISOString().slice(0, 16)
  }, [])

  const create = async (event) => {
    event.preventDefault()
    setBusy(true)
    setSuccess('')
    setError('')

    try {
      await createHomeworkWeb(
        {
          ...draft,
          due_date: draft.due_date || defaultDueDate,
        },
        attachments,
      )
      setDraft({
        title: '',
        description: '',
        subject: '',
        due_date: '',
        assigned_child_ids: childId ? [Number(childId)] : [],
      })
      setAttachments([])
      setCreateOpen(false)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const submit = async (event) => {
    event.preventDefault()
    if (!submission.homework_id) return

    setBusy(true)
    setSuccess('')
    setError('')

    try {
      await submitHomeworkWeb(
        submission.homework_id,
        {
          child_id: Number(submission.child_id),
          text_answer: submission.text_answer,
        },
        submission.files,
      )
      setSubmission(EMPTY_SUBMISSION)
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const grade = async (submission) => {
    const payload = homeworkGradePayload(submission, grades[submission.id])
    if (!payload) {
      setError('أدخل علامة صحيحة بين 0 و100')
      return
    }
    setBusy(true)
    setSuccess('')
    setError('')

    try {
      await gradeHomeworkWeb(
        submission.id,
        payload.grade,
        payload.feedback,
      )
      setSuccess('تم تقييم الواجب بنجاح')
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const openSubmission = (homeworkId, childId) => {
    setSubmission({
      ...EMPTY_SUBMISSION,
      homework_id: homeworkId,
      child_id: childId,
    })
  }

  const submissionHomework = items.find(item => item.id === submission.homework_id)
  const submissionChildren = unsubmittedHomeworkChildren(submissionHomework, children)
  const listLoading = loading || loadedChildId !== childId

  return (
    <div className="fp-page homework-page-v2">
      <section className="fp-hero homework-hero">
        <div>
          <span className="fp-eyebrow">التعلّم والمتابعة</span>
          <h1>الواجبات</h1>
          <p>{isStaff ? 'أنشئ الواجبات، تابع التسليم، وراجع التقييمات من مكان واحد.' : 'تابع واجبات أبنائك، سلّم الإجابات، وراجع تقييمات المعلّم.'}</p>
        </div>
        <button className="btn outline" onClick={load} disabled={listLoading}>تحديث</button>
      </section>

      {error && <div className="fp-error">{error}</div>}
      {success && <div className="success-box" role="status">{success}</div>}

      {isStaff && (
        <FormDisclosure label="إضافة واجب جديد" open={createOpen} onToggle={setCreateOpen}>
          <HomeworkCreateForm
            attachments={attachments}
            busy={busy}
            children={children}
            draft={draft}
            onAttachmentsChange={setAttachments}
            onDraftChange={setDraft}
            onSubmit={create}
          />
        </FormDisclosure>
      )}

      <section className="fp-grid" aria-busy={listLoading}>
        {listLoading ? <div className="state" role="status">جارِ تحميل الواجبات...</div> : !error &&
        <HomeworkGrid
          busy={busy}
          children={children}
          grades={grades}
          items={items}
          onGrade={grade}
          onGradesChange={setGrades}
          onOpenSubmission={openSubmission}
          role={me?.role}
          staff={isStaff}
          onCreate={() => setCreateOpen(true)}
        />}
      </section>

      <HomeworkSubmissionForm
        busy={busy}
        children={submissionChildren}
        onCancel={() => setSubmission(EMPTY_SUBMISSION)}
        onChange={setSubmission}
        onSubmit={submit}
        submission={submission}
      />
    </div>
  )
}
