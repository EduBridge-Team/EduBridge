import { ArrowLeft, BarChart3, CalendarDays, MessageCircle, PlayCircle, Sparkles } from 'lucide-react'
import { lessonTimeLabel } from './utils'

export default function ParentLowerSections({
  children,
  conversations,
  navigate,
  openNoor,
  visibleLessons,
}) {
  const firstChild = children[0]

  return (
    <div className="pd-fullwidth-lower">
      <div className="pd-lower-grid">
        <section className="pd-section pd-today">
          <div className="pd-section-head">
            <div>
              <div className="pd-title-with-icon">
                <CalendarDays size={23} />
                <h2>دروس ومهام اليوم</h2>
              </div>
              <p>{firstChild ? `المحتوى التعليمي المتاح لـ ${firstChild.name}` : 'أضف طفلاً لعرض الدروس والمهام'}</p>
            </div>
          </div>
          <div className="pd-schedule-list">
            {visibleLessons.slice(0, 3).length ? visibleLessons.slice(0, 3).map((lesson, index) => (
              <article key={lesson.id} className="pd-schedule-row">
                <div className="pd-schedule-time">
                  <span>{lessonTimeLabel(lesson, index)}</span>
                </div>
                <span className={`pd-schedule-icon pd-schedule-icon-${index % 3}`}>
                  {index === 1 ? '🎨' : index === 2 ? '🏠' : '📘'}
                </span>
                <div className="pd-schedule-copy">
                  <strong>{lesson.title}</strong>
                  <small>{firstChild?.name || 'الطفل'} · محتوى تعليمي</small>
                </div>
                <button onClick={() => firstChild && navigate(`/children/${firstChild.id}/lessons`, { state: { childName: firstChild.name } })}>
                  {index === 0 ? 'ابدأ الآن' : 'عرض الدرس'}
                </button>
              </article>
            )) : <div className="pd-mini-empty">لا توجد دروس أو مهام متاحة حالياً.</div>}
          </div>
        </section>

        <section className="pd-section pd-conversations">
          <div className="pd-section-head">
            <div>
              <h2>المحادثات الأخيرة</h2>
              <p>آخر تواصل مع الفريق التعليمي.</p>
            </div>
            <button className="pd-link-btn" onClick={() => navigate('/conversations')}>
              عرض الكل <ArrowLeft size={15} />
            </button>
          </div>
          <div className="pd-list">
            {conversations.slice(0, 3).length ? conversations.slice(0, 3).map((conversation) => (
              <article key={conversation.id} className="pd-chat-row">
                <span className="pd-chat-avatar">{(conversation.other_user_name || 'م').charAt(0)}</span>
                <div>
                  <strong>{conversation.other_user_name || 'فريق EduBridge'}</strong>
                  <small>{conversation.last_message || 'ابدأ المحادثة الآن'}</small>
                </div>
                <span className="pd-chat-dot" />
              </article>
            )) : <div className="pd-mini-empty">لا توجد محادثات بعد.</div>}
          </div>
        </section>
      </div>

      <section className="pd-quick-actions">
        <h2>إجراءات سريعة</h2>
        <button
          className="primary"
          onClick={() => firstChild
            ? navigate(`/children/${firstChild.id}/lessons`, { state: { childName: firstChild.name } })
            : navigate('/lessons')}
        >
          <PlayCircle size={20} /> بدء درس
        </button>
        <button
          onClick={() => firstChild
            ? navigate(`/children/${firstChild.id}/progress`, { state: { childName: firstChild.name } })
            : navigate('/children')}
        >
          <BarChart3 size={19} /> عرض التقرير
        </button>
        <button onClick={() => navigate('/conversations')}>
          <MessageCircle size={19} /> التواصل مع المعلم
        </button>
        <button onClick={openNoor}>
          <Sparkles size={19} /> التحدث مع نور
        </button>
      </section>

    </div>
  )
}
