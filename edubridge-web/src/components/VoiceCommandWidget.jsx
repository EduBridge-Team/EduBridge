import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getToken, getUser } from '../api'
import './VoiceCommandWidget.css'

const MAP=[
  [['الرئيسية','الرئيسيه','هوم'],'/dashboard'],
  [['الاطفال','الأطفال','طفل'],'/children'],
  [['دروس ولي الامر','دروس لولي الامر','نصائح'],'/parent-lessons'],
  [['الدروس','مكتبة الدروس','مكتبه الدروس'],'/lessons'],
  [['الواجبات','واجبات'],'/homeworks'],
  [['التقارير','تقرير اسبوعي','تقرير أسبوعي'],'/weekly-reports'],
  [['الجلسات','الدعم التعليمي','جلسات نفسيه'],'/learning support'],
  [['فريق الرعاية','فريق الطفل','الفريق'],'/care-team'],
  [['دراسات الحالة','دراسة حالة','دراسه حاله'],'/case-discussions'],
  [['اقتراحات المختصين','متابعة المختصين'],'/specialist-workflow'],
  [['التواصل','تواصل بالصور','aac'],'/aac'],
  [['المحادثات','رسائل','شات'],'/conversations'],
  [['الاشعارات','الإشعارات','تنبيهات'],'/notifications'],
  [['الملف الشخصي','ملفي','حسابي'],'/profile'],
  [['الاعدادات','الإعدادات','احتياجات'],'/accessibility'],
  [['الدعم','مساعدة','مساعده'],'/support'],
]

export default function VoiceCommandWidget(){
  const navigate=useNavigate()
  const [hidden,setHidden]=useState(()=>localStorage.getItem('edubridge_voice_hidden')==='1')
  const [listening,setListening]=useState(false)
  const [status,setStatus]=useState('')
  const recognitionRef=useRef(null)

  useEffect(()=>()=>recognitionRef.current?.abort?.(),[])

  if(!getToken())return null
  const me=getUser()
  if(hidden)return <button className="vc-restore" onClick={()=>{localStorage.removeItem('edubridge_voice_hidden');setHidden(false)}} aria-label="إظهار التحكم الصوتي">🎙️</button>

  const reply=(text)=>{setStatus(text);if(window.speechSynthesis){window.speechSynthesis.cancel();const u=new SpeechSynthesisUtterance(text);u.lang='ar';u.rate=.9;window.speechSynthesis.speak(u)}}
  const execute=(raw)=>{
    const text=(raw||'').toLowerCase().trim()
    const hit=MAP.find(([phrases])=>phrases.some(p=>text.includes(p)))
    if(!hit){reply('لم أفهم الأمر. جرّب: الدروس، الواجبات، التقارير، الجلسات، أو التواصل بالصور.');return}
    const path=hit[1]
    if(path==='/parent-lessons'&&me?.role!=='parent'){reply('دروس ولي الأمر متاحة لحساب ولي الأمر.');return}
    if(path==='/case-discussions'&&!['teacher','specialist','admin'].includes(me?.role)){reply('دراسات الحالة غير متاحة لهذا الحساب.');return}
    if(path==='/specialist-workflow'&&!['teacher','specialist','admin'].includes(me?.role)){reply('متابعة المختصين غير متاحة لهذا الحساب.');return}
    reply('حسناً')
    navigate(path)
  }
  const start=()=>{
    const Recognition=window.SpeechRecognition||window.webkitSpeechRecognition
    if(!Recognition){setStatus('المتصفح لا يدعم التعرف الصوتي. استخدم Chrome أو Edge.');return}
    const r=new Recognition();recognitionRef.current=r;r.lang='ar';r.interimResults=false;r.maxAlternatives=1
    r.onstart=()=>{setListening(true);setStatus('أستمع الآن...')}
    r.onerror=()=>{setListening(false);setStatus('تعذّر سماع الأمر')}
    r.onend=()=>setListening(false)
    r.onresult=e=>execute(e.results?.[0]?.[0]?.transcript||'')
    r.start()
  }

  return <div className="vc-widget">
    <button className={listening?'vc-mic is-listening':'vc-mic'} onClick={start} aria-label="الأوامر الصوتية">🎙️</button>
    {status&&<span className="vc-status">{status}</span>}
    <button className="vc-close" onClick={()=>{localStorage.setItem('edubridge_voice_hidden','1');setHidden(true)}} aria-label="إخفاء الميكروفون">×</button>
  </div>
}
