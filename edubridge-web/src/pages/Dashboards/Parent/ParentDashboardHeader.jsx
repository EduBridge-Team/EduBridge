import { CalendarDays, CheckCircle2, Search } from 'lucide-react'

export default function ParentDashboardHeader({
  query,
  setQuery,
  todayLabel,
  user,
}) {
  return (
    <>
      <section className="pd-hero">
        <div className="pd-hero-copy">
          <span>لوحة ولي الأمر</span>
          <h1>مرحباً {user?.name || 'ولي الأمر'} <b>👋</b></h1>
          <h2>من الرائع رؤيتك مجدداً!</h2>
          <p>هنا نظرة سريعة على رحلة أبنائك التعليمية اليوم.</p>
          <label className="pd-hero-search">
            <Search size={18} />
            <input
              aria-label="البحث في لوحة ولي الأمر"
              value={query}
              onChange={(event) => setQuery(event.target.value)}
              placeholder="ابحث عن طفل أو درس..."
            />
          </label>
          <div className="pd-hero-status" aria-label="ملخص اليوم">
            <span><CalendarDays size={15} /> {todayLabel}</span>
            <span><CheckCircle2 size={15} /> تم تحديث بيانات التقدم</span>
          </div>
        </div>
        <span className="pd-deco pd-deco-a" aria-hidden="true">✦</span>
        <span className="pd-deco pd-deco-b" aria-hidden="true">✦</span>
        <span className="pd-deco pd-deco-c" aria-hidden="true">+</span>
      </section>
    </>
  )
}
