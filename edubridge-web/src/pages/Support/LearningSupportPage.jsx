import { useCallback, useEffect, useState } from 'react'
import { cancelLearningSupportRequestWeb, completeLearningSupportMeetingWeb, createLearningSupportRequestWeb, fetchChildren, fetchLearningSupportRequests, fetchLearningSupportMeetings, getUser, scheduleLearningSupportRequestWeb } from '../../api'
import {
  LearningSupportRequestForm,
  LearningSupportRequests,
  LearningSupportSessions,
} from './LearningSupportSections'
import '../../feature-parity.css'

export default function LearningSupportPage(){
  const me=getUser(); const parent=me?.role==='parent'; const specialist=['specialist','admin'].includes(me?.role)
  const [children,setChildren]=useState([]);const [requests,setRequests]=useState([]);const [sessions,setSessions]=useState([]);const [error,setError]=useState('');const [busy,setBusy]=useState(false)
  const [req,setReq]=useState({child_id:'',reason:'',description:'',urgency:'medium'})
  const [schedule,setSchedule]=useState({}); const [complete,setComplete]=useState({})

  const load=useCallback(async()=>{try{const [c,r,s]=await Promise.all([fetchChildren(),fetchLearningSupportRequests(),fetchLearningSupportMeetings()]);const kids=c.children||[];setChildren(kids);setRequests(r.requests||[]);setSessions(s.sessions||[]);setReq(current=>current.child_id||!kids[0]?current:{...current,child_id:String(kids[0].id)});setError('')}catch(e){setError(e.message)}},[])
  useEffect(()=>{load()},[load])

  const create=async(e)=>{e.preventDefault();setBusy(true);try{await createLearningSupportRequestWeb({...req,child_id:Number(req.child_id)});setReq({...req,reason:'',description:''});await load()}catch(e){setError(e.message)}finally{setBusy(false)}}
  const scheduleOne=async(id)=>{const x=schedule[id]||{};setBusy(true);try{await scheduleLearningSupportRequestWeb(id,{scheduled_at:x.scheduled_at,meeting_link:x.meeting_link,specialist_notes:x.notes});await load()}catch(e){setError(e.message)}finally{setBusy(false)}}
  const finish=async(id)=>{const x=complete[id]||{};setBusy(true);try{await completeLearningSupportMeetingWeb(id,{notes:x.notes||'',recommendations:x.recommendations||'',mood_rating:x.mood?Number(x.mood):null,tags:[]});await load()}catch(e){setError(e.message)}finally{setBusy(false)}}

  const cancelOne = async (id) => {
    try {
      await cancelLearningSupportRequestWeb(id)
      await load()
    } catch (e) {
      setError(e.message)
    }
  }

  return (
    <div className="fp-page">
      <div className="fp-head">
        <div>
          <h2>📘 الدعم والاجتماعات التعليمية</h2>
          <div className="meta">طلبات الدعم، المواعيد، وسجل الجلسات</div>
        </div>
        <button className="btn outline" onClick={load}>تحديث</button>
      </div>

      {error && <div className="fp-error">{error}</div>}

      {parent && (
        <LearningSupportRequestForm
          busy={busy}
          children={children}
          onChange={setReq}
          onSubmit={create}
          request={req}
        />
      )}

      <LearningSupportRequests
        busy={busy}
        onCancel={cancelOne}
        onSchedule={scheduleOne}
        onScheduleChange={setSchedule}
        requests={requests}
        schedule={schedule}
        specialist={specialist}
      />

      <LearningSupportSessions
        complete={complete}
        onComplete={finish}
        onCompleteChange={setComplete}
        sessions={sessions}
        specialist={specialist}
      />
    </div>
  )
}
