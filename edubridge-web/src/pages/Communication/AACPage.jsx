import { useMemo, useState } from 'react'
import {
  AACCategoryTabs,
  AACSentencePanel,
  AACSymbolGrid,
} from './AACSections'
import '../../feature-parity.css'

const CATEGORIES = {
  'أساسية': [
    ['👋', 'مرحباً', 'مرحبا'],
    ['🙋', 'أنا', 'أنا'],
    ['✅', 'نعم', 'نعم'],
    ['❌', 'لا', 'لا'],
    ['🙏', 'شكراً', 'شكرا'],
    ['🙋‍♂️', 'من فضلك', 'من فضلك'],
    ['😊', 'سعيد', 'أنا سعيد'],
    ['😢', 'حزين', 'أنا حزين'],
  ],
  'احتياجات': [
    ['💧', 'ماء', 'أريد ماء'],
    ['🍎', 'طعام', 'أريد طعام'],
    ['🚽', 'حمام', 'أريد الحمام'],
    ['😴', 'نوم', 'أريد أن أنام'],
    ['🤒', 'مرض', 'أنا مريض'],
    ['🥶', 'بارد', 'أشعر بالبرد'],
    ['🥵', 'حار', 'أشعر بالحرارة'],
    ['🤗', 'عناق', 'أريد عناق'],
  ],
  'مشاعر': [
    ['😡', 'غاضب', 'أنا غاضب'],
    ['😨', 'خائف', 'أنا خائف'],
    ['😕', 'مرتبك', 'أنا مرتبك'],
    ['🥰', 'محبوب', 'أشعر بالحب'],
    ['😔', 'متعب', 'أنا متعب'],
    ['😃', 'متحمس', 'أنا متحمس'],
    ['🤔', 'أفكر', 'أنا أفكر'],
    ['😌', 'مرتاح', 'أنا مرتاح'],
  ],
  'أنشطة': [
    ['🎮', 'ألعب', 'أريد أن ألعب'],
    ['📚', 'أقرأ', 'أريد أن أقرأ'],
    ['🎨', 'أرسم', 'أريد أن أرسم'],
    ['🎵', 'أسمع', 'أريد سماع موسيقى'],
    ['🎬', 'أشاهد', 'أريد مشاهدة'],
    ['🏃', 'أتحرك', 'أريد أن أتحرك'],
    ['🛏️', 'أرتاح', 'أريد الراحة'],
    ['📝', 'أدرس', 'أريد أن أدرس'],
  ],
  'أشخاص': [
    ['👩', 'أمي', 'أريد أمي'],
    ['👨', 'أبي', 'أريد أبي'],
    ['👶', 'أخي', 'أريد أخي'],
    ['👧', 'أختي', 'أريد أختي'],
    ['👨‍🏫', 'معلمي', 'أريد معلمي'],
    ['🧑‍⚕️', 'الطبيب', 'أريد الطبيب'],
    ['🧩', 'المختص', 'أريد المختص'],
    ['👥', 'أصدقائي', 'أريد أصدقائي'],
  ],
}

function speak(text) {
  const synth = window.speechSynthesis
  if (!synth) return

  synth.cancel()
  const utterance = new SpeechSynthesisUtterance(text)
  utterance.lang = 'ar'
  utterance.rate = 0.82
  synth.speak(utterance)
}

export default function AACPage() {
  const [category, setCategory] = useState('أساسية')
  const [sentence, setSentence] = useState([])

  const items = useMemo(
    () => CATEGORIES[category] || [],
    [category],
  )

  const addSymbol = (label, spoken) => {
    setSentence((current) => [...current, label])
    speak(spoken)
  }

  return (
    <div className="fp-page aac-page">
      <section className="fp-hero aac-hero">
        <div>
          <span className="fp-eyebrow">التواصل البديل والمعزز</span>
          <h1>تواصل بالصور</h1>
          <p>اختر الرموز لبناء جملة واضحة ثم استخدم القراءة الصوتية للتعبير عنها.</p>
        </div>
      </section>

      <AACSentencePanel
        sentence={sentence}
        onClear={() => setSentence([])}
        onRemoveLast={() => setSentence((current) => current.slice(0, -1))}
        onSpeak={() => speak(sentence.join(' '))}
      />

      <AACCategoryTabs
        categories={Object.keys(CATEGORIES)}
        selectedCategory={category}
        onSelect={setCategory}
      />

      <AACSymbolGrid
        items={items}
        onSelect={addSymbol}
      />
    </div>
  )
}
