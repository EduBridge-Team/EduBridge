import test from 'node:test'
import assert from 'node:assert/strict'
import { resolveVoiceCommand, normalizeVoiceText } from '../src/components/VoiceCommandWidget/voiceCommands.js'
import { createVoiceRecognition } from '../src/components/VoiceCommandWidget/voiceRecognition.js'

test('Arabic commands prioritize specific phrases and normalize speech spelling', () => {
  for (const [text,path] of [
    ['اِفتحْ دُروس ولي الأَمْر!', '/parent-lessons'],
    ['افتح فريق الدعم التعليمي', '/care-team'],
    ['افتح التقدّم الأُسبوعي', '/weekly-reports'],
    ['افتح إعدادات التكيف الخاصة بالطفل', '/accessibility'],
    ['افتح مكتبة الدروس', '/lessons'],
    ['افتح التواصل بالصور', '/conversations?mode=aac'],
    ['الرئيسية', '/specialist'],
  ]) assert.deepEqual(resolveVoiceCommand(text,'specialist'),{type:'navigate',path})
  assert.equal(normalizeVoiceText('إعــدادات التَّكيُّف'), 'اعدادات التكيف')
  assert.equal(resolveVoiceCommand('الدعمة','parent').type,'unknown')
  for(const [text,role] of [['إضافة طفل','teacher'],['إعدادات التكيف','parent'],['الواجبات','ministry'],['الدعم التعليمي','teacher'],['دراسة حالة','parent']])
    assert.equal(resolveVoiceCommand(text,role).type,'denied')
  assert.equal(resolveVoiceCommand('ارجع','parent').type,'back')
})

function fakeRecognition() {
  const sessions=[]
  class Recognition {
    constructor(){sessions.push(this)}
    start(){}
    abort(){this.onend?.()}
    result(text,isFinal=true){this.onresult?.({resultIndex:0,results:[Object.assign([{transcript:text}],{isFinal})]})}
  }
  const commands=[], statuses=[]
  const controller=createVoiceRecognition(Recognition,{onCommand:text=>commands.push(text),onStatus:(...status)=>statuses.push(status)})
  return {sessions,commands,statuses,controller}
}

test('recognition executes only one final result and ignores cancelled sessions',()=>{
  const {controller,sessions,commands}=fakeRecognition()
  controller.start()
  sessions[0].result('دروس',false)
  sessions[0].result('المحادثات')
  sessions[0].result('المحادثات')
  assert.deepEqual(commands,['المحادثات'])
  controller.stop()
  sessions[0].result('الأطفال')
  controller.start()
  controller.start()
  sessions[1].result('الأطفال')
  assert.equal(sessions.length,2)
  assert.deepEqual(commands,['المحادثات'])
})

test('microphone permission failure allows retry and surfaces an actionable message',()=>{
  const {controller,sessions,statuses,commands}=fakeRecognition()
  controller.start()
  sessions[0].onerror({error:'not-allowed'})
  assert.match(statuses.at(-1)[1],/اسمح باستخدام الميكروفون/)
  sessions[0].result('الأطفال')
  controller.start()
  sessions[1].result('المحادثات')
  assert.deepEqual(commands,['المحادثات'])
})
