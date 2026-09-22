import { useEffect, useState } from 'react'
import { fetchChildWeeklyReports, fetchChildren, getUser, saveWeeklyReport } from '../api'
import '../feature-parity.css'

export default function WeeklyReportsPage(){
  const me=getUser(); const staff=['teacher','specialist','admin'].includes(me?.role)
  const [children,setChildren]=useState([]); const [childId,setChildId]=useState('')
  const [reports,setReports]=useState([]); const [error,setError]=useState(''); const [busy,setBusy]=useState(false)
  const monday=()=>{const d=new Date();const day=d.getDay()||7;d.setDate(d.getDate()-day+1);return d.toISOString().slice(0,10)}
  const [draft,setDraft]=useState({week_start:monday(),lessons_completed:0,progress_percentage:50,teacher_notes:'',achievements:'',concerns:''})

  useEffect(()=>{fetchChildren().then(d=>{const list=d.children||[];setChildren(list);if(list[0])setChildId(String(list[0].id))}).catch(e=>setError(e.message))},[])
  useEffect(()=>{if(childId)fetchChildWeeklyReports(childId).then(d=>setReports(d.reports||[])).catch(e=>setError(e.message))},[childId])

  const save=async(e)=>{e.preventDefault();setBusy(true);setError('');try{
    await saveWeeklyReport({child_id:Number(childId),week_start:draft.week_start,lessons_completed:Number(draft.lessons_completed),progress_percentage:Number(draft.progress_percentage),teacher_notes:draft.teacher_notes,achievements:draft.achievements.split('\n').map(x=>x.trim()).filter(Boolean),concerns:draft.concerns.split('\n').map(x=>x.trim()).filter(Boolean)})
    const d=await fetchChildWeeklyReports(childId);setReports(d.reports||[])
  }catch(e){setError(e.message)}finally{setBusy(false)}}

  return <div className="fp-page">
    <div className="fp-head"><div><h2>📊 التقارير الأسبوعية</h2><div className="meta">ملخص التقدم والدروس والواجبات والجلسات</div></div><select value={childId} onChange={e=>setChildId(e.target.value)}>{children.map(c=><option key={c.id} value={c.id}>{c.name}</option>)}</select></div>
    {error&&<div className="fp-error">{error}</div>}
    {staff&&childId&&<section className="fp-card"><h3>إضافة/تحديث تقرير</h3><form className="fp-form" onSubmit={save}>
      <div className="fp-row"><input type="date" value={draft.week_start} onChange={e=>setDraft({...draft,week_start:e.target.value})}/><input type="number" min="0" placeholder="الدروس المكتملة" value={draft.lessons_completed} onChange={e=>setDraft({...draft,lessons_completed:e.target.value})}/></div>
      <label>نسبة التقدم: {draft.progress_percentage}%</label><input type="range" min="0" max="100" value={draft.progress_percentage} onChange={e=>setDraft({...draft,progress_percentage:e.target.value})}/>
      <textarea rows={3} placeholder="ملاحظات المعلم" value={draft.teacher_notes} onChange={e=>setDraft({...draft,teacher_notes:e.target.value})}/>
      <textarea rows={3} placeholder="الإنجازات — كل إنجاز في سطر" value={draft.achievements} onChange={e=>setDraft({...draft,achievements:e.target.value})}/>
      <textarea rows={3} placeholder="نقاط للانتباه — كل نقطة في سطر" value={draft.concerns} onChange={e=>setDraft({...draft,concerns:e.target.value})}/>
      <button className="btn success" disabled={busy}>حفظ التقرير</button>
    </form></section>}
    <section className="fp-grid">{reports.length===0?<div className="fp-empty">لا توجد تقارير لهذا الطفل</div>:reports.map(r=><article className="fp-card" key={r.id}>
      <div className="fp-head"><h3>{new Date(r.week_start).toLocaleDateString('ar')} — {new Date(r.week_end).toLocaleDateString('ar')}</h3><span className="fp-badge">{Math.round(r.progress_percentage||0)}%</span></div>
      <div className="fp-grid"><div><div className="fp-stat">{r.lessons_completed}/{r.lessons_total}</div><small>الدروس</small></div><div><div className="fp-stat">{r.homework_submitted}/{r.homework_assigned}</div><small>الواجبات</small></div><div><div className="fp-stat">{r.learning_support_meetings_attended}/{r.learning_support_meetings_scheduled}</div><small>اجتماعات الدعم</small></div></div>
      {r.teacher_notes&&<p>{r.teacher_notes}</p>}
      {(r.achievements||[]).length>0&&<div><b>الإنجازات:</b> {(r.achievements||[]).join('، ')}</div>}
      {(r.concerns||[]).length>0&&<div><b>نقاط للانتباه:</b> {(r.concerns||[]).join('، ')}</div>}
    </article>)}</section>
  </div>
}
