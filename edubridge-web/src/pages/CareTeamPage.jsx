import { useEffect, useState } from 'react'
import { addCareTeamMember, fetchCareTeam, fetchChildren, fetchUsers, getUser, removeCareTeamMember } from '../api'
import '../feature-parity.css'

export default function CareTeamPage(){
  const me=getUser()
  const canManage=['specialist','admin'].includes(me?.role)
  const [children,setChildren]=useState([])
  const [childId,setChildId]=useState('')
  const [team,setTeam]=useState({members:[]})
  const [users,setUsers]=useState([])
  const [draft,setDraft]=useState({user_id:'',role:'teacher',specialty:'learning_support',subject:''})
  const [error,setError]=useState('')
  const [busy,setBusy]=useState(false)

  const loadChildren=async()=>{
    try{
      const c=await fetchChildren(); const list=c.children||[]
      setChildren(list)
      if(!childId&&list[0]) setChildId(String(list[0].id))
      if(canManage){const u=await fetchUsers();setUsers((u.users||[]).filter(x=>['teacher','specialist'].includes(x.role)))}
    }catch(e){setError(e.message)}
  }
  useEffect(()=>{loadChildren()},[])
  useEffect(()=>{if(childId)fetchCareTeam(childId).then(d=>setTeam(d.care_team||{members:[]})).catch(e=>setError(e.message))},[childId])

  const add=async(e)=>{e.preventDefault();setBusy(true);setError('');try{
    await addCareTeamMember(childId,{user_id:Number(draft.user_id),role:draft.role,specialty:draft.role==='specialist'?draft.specialty:null,subject:draft.role==='teacher'?draft.subject:null})
    const d=await fetchCareTeam(childId);setTeam(d.care_team||{members:[]})
  }catch(e){setError(e.message)}finally{setBusy(false)}}
  const remove=async(userId)=>{setBusy(true);try{await removeCareTeamMember(childId,userId);const d=await fetchCareTeam(childId);setTeam(d.care_team||{members:[]})}catch(e){setError(e.message)}finally{setBusy(false)}}

  const available=users.filter(u=>u.role===draft.role)

  return <div className="fp-page">
    <div className="fp-head"><div><h2>👥 فريق الدعم التعليمي</h2><div className="meta">المعلمون والمختصون المرتبطون بالطفل</div></div><select value={childId} onChange={e=>setChildId(e.target.value)}>{children.map(c=><option key={c.id} value={c.id}>{c.name}</option>)}</select></div>
    {error&&<div className="fp-error">{error}</div>}
    {canManage&&childId&&<section className="fp-card"><h3>إضافة عضو</h3><form className="fp-form" onSubmit={add}>
      <div className="fp-row"><select value={draft.role} onChange={e=>setDraft({...draft,role:e.target.value,user_id:''})}><option value="teacher">معلم</option><option value="specialist">مختص</option></select><select value={draft.user_id} onChange={e=>setDraft({...draft,user_id:e.target.value})} required><option value="">اختر المستخدم</option>{available.map(u=><option key={u.id} value={u.id}>{u.name}</option>)}</select></div>
      {draft.role==='teacher'?<input placeholder="المادة/التخصص التعليمي" value={draft.subject} onChange={e=>setDraft({...draft,subject:e.target.value})}/>:<select value={draft.specialty} onChange={e=>setDraft({...draft,specialty:e.target.value})}><option value="learning_support">دعم تعليمي</option><option value="educational">تعليمي</option><option value="communication_support">تخاطب</option><option value="learning_behavior">دعم سلوك التعلم</option></select>}
      <button className="btn success" disabled={busy}>إضافة للفريق</button>
    </form></section>}
    <section className="fp-grid">{(team.members||[]).length===0?<div className="fp-empty">لم يتم تعيين فريق بعد</div>:(team.members||[]).map(m=><article className="fp-card" key={m.user_id}>
      <div className="fp-head"><h3>{m.name}</h3><span className="fp-badge">{m.role==='teacher'?'معلم':'مختص'}</span></div>
      <div className="fp-meta"><span>{m.subject||m.specialty||'عام'}</span><span>منذ {new Date(m.assigned_at).toLocaleDateString('ar')}</span></div>
      {canManage&&<div className="fp-actions"><button className="btn outline small" disabled={busy} onClick={()=>remove(m.user_id)}>إزالة</button></div>}
    </article>)}</section>
  </div>
}
