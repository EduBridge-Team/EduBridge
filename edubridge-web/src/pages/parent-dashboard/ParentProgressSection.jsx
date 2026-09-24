import { BarChart3, BookOpen, Target, Users } from 'lucide-react'
import { clampPercent } from './utils'

function RingMetric({ value, label, detail, icon, tone = 'cyan' }) {
  const pct = clampPercent(value)
  return (
    <article className={`pd-metric-card pd-metric-${tone}`}>
      <div className="pd-metric-head">
        <span>{label}</span>
        <span className="pd-metric-icon">{icon}</span>
      </div>
      <div className="pd-ring-wrap">
        <div className="pd-ring" style={{ '--pd-progress': `${pct * 3.6}deg` }}>
          <div className="pd-ring-center"><b>{pct}%</b></div>
        </div>
      </div>
      <small>{detail}</small>
    </article>
  )
}

export default function ParentProgressSection({ dashboardStats, children }) {
  return (
    <section className="pd-section pd-progress-section">
      <div className="pd-section-head">
        <div><h2>نظرة على التقدم</h2></div>
        <span className="pd-period">هذا الأسبوع</span>
      </div>

      <div className="pd-metrics-grid">
        <RingMetric
          value={dashboardStats.completion}
          label="الدروس المكتملة"
          detail={dashboardStats.totalLessons ? `${dashboardStats.done} من ${dashboardStats.totalLessons} درساً` : 'لا توجد بيانات دروس بعد'}
          icon={<BookOpen size={20} />}
          tone="blue"
        />
        <RingMetric
          value={dashboardStats.engagement}
          label="المشاركة التعليمية"
          detail="الدروس المكتملة أو قيد التنفيذ"
          icon={<Users size={20} />}
          tone="cyan"
        />
        <article className="pd-metric-card pd-bars-card">
          <div className="pd-metric-head"><span>متوسط النتائج</span><span className="pd-metric-icon"><BarChart3 size={20} /></span></div>
          <div className="pd-bars" aria-hidden="true">
            {[34, 47, 58, 71, dashboardStats.avgScore || 20].map((height, index) => <i key={index} style={{ height: `${Math.max(18, height)}%` }} />)}
          </div>
          <b className="pd-bars-value">{dashboardStats.avgScore ? `${dashboardStats.avgScore}%` : '—'}</b>
          <small>{dashboardStats.avgScore ? 'متوسط نتائج التقييمات' : 'لا توجد نتائج مسجلة بعد'}</small>
        </article>
        <RingMetric
          value={dashboardStats.supportRate}
          label="تحقيق الأهداف"
          detail={children.length ? 'جاهزية ملفات الأطفال للمتابعة' : 'أضف طفلاً للبدء'}
          icon={<Target size={20} />}
          tone="mint"
        />
      </div>
    </section>
  )
}
