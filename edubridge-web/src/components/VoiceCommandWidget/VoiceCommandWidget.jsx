import { useEffect, useRef, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { getToken, getUser } from '../../api'
import './VoiceCommandWidget.css'
import { useUserSettings } from '../../userSettings'
import { resolveVoiceCommand } from './voiceCommands.js'
import { createVoiceRecognition } from './voiceRecognition.js'

const POSITION_KEY = 'edubridge_voice_position_v1'
const SCREEN_MARGIN = 14
const MOVE_THRESHOLD = 8

const clamp = (value, min, max) => Math.min(Math.max(value, min), max)

export default function VoiceCommandWidget(){
  const navigate=useNavigate()
  const { settings, updateSettings } = useUserSettings()
  const [hidden,setHidden]=useState(()=>localStorage.getItem('edubridge_voice_hidden')==='1')
  const [listening,setListening]=useState(false)
  const [status,setStatus]=useState('')
  const [position,setPosition]=useState(null)
  const [dragging,setDragging]=useState(false)
  const recognitionRef=useRef(null)
  const widgetRef=useRef(null)
  const dragRef=useRef(null)
  const suppressClickRef=useRef(false)

  const bounds=()=>{
    const rect=widgetRef.current?.getBoundingClientRect()
    const width=rect?.width || 96
    const height=rect?.height || 58
    return {
      minX:SCREEN_MARGIN,
      minY:SCREEN_MARGIN,
      maxX:Math.max(SCREEN_MARGIN,window.innerWidth-width-SCREEN_MARGIN),
      maxY:Math.max(SCREEN_MARGIN,window.innerHeight-height-SCREEN_MARGIN),
    }
  }

  const loadPosition=()=>{
    const b=bounds()
    try{
      const saved=JSON.parse(localStorage.getItem(POSITION_KEY)||'{}')
      if(Number.isFinite(saved?.xFraction)&&Number.isFinite(saved?.yFraction)){
        return {
          x:b.minX+(b.maxX-b.minX)*clamp(saved.xFraction,0,1),
          y:b.minY+(b.maxY-b.minY)*clamp(saved.yFraction,0,1),
        }
      }
    }catch{}
    return {
      x:Math.min(20,b.maxX),
      y:Math.max(b.minY,b.maxY-98),
    }
  }

  const savePosition=(next)=>{
    const b=bounds()
    const width=Math.max(1,b.maxX-b.minX)
    const height=Math.max(1,b.maxY-b.minY)
    localStorage.setItem(POSITION_KEY,JSON.stringify({
      xFraction:clamp((next.x-b.minX)/width,0,1),
      yFraction:clamp((next.y-b.minY)/height,0,1),
    }))
  }

  useEffect(()=>()=>recognitionRef.current?.stop(),[])
  useEffect(()=>{ if(hidden || !settings.microphone_visible) recognitionRef.current?.stop() },[hidden,settings.microphone_visible])

  useEffect(()=>{
    if(hidden || !settings.microphone_visible)return undefined
    const frame=requestAnimationFrame(()=>setPosition(loadPosition()))
    const keepInside=()=>setPosition(current=>{
      if(!current)return loadPosition()
      const b=bounds()
      return {x:clamp(current.x,b.minX,b.maxX),y:clamp(current.y,b.minY,b.maxY)}
    })
    window.addEventListener('resize',keepInside)
    return ()=>{cancelAnimationFrame(frame);window.removeEventListener('resize',keepInside)}
  },[hidden,settings.microphone_visible])

  useEffect(()=>{
    if(!position)return
    const frame=requestAnimationFrame(()=>{
      const b=bounds()
      setPosition(current=>current?{x:clamp(current.x,b.minX,b.maxX),y:clamp(current.y,b.minY,b.maxY)}:current)
    })
    return ()=>cancelAnimationFrame(frame)
  },[status])

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

  const startDrag=(event)=>{
    if(!position || (typeof event.button==='number'&&event.button!==0))return
    event.currentTarget.setPointerCapture?.(event.pointerId)
    dragRef.current={
      pointerId:event.pointerId,
      pointerX:event.clientX,
      pointerY:event.clientY,
      startX:position.x,
      startY:position.y,
      lastPosition:position,
      moved:false,
    }
  }

  const moveDrag=(event)=>{
    const drag=dragRef.current
    if(!drag || drag.pointerId!==event.pointerId)return
    const dx=event.clientX-drag.pointerX
    const dy=event.clientY-drag.pointerY
    if(!drag.moved && Math.hypot(dx,dy)<MOVE_THRESHOLD)return
    const b=bounds()
    const next={x:clamp(drag.startX+dx,b.minX,b.maxX),y:clamp(drag.startY+dy,b.minY,b.maxY)}
    drag.moved=true
    drag.lastPosition=next
    setDragging(true)
    setPosition(next)
  }

  const finishDrag=(event)=>{
    const drag=dragRef.current
    if(!drag || drag.pointerId!==event.pointerId)return
    event.currentTarget.releasePointerCapture?.(event.pointerId)
    suppressClickRef.current=drag.moved
    if(drag.moved)savePosition(drag.lastPosition)
    dragRef.current=null
    setDragging(false)
  }

  const cancelDrag=()=>{dragRef.current=null;setDragging(false)}
  const allowClick=(event)=>{
    if(!suppressClickRef.current)return true
    suppressClickRef.current=false
    event.preventDefault()
    event.stopPropagation()
    return false
  }

  return <div
    ref={widgetRef}
    className={dragging?'vc-widget is-dragging':'vc-widget'}
    style={position?{left:`${position.x}px`,top:`${position.y}px`,bottom:'auto'}:undefined}
    onPointerDown={startDrag}
    onPointerMove={moveDrag}
    onPointerUp={finishDrag}
    onPointerCancel={cancelDrag}
    aria-label="التحكم الصوتي. اسحبه لتحريكه"
  >
    <button className={listening?'vc-mic is-listening':'vc-mic'} onClick={(event)=>{if(allowClick(event))start()}} aria-label="الأوامر الصوتية">🎙️</button>
    {status&&<span className="vc-status">{status}</span>}
    <button className="vc-close" onClick={(event)=>{if(!allowClick(event))return;recognitionRef.current?.stop();localStorage.setItem('edubridge_voice_hidden','1');setHidden(true)}} aria-label="إخفاء الميكروفون">×</button>
  </div>
}
