import { useCallback, useEffect, useMemo, useState } from 'react'
import { fetchParentLessons } from '../api'
import '../feature-parity.css'

export default function ParentLessonsPage(){
  const [lessons,setLessons]=useState([])
  const [query,setQuery]=useState('')
  const [error,setError]=useState('')
  const [speakingId,setSpeakingId]=useState(null)

  const load=useCallback(async()=>{try{const d=await fetchParentLessons();setLessons(d.lessons||[]);setError('')}catch(e){setError(e.message)}},[])
  useEffect(()=>{load();return()=>window.speechSynthesis?.cancel()},[load])

  const filtered=useMemo(()=>{
    const q=query.trim()
    if(!q)return lessons
    return lessons.filter(l=>(l.title||'').includes(q)||(l.content||'').includes(q))
  },[lessons,query])

  const speak=(lesson)=>{
    const synth=window.speechSynthesis
    if(!synth)return
    if(speakingId===lesson.id){synth.cancel();setSpeakingId(null);return}
    synth.cancel()
    const u=new SpeechSynthesisUtterance([lesson.title,lesson.content].filter(Boolean).join('. '))
    u.lang='ar'
    u.rate=.85
    u.onend=()=>setSpeakingId(null)
    setSpeakingId(lesson.id)
    synth.speak(u)
  }

  return <div className="fp-page">
    <div className="fp-head"><div><h2>👪 دروس لولي الأمر</h2><div className="meta">نصائح وإرشادات مخصصة لمساعدتك في دعم طفلك</div></div><button className="btn outline" onClick={load}>تحديث</button></div>
    <input type="search" placeholder="ابحث في دروس ولي الأمر..." value={query} onChange={e=>setQuery(e.target.value)}/>
    {error&&<div className="fp-error">{error}</div>}
    <section className="fp-grid">
      {filtered.length===0?<div className="fp-empty">لا توجد دروس مخصصة لأولياء الأمور بعد</div>:filtered.map(l=><article className="fp-card" key={l.id}>
        <div className="fp-head"><h3>{l.title}</h3><span className="fp-badge">لولي الأمر</span></div>
        {l.content&&<p>{l.content}</p>}
        {(l.images||l.image_urls||[]).length>0&&<div className="fp-grid">{(l.images||l.image_urls||[]).map(url=><img key={url} src={url} alt="" style={{width:'100%',height:180,objectFit:'cover',borderRadius:14}}/>)}</div>}
        {l.video_url&&<video controls preload="metadata" style={{width:'100%',borderRadius:14,marginTop:10}}><source src={l.video_url}/>{l.caption_url&&<track kind="captions" src={l.caption_url} srcLang="ar" label="العربية" default/>}</video>}
        {l.audio_url&&<audio controls style={{width:'100%',marginTop:10}}><source src={l.audio_url}/></audio>}
        {l.sign_language_url&&<video controls preload="metadata" style={{width:'100%',borderRadius:14,marginTop:10}}><source src={l.sign_language_url}/></video>}
        {l.audio_description&&<div className="fp-message" style={{marginTop:10}}>🔊 {l.audio_description}</div>}
        <div className="fp-actions"><button className="btn outline small" onClick={()=>speak(l)}>{speakingId===l.id?'إيقاف':'استمع'}</button></div>
      </article>)}
    </section>
  </div>
}
