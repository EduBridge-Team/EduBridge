import { useCallback, useEffect, useMemo, useState } from 'react'
import { createHomeworkWeb, fetchChildren, fetchHomeworks, getUser, gradeHomeworkWeb, submitHomeworkWeb } from '../api'
import '../feature-parity.css'

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

  return <div className="fp-page">
    <div className="fp-head"><div><h2>📝 الواجبات</h2><div className="meta">إنشاء الواجبات، التسليم، والتقييم</div></div><button className="btn outline" onClick={load}>تحديث</button></div>
    {error&&<div className="fp-error">{error}</div>}

    {staff&&<section className="fp-card">
      <h3>واجب جديد</h3>
      <form className="fp-form" onSubmit={create}>
        <input placeholder="عنوان الواجب" value={draft.title} onChange={e=>setDraft({...draft,title:e.target.value})} required/>
        <textarea rows={3} placeholder="الوصف" value={draft.description} onChange={e=>setDraft({...draft,description:e.target.value})} required/>
        <div className="fp-row">
          <input placeholder="المادة" value={draft.subject} onChange={e=>setDraft({...draft,subject:e.target.value})}/>
          <input type="datetime-local" value={draft.due_date} onChange={e=>setDraft({...draft,due_date:e.target.value})}/>
        </div>
        <div className="fp-checks">{children.map(ch=><label className="fp-check" key={ch.id}><input type="checkbox" checked={draft.assigned_child_ids.includes(ch.id)} onChange={e=>setDraft({...draft,assigned_child_ids:e.target.checked?[...draft.assigned_child_ids,ch.id]:draft.assigned_child_ids.filter(id=>id!==ch.id)})}/>{ch.name}</label>)}</div>
        <input type="file" multiple onChange={e=>setAttachments(Array.from(e.target.files||[]))}/>
        <button className="btn success" disabled={busy||draft.assigned_child_ids.length===0}>حفظ الواجب</button>
      </form>
    </section>}

    <section className="fp-grid">
      {items.length===0?<div className="fp-empty">لا توجد واجبات بعد</div>:items.map(hw=><article className="fp-card" key={hw.id}>
        <h3>{hw.title}</h3>
        <p>{hw.description}</p>
        <div className="fp-meta"><span>{hw.subject||'عام'}</span><span>التسليم: {new Date(hw.due_date).toLocaleString('ar')}</span><span>{(hw.submissions||[]).length}/{(hw.assigned_child_ids||[]).length} تسليم</span></div>
        {(hw.attachment_urls||[]).length>0&&<div className="fp-actions">{hw.attachment_urls.map((u,i)=><a className="btn outline small" key={u} href={u} target="_blank" rel="noreferrer">مرفق {i+1}</a>)}</div>}

        {me?.role==='parent'&&<div className="fp-actions"><button className="btn" onClick={()=>setSubmission({...submission,homework_id:hw.id,child_id:children[0]?.id||''})}>تسليم الواجب</button></div>}

        {staff&&(hw.submissions||[]).length>0&&<div className="fp-list" style={{marginTop:12}}>{hw.submissions.map(s=><div className="fp-message" key={s.id}>
          <small>{s.child_name} — {new Date(s.submitted_at).toLocaleString('ar')} {s.is_late?'• متأخر':''}</small>
          <div>{s.text_answer||'تسليم ملف'}</div>
          {s.file_url&&<a href={s.file_url} target="_blank" rel="noreferrer">فتح الملف</a>}
          <div className="fp-row" style={{marginTop:8}}>
            <input type="number" min="0" max="100" placeholder="الدرجة" value={grades[s.id]?.grade??s.grade??''} onChange={e=>setGrades({...grades,[s.id]:{...grades[s.id],grade:e.target.value}})}/>
            <input placeholder="ملاحظات" value={grades[s.id]?.feedback??s.feedback??''} onChange={e=>setGrades({...grades,[s.id]:{...grades[s.id],feedback:e.target.value}})}/>
            <button className="btn small" onClick={()=>grade(s.id)} disabled={busy}>حفظ التقييم</button>
          </div>
        </div>)}</div>}
      </article>)}
    </section>

    {submission.homework_id&&<section className="fp-card">
      <h3>تسليم الواجب</h3>
      <form className="fp-form" onSubmit={submit}>
        <select value={submission.child_id} onChange={e=>setSubmission({...submission,child_id:e.target.value})} required>{children.map(ch=><option key={ch.id} value={ch.id}>{ch.name}</option>)}</select>
        <textarea rows={3} placeholder="إجابة نصية" value={submission.text_answer} onChange={e=>setSubmission({...submission,text_answer:e.target.value})}/>
        <input type="file" multiple onChange={e=>setSubmission({...submission,files:Array.from(e.target.files||[])})}/>
        <div className="fp-actions"><button className="btn success" disabled={busy}>إرسال</button><button type="button" className="btn outline" onClick={()=>setSubmission({homework_id:null,child_id:'',text_answer:'',files:[]})}>إلغاء</button></div>
      </form>
    </section>}
  </div>
}
