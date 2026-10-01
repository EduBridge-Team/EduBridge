import { useEffect, useId, useMemo, useRef, useState } from 'react'
import { RotateCcw, Volume2, X } from 'lucide-react'
import { speakArabic } from '../../accessibility'
import { recordGameAttempt } from '../../api'
import { questionFor, shuffle } from './educationalGamesData'

function MemoryGame({ profile, onScore }) {
  const [cards, setCards] = useState(() => shuffle(['🐶', '🐱', '🦊', '🐼', '🐶', '🐱', '🦊', '🐼']).map((value, id) => ({ id, value, open: false, done: false })))
  const [locked, setLocked] = useState(false)
  const [attempts, setAttempts] = useState(0)

  const pick = (id) => {
    if (locked || cards[id].open || cards[id].done) return
    const next = cards.map((card) => card.id === id ? { ...card, open: true } : card)
    const open = next.filter((card) => card.open && !card.done)
    setCards(next)

    if (open.length === 2) {
      setAttempts((value) => value + 1)
      setLocked(true)
      setTimeout(() => {
        const match = open[0].value === open[1].value
        const updated = next.map((card) => open.some((item) => item.id === card.id) ? { ...card, open: match, done: match } : card)
        setCards(updated)
        setLocked(false)
        if (updated.every((card) => card.done)) onScore(Math.round(400 / (attempts + 1)))
      }, profile.reducedAnimations ? 250 : 650)
    }
  }

  return <div className="memory-grid">{cards.map((card) => (
    <button
      key={card.id}
      aria-label={card.open || card.done ? card.value : 'بطاقة مخفية'}
      className={card.done ? 'matched' : ''}
      onClick={() => pick(card.id)}
    >
      {card.open || card.done ? card.value : '؟'}
    </button>
  ))}</div>
}

function QuizGame({ game, age, profile, onScore }) {
  const total = 6
  const [round, setRound] = useState(0)
  const [score, setScore] = useState(0)
  const [feedback, setFeedback] = useState('')
  const [countTarget, setCountTarget] = useState(() => 1 + Math.floor(Math.random() * 6))
  const question = useMemo(() => game[6] === 'count'
    ? ['كم عدد النجوم؟', shuffle([countTarget, countTarget + 1, Math.max(1, countTarget - 1), countTarget + 2]).map(String), String(countTarget)]
    : questionFor(game[0], round, age), [game, round, age, countTarget])

  useEffect(() => {
    if (profile.autoReadOnTap) speakArabic(question[0], profile.slowSpeech)
  }, [question, profile.autoReadOnTap, profile.slowSpeech])

  const answer = (value) => {
    if (feedback) return
    const correct = value === question[2]
    setFeedback(correct ? 'أحسنت! إجابة صحيحة ⭐' : `حاول مرة أخرى — الإجابة: ${question[2]}`)
    if (correct) setScore((current) => current + 1)
    setTimeout(() => {
      if (round + 1 >= total) onScore(Math.round(((score + (correct ? 1 : 0)) / total) * 100))
      else {
        setRound((current) => current + 1)
        setCountTarget(1 + Math.floor(Math.random() * 6))
        setFeedback('')
      }
    }, profile.reducedAnimations ? 450 : 900)
  }

  return <div className="quiz-game">
    <div className="game-progress"><span>السؤال {round + 1}/{total}</span><span>⭐ {score}</span></div>
    <h3>{game[6] === 'count' ? <><span className="count-items">{'⭐'.repeat(countTarget)}</span><small>{question[0]}</small></> : question[0]}</h3>
    <div className="answer-grid">{question[1].map((value) => <button key={value} onClick={() => answer(value)}>{value}</button>)}</div>
    {feedback && <div className={feedback.startsWith('أحسنت') ? 'game-good' : 'game-retry'}>{feedback}</div>}
  </div>
}

function SoundGame({ onScore, profile }) {
  const animals = [['كلب', '🐶'], ['قطة', '🐱'], ['عصفور', '🐦'], ['أسد', '🦁']]
  const [round, setRound] = useState(0)
  const [score, setScore] = useState(0)
  const target = animals[round % animals.length]
  const play = () => speakArabic(`صوت ${target[0]}. اختر ${target[0]}`, profile.slowSpeech)
  const pick = (name) => {
    const correct = name === target[0]
    const next = score + (correct ? 1 : 0)
    if (round === 3) onScore(Math.round(next * 25))
    else {
      setScore(next)
      setRound(round + 1)
    }
  }

  return <div className="quiz-game">
    <button className="sound-prompt" onClick={play}><Volume2 /> استمع إلى السؤال</button>
    <div className="answer-grid">{shuffle(animals).map(([name, icon]) => (
      <button key={name} onClick={() => pick(name)}><span className="answer-emoji">{icon}</span>{name}</button>
    ))}</div>
    <p>⭐ {score}</p>
  </div>
}

function QuickGame({ onScore }) {
  const actions = ['صفّق مرة 👏', 'المس رأسك 🙆', 'ارفع يديك 🙌', 'قف ثم اجلس 🧍']
  const [round, setRound] = useState(0)
  return <div className="quick-game">
    <div className="quick-action">{actions[round]}</div>
    <p>نفّذ الحركة ثم اضغط «تم»</p>
    <button className="btn" onClick={() => round === actions.length - 1 ? onScore(100) : setRound(round + 1)}>تم ✓</button>
    <div className="meta">{round + 1}/{actions.length}</div>
  </div>
}

function RhythmGame({ onScore }) {
  const [taps, setTaps] = useState(0)
  const [started, setStarted] = useState(false)
  const tapsRef = useRef(0)
  const tap = () => {
    tapsRef.current += 1
    setTaps(tapsRef.current)
  }
  const start = () => {
    setStarted(true)
    setTaps(0)
    tapsRef.current = 0
    setTimeout(() => onScore(Math.min(100, tapsRef.current * 10 + 50)), 8000)
  }

  return <div className="quick-game">
    <h3>انقر مع الكلمات: جسر · علم · أمل</h3>
    {!started
      ? <button className="btn" onClick={start}>ابدأ الإيقاع</button>
      : <button className="rhythm-pad" onClick={tap}>🎵<small>انقر هنا</small></button>}
    <p>النقرات: {taps}</p>
  </div>
}

export default function GamePlayer({ game, childId, age, profile, close, onRecorded }) {
  const headingId = useId()
  const dialogRef = useRef(null)
  useEffect(() => {
    const opener = document.activeElement
    dialogRef.current?.querySelector('button')?.focus()
    return () => {
      if (opener?.isConnected) opener.focus({ preventScroll: true })
    }
  }, [])

  const handleDialogKeyDown = (event) => {
    if (event.key === 'Escape') {
      event.preventDefault()
      close()
    } else if (event.key === 'Tab') {
      const controls = Array.from(dialogRef.current.querySelectorAll('button:not([disabled])'))
        .filter((control) => control.getClientRects().length > 0)
      const first = controls[0]
      const last = controls.at(-1)
      if (event.shiftKey && document.activeElement === first) {
        event.preventDefault()
        last?.focus()
      } else if (!event.shiftKey && document.activeElement === last) {
        event.preventDefault()
        first?.focus()
      }
    }
  }
  const [result, setResult] = useState(null)
  const [key, setKey] = useState(0)
  const startedAt = useRef(Date.now())
  const recorded = useRef(false)

  const finish = (score) => {
    const normalized = Math.max(0, Math.min(100, Math.round(score)))
    setResult(normalized)

    if (recorded.current || !childId) return
    recorded.current = true

    const starsEarned = normalized >= 90 ? 3 : normalized >= 70 ? 2 : normalized >= 50 ? 1 : 0
    const durationSeconds = Math.max(1, Math.round((Date.now() - startedAt.current) / 1000))
    recordGameAttempt(childId, game[0], normalized, starsEarned, durationSeconds)
      .then((data) => onRecorded?.(data))
      .catch(() => {})
  }

  let content
  if (game[6] === 'matching') content = <MemoryGame key={key} profile={profile} onScore={finish} />
  else if (game[6] === 'sound') content = <SoundGame key={key} profile={profile} onScore={finish} />
  else if (game[6] === 'quick') content = <QuickGame key={key} onScore={finish} />
  else if (game[6] === 'rhythm') content = <RhythmGame key={key} onScore={finish} />
  else content = <QuizGame key={key} game={game} age={age} profile={profile} onScore={finish} />

  return <div className="game-overlay" role="dialog" aria-modal="true" aria-labelledby={headingId} ref={dialogRef} onKeyDown={handleDialogKeyDown}><div className="game-modal">
    <div className="game-modal-head">
      <div><span>{game[1]}</span><h2 id={headingId}>{game[2]}</h2></div>
      <button onClick={close} aria-label="إغلاق"><X /></button>
    </div>
    {result == null
      ? content
      : <div className="game-result">
          <span>🏆</span><h2>أحسنت!</h2><p>نتيجتك <strong>{result}%</strong></p>
          <div>
            <button className="btn outline" onClick={close}>العودة للألعاب</button>
            <button className="btn" onClick={() => { recorded.current = false; startedAt.current = Date.now(); setResult(null); setKey((value) => value + 1) }}>
              <RotateCcw size={17} /> العب مرة أخرى
            </button>
          </div>
        </div>}
  </div></div>
}
