import { useEffect, useState } from 'react'
import { acceptSpecialistSuggestion, createSpecialistSuggestion, fetchChildren, fetchMyProfile, fetchSpecialistSuggestions, fetchUsers, getUser, rejectSpecialistSuggestion, setMySpecialty } from '../api'
import '../feature-parity.css'

export default function SpecialistWorkflowPage(){
  const me=getUser(); const isSpecialist=me?.role==='specialist'
  const [profile,setProfile]=useState(null);const [items,setItems]=useState([]);const [children,setChildren]=useState([]);const [specialists,setSpecialists]=useState([])
  const [filter,setFilter]=useState('pending');const [specialty,setSpecialty]=useState('psychological');const [draft,setDraft]=useState({child_id:'',specialist_id:'',specialty:'psychological',reason:''});const [error,setError]=useState('');const [busy,setBusy]=useState(false)

  const load=async()=>{try{
    const jobs=[fetchSpecialistSuggestions(filter==='all'?undefined:filter)]
    if(isSpecialist)jobs.push(fetchMyProfile())
    else jobs.push(Promise.resolve(null))
    jobs.push(fetchChildren());jobs.push(fetchUsers('specialist'))
    const [s,p,c,u]=await Promise.all(jobs)
    setItems(s.suggestions||[]);setProfile(p);setChildren(c.children||[]);setSpecialists((u.users||[]).filter(x=>x.role==='specialist'))
    if(p?.specialty)setSpecialty(p.specialty)
    if(!draft.child_id&&(c.children||[])[0])setDraft(x=>({...x,child_id:String(c.children[0].id)}))
    setError('')
  }catch(e){setError(e.message)}}
  useEffect(()=>{load()},[filter])

  const saveSpecialty=async()=>{setBusy(true);try{await setMySpecialty(specialty);await load()}catch(e){setError(e.message)}finally{setBusy(false)}}
  const suggest=async(e)=>{e.preventDefault();setBusy(true);try{await createSpecialistSuggestion(draft.child_id,{specialist_id:Number(draft.specialist_id),specialty:draft.specialty,reason:draft.reason});setDraft({...draft,specialist_id:'',reason:''});await load()}catch(e){setError(e.message)}finally{setBusy(false)}}
  const accept=async(id)=>{setBusy(true);try{await acceptSpecialistSuggestion(id);await load()}catch(e){setError(e.message)}finally{setBusy(false)}}
  const reject=async(id)=>{const reason=window.prompt('سبب الرفض (اختياري)')||'';setBusy(true);try{await rejectSpecialistSuggestion(id,reason);await load()}catch(e){setError(e.message)}finally{setBusy(false)}}

  return <div className="fp-page">
    <div className="fp-head"><div><h2>🤝 متابعة المختصين</h2><div className="meta">التخصص واقتراحات متابعة الأطفال</div></div><select value={filter} onChange={e=>setFilter(e.target.value)}><option value="pending">معلقة</option><option value="accepted">مقبولة</option><option value="rejected">مرفوضة</option><option value="all">الكل</option></select></div>
    {error&&<div className="fp-error">{error}</div>}
    {isSpecialist&&<section className="fp-card"><h3>تخصصي</h3><div className="fp-row"><select value={specialty} onChange={e=>setSpecialty(e.target.value)} disabled={Boolean(profile?.specialty)}><option value="psychological">مختص نفسي</option><option value="educational">مختص تعليمي</option></select><button className="btn" onClick={saveSpecialty} disabled={busy||Boolean(profile?.specialty)}>{profile?.specialty?'تم الحفظ':'حفظ التخصص'}</button></div></section>}
    {['teacher','specialist','admin'].includes(me?.role)&&<section className="fp-card"><h3>اقتراح مختص لطفل</h3><form className="fp-form" onSubmit={suggest}>
      <select value={draft.child_id} onChange={e=>setDraft({...draft,child_id:e.target.value})}>{children.map(c=><option key={c.id} value={c.id}>{c.name}</option>)}</select>
      <select value={draft.specialty} onChange={e=>setDraft({...draft,specialty:e.target.value,specialist_id:''})}><option value="psychological">نفسي</option><option value="educational">تعليمي</option></select>
      <select value={draft.specialist_id} onChange={e=>setDraft({...draft,specialist_id:e.target.value})} required><option value="">اختر المختص</option>{specialists.filter(s=>!s.specialty||s.specialty===draft.specialty).map(s=><option key={s.id} value={s.id}>{s.name}</option>)}</select>
      <textarea rows={3} placeholder="سبب الاقتراح" value={draft.reason} onChange={e=>setDraft({...draft,reason:e.target.value})} required/>
      <button className="btn success" disabled={busy}>إرسال الاقتراح</button>
    </form></section>}
    <section className="fp-grid">{items.length===0?<div className="fp-empty">لا توجد اقتراحات</div>:items.map(s=><article className="fp-card" key={s.id}><div className="fp-head"><h3>{s.child_name}</h3><span className="fp-badge">{s.status}</span></div><div className="fp-meta"><span>{s.specialist_name}</span><span>{s.specialty==='psychological'?'نفسي':'تعليمي'}</span></div><p>{s.reason}</p>{isSpecialist&&s.status==='pending'&&<div className="fp-actions"><button className="btn success" onClick={()=>accept(s.id)} disabled={busy}>قبول</button><button className="btn outline" onClick={()=>reject(s.id)} disabled={busy}>رفض</button></div>}</article>)}</section>
  </div>
}
