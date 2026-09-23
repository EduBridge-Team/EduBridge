import { useCallback, useEffect, useState } from 'react'
import { createCaseDiscussionWeb, fetchCaseDiscussion, fetchCaseDiscussions, fetchChildren, fetchUsers, getUser, resolveCaseDiscussionWeb, sendCaseDiscussionMessage } from '../api'
import '../feature-parity.css'

export default function CaseDiscussionsPage(){
  const me=getUser()
  const meId=me?.id
  const [items,setItems]=useState([])
  const [selected,setSelected]=useState(null)
  const [children,setChildren]=useState([])
  const [users,setUsers]=useState([])
  const [error,setError]=useState('')
  const [busy,setBusy]=useState(false)
  const [draft,setDraft]=useState({child_id:'',topic:'',description:'',participant_ids:[]})
  const [message,setMessage]=useState({content:'',type:'text'})

  const load=useCallback(async()=>{try{
    const [d,c,u]=await Promise.all([fetchCaseDiscussions(),fetchChildren(),fetchUsers()])
    setItems(d.discussions||[]);setChildren(c.children||[]);setUsers((u.users||[]).filter(x=>['teacher','specialist'].includes(x.role)&&x.id!==meId));setError('')
    if((c.children||[])[0])setDraft(x=>x.child_id?x:{...x,child_id:String(c.children[0].id)})
  }catch(e){setError(e.message)}},[meId])
  useEffect(()=>{load()},[load])

  const open=async(id)=>{try{const d=await fetchCaseDiscussion(id);setSelected(d.discussion)}catch(e){setError(e.message)}}
  const create=async(e)=>{e.preventDefault();setBusy(true);try{
    await createCaseDiscussionWeb({child_id:Number(draft.child_id),topic:draft.topic,description:draft.description,participant_ids:draft.participant_ids})
    setDraft({...draft,topic:'',description:'',participant_ids:[]});await load()
  }catch(e){setError(e.message)}finally{setBusy(false)}}
  const send=async(e)=>{e.preventDefault();if(!selected)return;setBusy(true);try{await sendCaseDiscussionMessage(selected.id,message.content,message.type);setMessage({content:'',type:'text'});await open(selected.id);await load()}catch(e){setError(e.message)}finally{setBusy(false)}}
  const resolve=async()=>{if(!selected)return;setBusy(true);try{await resolveCaseDiscussionWeb(selected.id);await open(selected.id);await load()}catch(e){setError(e.message)}finally{setBusy(false)}}

  return <div className="fp-page">
    <div className="fp-head"><div><h2>📋 دراسات الحالة</h2><div className="meta">نقاش تعاوني بين المعلمين والمختصين</div></div><button className="btn outline" onClick={load}>تحديث</button></div>
    {error&&<div className="fp-error">{error}</div>}
    <section className="fp-card"><h3>دراسة جديدة</h3><form className="fp-form" onSubmit={create}>
      <select value={draft.child_id} onChange={e=>setDraft({...draft,child_id:e.target.value})}>{children.map(c=><option key={c.id} value={c.id}>{c.name}</option>)}</select>
      <input placeholder="موضوع الدراسة" value={draft.topic} onChange={e=>setDraft({...draft,topic:e.target.value})} required/>
      <textarea rows={3} placeholder="وصف الحالة" value={draft.description} onChange={e=>setDraft({...draft,description:e.target.value})}/>
      <div className="fp-checks">{users.map(u=><label className="fp-check" key={u.id}><input type="checkbox" checked={draft.participant_ids.includes(u.id)} onChange={e=>setDraft({...draft,participant_ids:e.target.checked?[...draft.participant_ids,u.id]:draft.participant_ids.filter(id=>id!==u.id)})}/>{u.role==='teacher'?'👨‍🏫':'🧩'} {u.name}</label>)}</div>
      <button className="btn success" disabled={busy||draft.participant_ids.length===0}>إنشاء الدراسة</button>
    </form></section>
    <div className="fp-two"><section className="fp-list">{items.length===0?<div className="fp-empty">لا توجد دراسات</div>:items.map(d=><button key={d.id} className="fp-card" style={{textAlign:'right',cursor:'pointer'}} onClick={()=>open(d.id)}><div className="fp-head"><h3>{d.child_name}</h3><span className="fp-badge">{d.status}</span></div><div>{d.topic}</div><div className="fp-meta">{(d.participants||[]).map(p=>p.name).join('، ')}</div></button>)}</section>
    <section className="fp-card">{!selected?<div className="fp-empty">اختر دراسة لعرض النقاش</div>:<>
      <div className="fp-head"><div><h3>{selected.topic}</h3><div className="meta">{selected.child_name}</div></div><span className="fp-badge">{selected.status}</span></div>
      {selected.description&&<p>{selected.description}</p>}
      <div className="fp-scroll fp-list">{(selected.messages||[]).map(m=><div className="fp-message" key={m.id}><small>{m.sender_name} • {m.sender_role} • {new Date(m.created_at).toLocaleString('ar')} • {m.type}</small><div>{m.content}</div></div>)}</div>
      {selected.status!=='resolved'&&<form className="fp-form" onSubmit={send} style={{marginTop:12}}><select value={message.type} onChange={e=>setMessage({...message,type:e.target.value})}><option value="text">رسالة</option><option value="observation">ملاحظة</option><option value="question">سؤال</option><option value="decision">قرار</option></select><textarea rows={3} value={message.content} onChange={e=>setMessage({...message,content:e.target.value})} placeholder="اكتب الرسالة..." required/><div className="fp-actions"><button className="btn" disabled={busy}>إرسال</button><button type="button" className="btn success" onClick={resolve} disabled={busy}>اعتبارها محلولة</button></div></form>}
    </>}</section></div>
  </div>
}
