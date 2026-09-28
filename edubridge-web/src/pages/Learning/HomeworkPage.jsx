import { useCallback, useEffect, useMemo, useState } from 'react'
import { createHomeworkWeb, fetchChildren, fetchHomeworks, getUser, gradeHomeworkWeb, submitHomeworkWeb } from '../../api'
import {
  HomeworkCreateForm,
  HomeworkGrid,
  HomeworkSubmissionForm,
} from './HomeworkSections'
import '../../feature-parity.css'

export default function HomeworkPage() {
  const me = getUser()
  const staff = ['teacher','specialist','admin'].includes(me?.role)
  const [children,setChildren]=useState([])
  const [items,setItems]=useState([])
  const [error,setError]=useState('')
  const [busy,setBusy]=useState(false)
  const [draft,setDraft]=useState({title:'',description:'',subject:'',due_date:'',assigned_child_ids:[]})
  const [attachments,setAttachments]=useState([])
  const [submission,setSubmission]=useState({homework_id:null,child_id:'',text_answer:'',files:[]})
  const [grades,setGrades]=useState({})

  const load=useCallback(async()=>{
    try{
      const [c,h]=await Promise.all([fetchChildren(),fetchHomeworks()])
      setChildren(c.children||[])
      setItems(h.homeworks||[])
      setError('')
    }catch(e){setError(e.message)}
  },[])
  useEffect(()=>{load()},[load])

  const dueDefault=useMemo(()=>{
    const d=new Date(Date.now()+7*86400000)
    return d.toISOString().slice(0,16)
  },[])

  const create=async(e)=>{
    e.preventDefault(); setBusy(true); setError('')
    try{
      await createHomeworkWeb({...draft,due_date:draft.due_date||dueDefault},attachments)
      setDraft({title:'',description:'',subject:'',due_date:'',assigned_child_ids:[]}); setAttachments([])
      await load()
    }catch(e){setError(e.message)} finally{setBusy(false)}
  }

  const submit=async(e)=>{
    e.preventDefault(); if(!submission.homework_id)return
    setBusy(true); setError('')
    try{
      await submitHomeworkWeb(submission.homework_id,{child_id:Number(submission.child_id),text_answer:submission.text_answer},submission.files)
      setSubmission({homework_id:null,child_id:'',text_answer:'',files:[]}); await load()
    }catch(e){setError(e.message)} finally{setBusy(false)}
  }

  const grade=async(id)=>{
    const g=grades[id]||{}
    setBusy(true); setError('')
    try{await gradeHomeworkWeb(id,Number(g.grade),g.feedback||''); await load()}
    catch(e){setError(e.message)} finally{setBusy(false)}
  }

  return (
    <div className="fp-page">
      <div className="fp-head">
        <div>
          <h2>📝 الواجبات</h2>
          <div className="meta">إنشاء الواجبات، التسليم، والتقييم</div>
        </div>
        <button className="btn outline" onClick={load}>تحديث</button>
      </div>

      {error && <div className="fp-error">{error}</div>}

      {staff && (
        <HomeworkCreateForm
          attachments={attachments}
          busy={busy}
          children={children}
          draft={draft}
          onAttachmentsChange={setAttachments}
          onDraftChange={setDraft}
          onSubmit={create}
        />
      )}

      <section className="fp-grid">
        <HomeworkGrid
          busy={busy}
          children={children}
          grades={grades}
          items={items}
          onGrade={grade}
          onGradesChange={setGrades}
          onOpenSubmission={(homeworkId, childId) =>
            setSubmission({
              ...submission,
              homework_id: homeworkId,
              child_id: childId,
            })
          }
          role={me?.role}
          staff={staff}
        />
      </section>

      <HomeworkSubmissionForm
        busy={busy}
        children={children}
        onCancel={() =>
          setSubmission({
            homework_id: null,
            child_id: '',
            text_answer: '',
            files: [],
          })
        }
        onChange={setSubmission}
        onSubmit={submit}
        submission={submission}
      />
    </div>
  )
}
