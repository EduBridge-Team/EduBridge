import { Bell, CalendarDays, CheckCircle2, ChevronDown, Search } from 'lucide-react'

export default function ParentDashboardHeader({
  navigate,
  query,
  setQuery,
  todayLabel,
  unread,
  user,
}) {
  return (
    <>
      <header className="pd-toolbar">
        <label className="pd-search">
          <Search size={20} />
          <input
            aria-label="البحث في لوحة ولي الأمر"
            value={query}
            onChange={(event) => setQuery(event.target.value)}
            placeholder="ابحث عن طفل أو درس..."
          />
        </label>

        <button className="pd-notification" onClick={() => navigate('/notifications')} aria-label="الإشعارات">
          <Bell size={20} />
          {unread > 0 && <span>{Math.min(unread, 99)}</span>}
        </button>

        <button className="pd-profile" onClick={() => navigate('/profile')} aria-label="الملف الشخصي">
          <span className="pd-user-avatar">{(user?.name || 'و').charAt(0)}</span>
          <span className="pd-profile-copy">
            <strong>أهلاً {user?.name || 'ولي الأمر'}</strong>
            <small>ولي أمر</small>
          </span>
          <ChevronDown size={16} className="pd-profile-chevron" aria-hidden="true" />
        </button>
      </header>

      <section className="pd-hero">
        <div className="pd-hero-copy">
          <span>لوحة ولي الأمر</span>
          <h1>مرحباً {user?.name || 'ولي الأمر'} <b>👋</b></h1>
          <h2>من الرائع رؤيتك مجدداً!</h2>
          <p>هنا نظرة سريعة على رحلة أبنائك التعليمية اليوم.</p>
          <div className="pd-hero-status" aria-label="ملخص اليوم">
            <span><CalendarDays size={15} /> {todayLabel}</span>
            <span><CheckCircle2 size={15} /> تم تحديث بيانات التقدم</span>
          </div>
        </div>
        <div className="pd-hero-art" aria-hidden="true">
          <img src="/edubridge-hero-child.webp" alt="" />
        </div>
        <span className="pd-deco pd-deco-a" aria-hidden="true">✦</span>
        <span className="pd-deco pd-deco-b" aria-hidden="true">✦</span>
        <span className="pd-deco pd-deco-c" aria-hidden="true">+</span>
      </section>
    </>
  )
}
