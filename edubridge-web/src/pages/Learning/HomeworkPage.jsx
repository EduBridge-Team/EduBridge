import { homeworkGradePayload } from './homeworkGrading'
import FormDisclosure from '../../components/FormDisclosure'
import { useCallback, useEffect, useMemo, useState } from 'react'
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
    assigned_child_ids: [],
  })
  const [attachments, setAttachments] = useState([])
  const [submission, setSubmission] = useState(EMPTY_SUBMISSION)
  const [grades, setGrades] = useState({})

  const load = useCallback(async () => {
    try {
      const [childrenData, homeworkData] = await Promise.all([
        fetchChildren(),
        fetchHomeworks(),
      ])

      setChildren(childrenData.children || [])
      setItems(homeworkData.homeworks || [])
      setError('')
    } catch (err) {
      setError(err.message)
    }
  }, [])

  useEffect(() => {
    load()
  }, [load])

  const defaultDueDate = useMemo(() => {
    const date = new Date(Date.now() + 7 * 86_400_000)
    return date.toISOString().slice(0, 16)
  }, [])

  const create = async (event) => {
    event.preventDefault()
    setBusy(true)
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
        assigned_child_ids: [],
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
    setError('')

    try {
      await gradeHomeworkWeb(
        submission.id,
        payload.grade,
        payload.feedback,
      )
      await load()
    } catch (err) {
      setError(err.message)
    } finally {
      setBusy(false)
    }
  }

  const openSubmission = (homeworkId, childId) => {
    setSubmission((current) => ({
      ...current,
      homework_id: homeworkId,
      child_id: childId,
    }))
  }

  return (
    <div className="fp-page homework-page-v2">
      <section className="fp-hero homework-hero">
        <div>
          <span className="fp-eyebrow">التعلّم والمتابعة</span>
          <h1>الواجبات</h1>
          <p>{isStaff ? 'أنشئ الواجبات، تابع التسليم، وراجع التقييمات من مكان واحد.' : 'تابع واجبات أبنائك، سلّم الإجابات، وراجع تقييمات المعلّم.'}</p>
        </div>
        <button className="btn outline" onClick={load}>تحديث</button>
      </section>

      {error && <div className="fp-error">{error}</div>}

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

      <section className="fp-grid">
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
        />
      </section>

      <HomeworkSubmissionForm
        busy={busy}
        children={children}
        onCancel={() => setSubmission(EMPTY_SUBMISSION)}
        onChange={setSubmission}
        onSubmit={submit}
        submission={submission}
      />
    </div>
  )
}
