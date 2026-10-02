import { useEffect, useMemo, useState } from 'react'
import { fetchSignLanguageCategories, fetchSignLanguageSigns } from '../../api'
import './SignLanguagePage.css'

const CATEGORY_LABELS = { math: 'الرياضيات', science: 'العلوم' }

export default function SignLanguagePage() {
  const [query, setQuery] = useState('')
  const [category, setCategory] = useState('')
  const [categories, setCategories] = useState([])
  const [signs, setSigns] = useState([])
  const [selected, setSelected] = useState(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState('')

  useEffect(() => {
    let active = true
    fetchSignLanguageCategories()
      .then((data) => { if (active) setCategories(data.categories ?? []) })
      .catch(() => {})
    return () => { active = false }
  }, [])

  useEffect(() => {
    let active = true
    setLoading(true)
    setError('')
    const timer = window.setTimeout(() => {
      fetchSignLanguageSigns({
        per_page: 100,
        ...(query.trim() ? { q: query.trim() } : {}),
        ...(category ? { category } : {}),
      })
        .then((data) => { if (active) setSigns(data.signs ?? []) })
        .catch((err) => { if (active) setError(err?.message || 'تعذّر تحميل قاموس لغة الإشارة') })
        .finally(() => { if (active) setLoading(false) })
    }, 180)
    return () => { active = false; window.clearTimeout(timer) }
  }, [query, category])

  const total = useMemo(
    () => categories.reduce((sum, item) => sum + Number(item.total || 0), 0),
    [categories],
  )

  return (
    <div className="psl-page" dir="rtl">
      <section className="psl-hero">
        <div>
          <span className="psl-kicker">🤟 إمكانية الوصول</span>
          <h1>قاموس لغة الإشارة الفلسطينية</h1>
          <p>مفاهيم تعليمية فلسطينية موثقة للرياضيات والعلوم. سنضيف الفيديوهات تلقائياً عند توفر الوسائط الأصلية من المصدر.</p>
        </div>
        <div className="psl-stat">
          <strong>{total || 76}</strong>
          <span>إشارة مراجعة ومتاحة</span>
        </div>
      </section>

      <section className="psl-toolbar" aria-label="بحث وتصفية قاموس لغة الإشارة">
        <label className="psl-search">
          <span>بحث</span>
          <input value={query} onChange={(event) => setQuery(event.target.value)} placeholder="ابحث بالعربية أو الإنجليزية..." />
        </label>
        <div className="psl-filters">
          <button className={!category ? 'active' : ''} onClick={() => setCategory('')}>الكل</button>
          {categories.map((item) => (
            <button key={item.category} className={category === item.category ? 'active' : ''} onClick={() => setCategory(item.category)}>
              {CATEGORY_LABELS[item.category] ?? item.category}<span>{item.total}</span>
            </button>
          ))}
        </div>
      </section>

      {loading ? <div className="psl-state">جارِ تحميل الإشارات…</div>
        : error ? <div className="psl-state error">{error}</div>
        : signs.length === 0 ? <div className="psl-state">لا توجد إشارات مطابقة.</div>
        : <section className="psl-grid">
            {signs.map((sign) => (
              <button className="psl-card" key={sign.id} onClick={() => setSelected(sign)}>
                <div className="psl-card-icon" aria-hidden="true">🤟</div>
                <div className="psl-card-copy">
                  <h2>{sign.arabic_label}</h2>
                  <p>{sign.english_label}</p>
                  <span>{CATEGORY_LABELS[sign.category] ?? sign.category}</span>
                </div>
                <div className="psl-media-status">{sign.media_url ? 'شاهد الإشارة' : 'الفيديو قريباً'}</div>
              </button>
            ))}
          </section>}

      {selected && (
        <div className="psl-modal-backdrop" role="presentation" onClick={() => setSelected(null)}>
          <section className="psl-modal" role="dialog" aria-modal="true" aria-labelledby="psl-sign-title" onClick={(event) => event.stopPropagation()}>
            <button className="psl-close" aria-label="إغلاق" onClick={() => setSelected(null)}>×</button>
            <div className="psl-modal-icon">🤟</div>
            <h2 id="psl-sign-title">{selected.arabic_label}</h2>
            <p className="psl-english">{selected.english_label}</p>
            <span className="psl-category">{CATEGORY_LABELS[selected.category] ?? selected.category}</span>
            {selected.media_url ? <video controls playsInline src={selected.media_url} />
              : <div className="psl-media-placeholder"><strong>الفيديو الأصلي غير متاح بعد</strong><p>المدخل جاهز، وسيظهر الفيديو هنا مباشرة عند إضافته للمصدر.</p></div>}
            <button
              className="btn"
              type="button"
              onClick={() => {
                const prompt = `اشرح لي مفهوم "${selected.arabic_label}" (${selected.english_label}) بطريقة تعليمية مبسطة، واذكر أنه موجود في قاموس لغة الإشارة الفلسطينية داخل EduBridge.`
                window.dispatchEvent(new CustomEvent('edubridge:noor-open', { detail: { prompt } }))
                setSelected(null)
              }}
            >
              ✨ اسأل نور عن هذا المفهوم
            </button>
            <p className="psl-noor-note">سيفتح نور مع السؤال جاهزاً ويمكنك تعديله قبل الإرسال.</p>
          </section>
        </div>
      )}
    </div>
  )
}
