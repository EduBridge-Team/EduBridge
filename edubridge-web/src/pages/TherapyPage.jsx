import { useEffect, useState } from 'react'
import { cancelTherapyRequestWeb, completeTherapySessionWeb, createTherapyRequestWeb, fetchChildren, fetchTherapyRequests, fetchTherapySessions, getUser, scheduleTherapyRequestWeb } from '../api'
import '../feature-parity.css'

export default function TherapyPage(){
  const me=getUser(); const parent=me?.role==='parent'; const specialist=['specialist','admin'].includes(me?.role)
  const [children,setChildren]=useState([]);const [requests,setRequests]=useState([]);const [sessions,setSessions]=useState([]);const [error,setError]=useState('');const [busy,setBusy]=useState(false)
  const [req,setReq]=useState({child_id:'',reason:'',description:'',urgency:'medium'})
  const [schedule,setSchedule]=useState({}); const [complete,setComplete]=useState({})

  const load=async()=>{try{const [c,r,s]=await Promise.all([fetchChildren(),fetchTherapyRequests(),fetchTherapySessions()]);const kids=c.children||[];setChildren(kids);setRequests(r.requests||[]);setSessions(s.sessions||[]);if(!req.child_id&&kids[0])setReq(x=>({...x,child_id:String(kids[0].id)}));setError('')}catch(e){setError(e.message)}}
  useEffect(()=>{load()},[])

  const create=async(e)=>{e.preventDefault();setBusy(true);try{await createTherapyRequestWeb({...req,child_id:Number(req.child_id)});setReq({...req,reason:'',description:''});await load()}catch(e){setError(e.message)}finally{setBusy(false)}}
  const scheduleOne=async(id)=>{const x=schedule[id]||{};setBusy(true);try{await scheduleTherapyRequestWeb(id,{scheduled_at:x.scheduled_at,meeting_link:x.meeting_link,specialist_notes:x.notes});await load()}catch(e){setError(e.message)}finally{setBusy(false)}}
  const finish=async(id)=>{const x=complete[id]||{};setBusy(true);try{await completeTherapySessionWeb(id,{notes:x.notes||'',recommendations:x.recommendations||'',mood_rating:x.mood?Number(x.mood):null,tags:[]});await load()}catch(e){setError(e.message)}finally{setBusy(false)}}

  return <div className="fp-page">
    <div className="fp-head"><div><h2>🧠 الدعم والجلسات النفسية</h2><div className="meta">طلبات الدعم، المواعيد، وسجل الجلسات</div></div><button className="btn outline" onClick={load}>تحديث</button></div>
    {error&&<div className="fp-error">{error}</div>}
    {parent&&<section className="fp-card"><h3>طلب جلسة دعم</h3><form className="fp-form" onSubmit={create}>
      <select value={req.child_id} onChange={e=>setReq({...req,child_id:e.target.value})}>{children.map(c=><option key={c.id} value={c.id}>{c.name}</option>)}</select>
      <input placeholder="السبب الرئيسي" value={req.reason} onChange={e=>setReq({...req,reason:e.target.value})} required/>
      <textarea rows={3} placeholder="تفاصيل إضافية" value={req.description} onChange={e=>setReq({...req,description:e.target.value})}/>
      <select value={req.urgency} onChange={e=>setReq({...req,urgency:e.target.value})}><option value="low">منخفض</option><option value="medium">متوسط</option><option value="high">مرتفع</option></select>
      <button className="btn success" disabled={busy}>إرسال الطلب</button>
    </form></section>}
    <section><h3>طلبات الدعم</h3><div className="fp-list">{requests.length===0?<div className="fp-empty">لا توجد طلبات</div>:requests.map(r=><article className="fp-card" key={r.id}>
      <div className="fp-head"><h3>{r.child_name||'طفل'}</h3><span className="fp-badge">{r.status}</span></div><p>{r.reason}</p>{r.description&&<p className="meta">{r.description}</p>}
      {specialist&&r.status!=='completed'&&r.status!=='cancelled'&&<div className="fp-form"><input type="datetime-local" value={schedule[r.id]?.scheduled_at||''} onChange={e=>setSchedule({...schedule,[r.id]:{...schedule[r.id],scheduled_at:e.target.value}})}/><input placeholder="رابط الاجتماع" value={schedule[r.id]?.meeting_link||r.meeting_link||''} onChange={e=>setSchedule({...schedule,[r.id]:{...schedule[r.id],meeting_link:e.target.value}})}/><input placeholder="ملاحظات" value={schedule[r.id]?.notes||''} onChange={e=>setSchedule({...schedule,[r.id]:{...schedule[r.id],notes:e.target.value}})}/><button className="btn" onClick={()=>scheduleOne(r.id)} disabled={busy}>تحديد الموعد</button></div>}
      {r.status==='pending'&&<button className="btn outline small" onClick={()=>cancelTherapyRequestWeb(r.id).then(load).catch(e=>setError(e.message))}>إلغاء الطلب</button>}
    </article>)}</div></section>
    <section><h3>الجلسات</h3><div className="fp-grid">{sessions.length===0?<div className="fp-empty">لا توجد جلسات</div>:sessions.map(s=><article className="fp-card" key={s.id}>
      <div className="fp-head"><h3>{s.child_name}</h3><span className="fp-badge">{s.status}</span></div>
      <div className="fp-meta"><span>{s.type}</span><span>{new Date(s.scheduled_at).toLocaleString('ar')}</span><span>{s.duration_minutes} دقيقة</span></div>
      {s.goals&&<p>{s.goals}</p>}
      {specialist&&s.status==='scheduled'&&<div className="fp-form"><textarea placeholder="ملاحظات الجلسة" value={complete[s.id]?.notes||''} onChange={e=>setComplete({...complete,[s.id]:{...complete[s.id],notes:e.target.value}})}/><textarea placeholder="التوصيات" value={complete[s.id]?.recommendations||''} onChange={e=>setComplete({...complete,[s.id]:{...complete[s.id],recommendations:e.target.value}})}/><input type="number" min="1" max="5" placeholder="الحالة النفسية 1-5" value={complete[s.id]?.mood||''} onChange={e=>setComplete({...complete,[s.id]:{...complete[s.id],mood:e.target.value}})}/><button className="btn success" onClick={()=>finish(s.id)}>إنهاء الجلسة</button></div>}
    </article>)}</div></section>
  </div>
}
