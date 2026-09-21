import { useMemo, useState } from 'react'
import '../feature-parity.css'

const CATEGORIES={
  'أساسية':[['👋','مرحباً','مرحبا'],['🙋','أنا','أنا'],['✅','نعم','نعم'],['❌','لا','لا'],['🙏','شكراً','شكرا'],['🙋‍♂️','من فضلك','من فضلك'],['😊','سعيد','أنا سعيد'],['😢','حزين','أنا حزين']],
  'احتياجات':[['💧','ماء','أريد ماء'],['🍎','طعام','أريد طعام'],['🚽','حمام','أريد الحمام'],['😴','نوم','أريد أن أنام'],['🤒','مرض','أنا مريض'],['🥶','بارد','أشعر بالبرد'],['🥵','حار','أشعر بالحرارة'],['🤗','عناق','أريد عناق']],
  'مشاعر':[['😡','غاضب','أنا غاضب'],['😨','خائف','أنا خائف'],['😕','مرتبك','أنا مرتبك'],['🥰','محبوب','أشعر بالحب'],['😔','متعب','أنا متعب'],['😃','متحمس','أنا متحمس'],['🤔','أفكر','أنا أفكر'],['😌','مرتاح','أنا مرتاح']],
  'أنشطة':[['🎮','ألعب','أريد أن ألعب'],['📚','أقرأ','أريد أن أقرأ'],['🎨','أرسم','أريد أن أرسم'],['🎵','أسمع','أريد سماع موسيقى'],['🎬','أشاهد','أريد مشاهدة'],['🏃','أتحرك','أريد أن أتحرك'],['🛏️','أرتاح','أريد الراحة'],['📝','أدرس','أريد أن أدرس']],
  'أشخاص':[['👩','أمي','أريد أمي'],['👨','أبي','أريد أبي'],['👶','أخي','أريد أخي'],['👧','أختي','أريد أختي'],['👨‍🏫','معلمي','أريد معلمي'],['🧑‍⚕️','الطبيب','أريد الطبيب'],['🧩','المختص','أريد المختص'],['👥','أصدقائي','أريد أصدقائي']]
}

function speak(text){if(!window.speechSynthesis)return;window.speechSynthesis.cancel();const u=new SpeechSynthesisUtterance(text);u.lang='ar';u.rate=.82;window.speechSynthesis.speak(u)}

export default function AACPage(){
  const [category,setCategory]=useState('أساسية')
  const [sentence,setSentence]=useState([])
  const items=useMemo(()=>CATEGORIES[category]||[],[category])
  const add=(label,spoken)=>{setSentence(s=>[...s,label]);speak(spoken)}
  return <div className="fp-page aac-page">
    <div className="fp-head"><div><h2>🗣️ تواصل بالصور</h2><div className="meta">اختر الصور لبناء جملة ثم اضغط «قلها»</div></div></div>
    <section className="fp-card">
      <div className="aac-sentence">{sentence.length?sentence.map((w,i)=><span key={i} className="fp-badge">{w}</span>):<span className="meta">اضغط على الصور لبناء جملة</span>}</div>
      <div className="fp-actions"><button className="btn success" onClick={()=>sentence.length&&speak(sentence.join(' '))}>🔊 قلها</button><button className="btn outline" onClick={()=>setSentence(s=>s.slice(0,-1))}>⌫ حذف آخر</button><button className="btn outline" onClick={()=>setSentence([])}>مسح</button></div>
    </section>
    <div className="fp-actions">{Object.keys(CATEGORIES).map(c=><button key={c} className={c===category?'btn':'btn outline'} onClick={()=>setCategory(c)}>{c}</button>)}</div>
    <section className="aac-grid">{items.map(([emoji,label,spoken])=><button className="aac-tile" key={label+spoken} onClick={()=>add(label,spoken)}><span>{emoji}</span><strong>{label}</strong></button>)}</section>
  </div>
}
