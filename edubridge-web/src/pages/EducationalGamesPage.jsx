import { useEffect, useMemo, useRef, useState } from 'react'
import { useLocation, useNavigate, useParams } from 'react-router-dom'
import { ArrowRight, RotateCcw, Settings, Volume2, X } from 'lucide-react'
import { fetchChildDetails } from '../api'
import { applyAccessibilityProfile, getAccessibilityProfile, speakArabic, typeFromText } from '../accessibility'

const GAMES = [
  ['animal_sounds', '🐶', 'أصوات الحيوانات', 'استمع وحدّد الحيوان', ['preschool', 'primary'], [], 'sound'],
  ['matching', '🎴', 'المطابقة', 'اعثر على البطاقات المتشابهة', ['preschool', 'primary'], [], 'matching'],
  ['shapes', '🔺', 'الأشكال', 'تعرّف على الأشكال الهندسية', ['preschool', 'primary'], [], 'quiz'],
  ['colors_simple', '🎨', 'الألوان', 'اختر اللون الصحيح', ['preschool'], [], 'quiz'],
  ['colors_symbols', '🌈', 'الألوان بالرموز', 'تعلّم الألوان بالرمز والنمط', ['preschool', 'primary', 'preparatory'], ['colorBlindness', 'blind'], 'quiz'],
  ['numbers_count', '🔢', 'العدّ البسيط', 'اعدّ من 1 إلى 10', ['preschool'], [], 'count'],
  ['numbers_math', '➕', 'سباق الحساب', 'حلّ مسائل مناسبة للعمر', ['primary', 'preparatory'], [], 'math'],
  ['visual_words', '🖼️', 'الكلمات البصرية', 'اربط الصورة بالكلمة', ['preschool', 'primary'], [], 'quiz'],
  ['word_builder', '🔤', 'بناء الكلمة', 'اختر حروف الكلمة الصحيحة', ['primary', 'preparatory'], [], 'quiz'],
  ['sequence_simple', '🧩', 'الترتيب البسيط', 'أكمل التسلسل', ['preschool', 'primary'], [], 'quiz'],
  ['story_sequencer', '📖', 'رتّب القصة', 'اختر الحدث التالي في القصة', ['primary', 'preparatory'], [], 'quiz'],
  ['logic_puzzle', '🧠', 'لغز المنطق', 'فكّر وحلّ اللغز', ['preparatory'], [], 'quiz'],
  ['audio_matching', '🎧', 'لعبة الأصوات', 'استمع وطابق الصوت', ['preschool', 'primary', 'preparatory'], ['blind'], 'sound'],
  ['sign_language', '🤟', 'لغة الإشارة', 'تعرّف إلى حروف لغة الإشارة', ['preschool', 'primary', 'preparatory'], ['deaf'], 'quiz'],
  ['quick_action', '⚡', 'الحركة السريعة', 'نفّذ التعليمات بسرعة', ['preschool', 'primary'], ['adhd'], 'quick'],
  ['rhythm', '🎵', 'الإيقاع', 'انقر مع إيقاع الكلمات', ['preschool', 'primary', 'preparatory'], ['stuttering', 'speechDisorders'], 'rhythm'],
]

const ageGroup = (age) => age <= 6 ? 'preschool' : age <= 10 ? 'primary' : 'preparatory'
const ageLabel = (g) => ({ preschool: 'رياض الأطفال (4–6)', primary: 'الابتدائي (7–10)', preparatory: 'الإعدادي (11–15)' }[g])
const shuffle = (items) => [...items].sort(() => Math.random() - 0.5)

function questionFor(id, round, age) {
  const sets = {
    shapes: [
      ['ما الشكل الذي له ثلاثة أضلاع؟', ['مثلث', 'مربع', 'دائرة', 'مستطيل'], 'مثلث'],
      ['ما الشكل الذي ليس له زوايا؟', ['دائرة', 'مثلث', 'مربع', 'نجمة'], 'دائرة'],
      ['ما الشكل الذي له أربعة أضلاع متساوية؟', ['مربع', 'دائرة', 'مثلث', 'بيضاوي'], 'مربع'],
    ],
    colors_simple: [
      ['ما لون الشمس غالباً؟', ['أصفر', 'أزرق', 'أخضر', 'بنفسجي'], 'أصفر'],
      ['ما لون العشب؟', ['أخضر', 'أحمر', 'أسود', 'برتقالي'], 'أخضر'],
      ['ما لون السماء الصافية؟', ['أزرق', 'بني', 'وردي', 'رمادي'], 'أزرق'],
    ],
    colors_symbols: [
      ['أي رمز يمثّل الأحمر؟  ▲ أحمر · ● أزرق', ['▲', '●', '■', '◆'], '▲'],
      ['أي رمز يمثّل الأزرق؟  ▲ أحمر · ● أزرق', ['●', '▲', '■', '◆'], '●'],
      ['أي اختيار يجمع اللون ورمزه الصحيح؟', ['أحمر ▲', 'أحمر ●', 'أزرق ▲', 'أخضر ▲'], 'أحمر ▲'],
    ],
    visual_words: [
      ['🐱', ['قطة', 'شجرة', 'كتاب', 'قمر'], 'قطة'], ['🍎', ['تفاحة', 'سيارة', 'سمكة', 'بيت'], 'تفاحة'],
      ['📚', ['كتب', 'ماء', 'باب', 'طائر'], 'كتب'], ['🌙', ['قمر', 'شمس', 'وردة', 'قلم'], 'قمر'],
    ],
    word_builder: [
      ['رتّب حروف: ت ـ ي ـ ب', ['بيت', 'تيب', 'ثبت', 'باب'], 'بيت'],
      ['رتّب حروف: م ـ ل ـ ق', ['قلم', 'ملق', 'علم', 'قمر'], 'قلم'],
      ['رتّب حروف: ب ـ ا ـ ت ـ ك', ['كتاب', 'كاتب', 'كبات', 'باب'], 'كتاب'],
    ],
    sequence_simple: [
      ['أكمل: 1، 2، 3، ...', ['4', '6', '2', '8'], '4'],
      ['أكمل: 🔴 🔵 🔴 🔵 ...', ['🔴', '🟢', '🟡', '⚫'], '🔴'],
      ['أكمل: صغير، متوسط، ...', ['كبير', 'قصير', 'خفيف', 'بطيء'], 'كبير'],
    ],
    story_sequencer: [
      ['استيقظ سامر، ثم غسل وجهه. ماذا يفعل بعد ذلك؟', ['يتناول الفطور', 'يعود للنوم في المدرسة', 'يطير', 'يطفئ الشمس'], 'يتناول الفطور'],
      ['زرعنا بذرة وسقيناها. ماذا يحدث لاحقاً؟', ['تنبت', 'تختفي السماء', 'تصبح حجراً', 'تتجمد فوراً'], 'تنبت'],
      ['فتحنا الكتاب وقرأنا الدرس. ما الخطوة الأخيرة؟', ['نراجع ما تعلمناه', 'نمزق الكتاب', 'ننسى العنوان', 'نطفئ الماء'], 'نراجع ما تعلمناه'],
    ],
    logic_puzzle: [
      ['كل الطيور لها أجنحة، والعصفور طائر. ماذا نعرف؟', ['للعصفور أجنحة', 'العصفور سمكة', 'لا يملك ريشاً', 'لا شيء'], 'للعصفور أجنحة'],
      ['أي عدد لا ينتمي: 2، 4، 6، 7؟', ['7', '2', '4', '6'], '7'],
      ['إذا كان أحمد أطول من علي، وعلي أطول من سامر، فمن الأطول؟', ['أحمد', 'علي', 'سامر', 'متساوون'], 'أحمد'],
    ],
    sign_language: [
      ['🤟 تُستخدم لغة الإشارة أساساً للتواصل عبر:', ['حركة اليدين وتعابير الوجه', 'الألوان فقط', 'الروائح', 'الأرقام فقط'], 'حركة اليدين وتعابير الوجه'],
      ['لماذا يجب النظر إلى وجه الشخص أثناء الإشارة؟', ['لأن تعبير الوجه جزء من المعنى', 'لعدّ الحروف', 'لرفع الصوت', 'لا داعي'], 'لأن تعبير الوجه جزء من المعنى'],
      ['ما التصرف الصحيح قبل بدء الحديث بلغة الإشارة؟', ['لفت الانتباه بلطف', 'إدارة الظهر', 'إطفاء الضوء', 'تغطية اليدين'], 'لفت الانتباه بلطف'],
    ],
  }
  if (id === 'numbers_math') {
    const max = age > 10 ? 20 : 10
    const a = 1 + Math.floor(Math.random() * max), b = 1 + Math.floor(Math.random() * max)
    const answer = a + b
    return [`${a} + ${b} = ؟`, shuffle([answer, answer + 1, Math.max(0, answer - 1), answer + 2]).map(String), String(answer)]
  }
  const rows = sets[id] || sets.logic_puzzle
  return rows[round % rows.length]
}

function MemoryGame({ profile, onScore }) {
  const [cards, setCards] = useState(() => shuffle(['🐶', '🐱', '🦊', '🐼', '🐶', '🐱', '🦊', '🐼']).map((value, id) => ({ id, value, open: false, done: false })))
  const [locked, setLocked] = useState(false)
  const [attempts, setAttempts] = useState(0)
  const pick = (id) => {
    if (locked || cards[id].open || cards[id].done) return
    const next = cards.map((c) => c.id === id ? { ...c, open: true } : c)
    const open = next.filter((c) => c.open && !c.done)
    setCards(next)
    if (open.length === 2) {
      setAttempts((v) => v + 1); setLocked(true)
      setTimeout(() => {
        const match = open[0].value === open[1].value
        const updated = next.map((c) => open.some((o) => o.id === c.id) ? { ...c, open: match, done: match } : c)
        setCards(updated); setLocked(false)
        if (updated.every((c) => c.done)) onScore(Math.round(400 / (attempts + 1)))
      }, profile.reducedAnimations ? 250 : 650)
    }
  }
  return <div className="memory-grid">{cards.map((c) => <button key={c.id} aria-label={c.open || c.done ? c.value : 'بطاقة مخفية'} className={c.done ? 'matched' : ''} onClick={() => pick(c.id)}>{c.open || c.done ? c.value : '؟'}</button>)}</div>
}

function QuizGame({ game, age, profile, onScore }) {
  const total = 6
  const [round, setRound] = useState(0), [score, setScore] = useState(0), [feedback, setFeedback] = useState('')
  const [countTarget, setCountTarget] = useState(() => 1 + Math.floor(Math.random() * 6))
  const q = useMemo(() => game[6] === 'count'
    ? ['كم عدد النجوم؟', shuffle([countTarget, countTarget + 1, Math.max(1, countTarget - 1), countTarget + 2]).map(String), String(countTarget)]
    : questionFor(game[0], round, age), [game, round, age, countTarget])
  useEffect(() => { if (profile.autoReadOnTap) speakArabic(q[0], profile.slowSpeech) }, [q, profile.autoReadOnTap, profile.slowSpeech])
  const answer = (value) => {
    if (feedback) return
    const correct = value === q[2]
    setFeedback(correct ? 'أحسنت! إجابة صحيحة ⭐' : `حاول مرة أخرى — الإجابة: ${q[2]}`)
    if (correct) setScore((v) => v + 1)
    setTimeout(() => {
      if (round + 1 >= total) onScore(Math.round(((score + (correct ? 1 : 0)) / total) * 100))
      else { setRound((v) => v + 1); setCountTarget(1 + Math.floor(Math.random() * 6)); setFeedback('') }
    }, profile.reducedAnimations ? 450 : 900)
  }
  return <div className="quiz-game">
    <div className="game-progress"><span>السؤال {round + 1}/{total}</span><span>⭐ {score}</span></div>
    <h3>{game[6] === 'count' ? <><span className="count-items">{'⭐'.repeat(countTarget)}</span><small>{q[0]}</small></> : q[0]}</h3>
    <div className="answer-grid">{q[1].map((v) => <button key={v} onClick={() => answer(v)}>{v}</button>)}</div>
    {feedback && <div className={feedback.startsWith('أحسنت') ? 'game-good' : 'game-retry'}>{feedback}</div>}
  </div>
}

function SoundGame({ onScore, profile }) {
  const animals = [['كلب', '🐶'], ['قطة', '🐱'], ['عصفور', '🐦'], ['أسد', '🦁']]
  const [round, setRound] = useState(0), [score, setScore] = useState(0)
  const target = animals[round % animals.length]
  const play = () => speakArabic(`صوت ${target[0]}. اختر ${target[0]}`, profile.slowSpeech)
  const pick = (name) => {
    const correct = name === target[0], next = score + (correct ? 1 : 0)
    if (round === 3) onScore(Math.round(next * 25)); else { setScore(next); setRound(round + 1) }
  }
  return <div className="quiz-game"><button className="sound-prompt" onClick={play}><Volume2 /> استمع إلى السؤال</button><div className="answer-grid">{shuffle(animals).map(([name, icon]) => <button key={name} onClick={() => pick(name)}><span className="answer-emoji">{icon}</span>{name}</button>)}</div><p>⭐ {score}</p></div>
}

function QuickGame({ onScore }) {
  const actions = ['صفّق مرة 👏', 'المس رأسك 🙆', 'ارفع يديك 🙌', 'قف ثم اجلس 🧍']
  const [round, setRound] = useState(0)
  return <div className="quick-game"><div className="quick-action">{actions[round]}</div><p>نفّذ الحركة ثم اضغط «تم»</p><button className="btn" onClick={() => round === 4 ? onScore(100) : setRound(round + 1)}>تم ✓</button><div className="meta">{round + 1}/5</div></div>
}

function RhythmGame({ onScore }) {
  const [taps, setTaps] = useState(0), [started, setStarted] = useState(false)
  const tapsRef = useRef(0)
  const tap = () => { tapsRef.current += 1; setTaps(tapsRef.current) }
  const start = () => { setStarted(true); setTaps(0); tapsRef.current = 0; setTimeout(() => onScore(Math.min(100, tapsRef.current * 10 + 50)), 8000) }
  return <div className="quick-game"><h3>انقر مع الكلمات: جسر · علم · أمل</h3>{!started ? <button className="btn" onClick={start}>ابدأ الإيقاع</button> : <button className="rhythm-pad" onClick={tap}>🎵<small>انقر هنا</small></button>}<p>النقرات: {taps}</p></div>
}

function GamePlayer({ game, age, profile, close }) {
  const [result, setResult] = useState(null), [key, setKey] = useState(0)
  const finish = (score) => setResult(Math.min(100, score))
  let content
  if (game[6] === 'matching') content = <MemoryGame key={key} profile={profile} onScore={finish} />
  else if (game[6] === 'sound') content = <SoundGame key={key} profile={profile} onScore={finish} />
  else if (game[6] === 'quick') content = <QuickGame key={key} onScore={finish} />
  else if (game[6] === 'rhythm') content = <RhythmGame key={key} onScore={finish} />
  else content = <QuizGame key={key} game={game} age={age} profile={profile} onScore={finish} />
  return <div className="game-overlay" role="dialog" aria-modal="true"><div className="game-modal">
    <div className="game-modal-head"><div><span>{game[1]}</span><h2>{game[2]}</h2></div><button onClick={close} aria-label="إغلاق"><X /></button></div>
    {result == null ? content : <div className="game-result"><span>🏆</span><h2>أحسنت!</h2><p>نتيجتك <strong>{result}%</strong></p><div><button className="btn outline" onClick={close}>العودة للألعاب</button><button className="btn" onClick={() => { setResult(null); setKey((v) => v + 1) }}><RotateCcw size={17} /> العب مرة أخرى</button></div></div>}
  </div></div>
}

export default function EducationalGamesPage() {
  const { childId } = useParams(), navigate = useNavigate(), location = useLocation()
  const [child, setChild] = useState({ name: location.state?.childName || 'الطفل', age: 8 })
  const [profile, setProfile] = useState(null), [active, setActive] = useState(null), breakTimer = useRef(null)
  useEffect(() => {
    fetchChildDetails(childId).then((data) => {
      const c = data.child || data, p = getAccessibilityProfile(childId, c.disability_type)
      setChild(c); setProfile(p); applyAccessibilityProfile(p)
    })
    return () => clearTimeout(breakTimer.current)
  }, [childId])
  const group = ageGroup(Number(child.age) || 8), type = profile?.type || typeFromText(child.disability_type)
  const games = useMemo(() => GAMES.filter((g) => g[4].includes(group) && (g[5].length === 0 || g[5].includes(type))), [group, type])
  const open = (game) => {
    setActive(game)
    if (profile?.brainBreaksEnabled) breakTimer.current = setTimeout(() => alert('حان وقت فاصل ذهني قصير 🌿'), profile.brainBreakIntervalMinutes * 60000)
  }
  if (!profile) return <div className="state"><div className="spinner" />جارِ تجهيز الألعاب...</div>
  return <div className="games-page">
    <div className="page-title"><button className="back-btn" onClick={() => navigate(-1)}><ArrowRight size={18} /></button><h2>الألعاب التعليمية</h2><span style={{ flex: 1 }} /><button className="btn small outline" onClick={() => navigate(`/children/${childId}/accessibility`)}><Settings size={16} /> إعدادات الوصول</button></div>
    <section className="games-hero"><span>{type === 'blind' ? '🎧' : type === 'deaf' ? '🤟' : '🎉'}</span><div><h2>وقت المرح يا {child.name}!</h2><p>{games.length} ألعاب مناسبة لعمرك — {ageLabel(group)}</p></div></section>
    <div className="games-grid">{games.map((g) => <button className="game-card" key={g[0]} onClick={() => open(g)}><span className="game-emoji">{g[1]}</span><span><strong>{g[2]}</strong><small>{g[3]}</small></span><b>ابدأ ←</b></button>)}</div>
    {active && <GamePlayer game={active} age={Number(child.age) || 8} profile={profile} close={() => { clearTimeout(breakTimer.current); setActive(null) }} />}
  </div>
}
