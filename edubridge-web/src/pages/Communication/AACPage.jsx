import { useMemo, useState } from 'react'
import {
  AACCategoryTabs,
  AACSentencePanel,
  AACSymbolGrid,
} from './AACSections'

import { AAC_CATEGORIES as CATEGORIES } from './aacData'

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
