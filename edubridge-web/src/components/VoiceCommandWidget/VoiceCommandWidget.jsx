import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getToken, getUser } from '../../api'
import './VoiceCommandWidget.css'
import { useUserSettings } from '../../userSettings'
import { resolveVoiceCommand } from './voiceCommands.js'
import { createVoiceRecognition } from './voiceRecognition.js'

export default function VoiceCommandWidget(){
  const navigate=useNavigate()
  const { settings, updateSettings } = useUserSettings()
  const [hidden,setHidden]=useState(()=>localStorage.getItem('edubridge_voice_hidden')==='1')
  const [listening,setListening]=useState(false)
  const [status,setStatus]=useState('')
  const recognitionRef=useRef(null)

  useEffect(()=>()=>recognitionRef.current?.stop(),[])
  useEffect(()=>{ if(hidden || !settings.microphone_visible) recognitionRef.current?.stop() },[hidden,settings.microphone_visible])

  if(!getToken() || !settings.microphone_visible)return null
  if(hidden)return <button className="vc-restore" onClick={()=>{localStorage.removeItem('edubridge_voice_hidden');setHidden(false)}} aria-label="إظهار التحكم الصوتي">🎙️</button>

  const reply=(text)=>{setStatus(text);if(window.speechSynthesis){window.speechSynthesis.cancel();const u=new SpeechSynthesisUtterance(text);u.lang='ar';u.rate=.9;window.speechSynthesis.speak(u)}}
  const execute=(raw)=>{
    const command=resolveVoiceCommand(raw,getUser()?.role)
    if(command.type==='unknown'){reply('لم أفهم الأمر. جرّب: دروس ولي الأمر، التقدم الأسبوعي، فريق الطفل أو المحادثات.');return}
    if(command.type==='denied'){reply('هذه الصفحة غير متاحة لدور حسابك.');return}
    if(command.type==='stop'){window.speechSynthesis?.cancel();setStatus('تم الإيقاف');return}
    if(command.type==='back'){navigate(-1);reply('رجعت للخلف');return}
    if(command.type==='dark'||command.type==='light'){
      updateSettings({theme_mode:command.type}).then(()=>reply('تم تغيير وضع العرض')).catch(()=>reply('تعذّر حفظ وضع العرض'))
      return
    }
    reply('حسناً')
    navigate(command.path)
  }
  const start=()=>{
    if(!recognitionRef.current) recognitionRef.current=createVoiceRecognition(window.SpeechRecognition||window.webkitSpeechRecognition,{
      onStatus:(active,message)=>{setListening(active);if(message!==null)setStatus(message)},
      onCommand:execute,
    })
    window.speechSynthesis?.cancel()
    recognitionRef.current.start()
  }

  return <div className="vc-widget">
    <button className={listening?'vc-mic is-listening':'vc-mic'} onClick={start} aria-label="الأوامر الصوتية">🎙️</button>
    {status&&<span className="vc-status">{status}</span>}
    <button className="vc-close" onClick={()=>{recognitionRef.current?.stop();localStorage.setItem('edubridge_voice_hidden','1');setHidden(true)}} aria-label="إخفاء الميكروفون">×</button>
  </div>
}
