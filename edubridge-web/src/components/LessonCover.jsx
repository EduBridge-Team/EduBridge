import { useState } from 'react'
import { BookOpen, CalendarDays, Hand, Heart, MessageCircle, Palette, Shapes, Calculator } from 'lucide-react'
import { lessonCategory } from '../utils/lessonCategories'

function artwork(lesson) {
  const title = lesson.title || ''
  if (/مشاعر|عواطف/.test(title)) return { Icon: Heart, tone: 'teal' }
  if (/روتين|جدول|يوم/.test(title)) return { Icon: CalendarDays, tone: 'teal' }
  if (/إشارة|اشارة/.test(title)) return { Icon: Hand, tone: 'blue' }
  const category = lessonCategory(lesson)
  if (category === 'الرياضيات') return { Icon: Calculator, tone: 'blue' }
  if (category === 'الفنون') return { Icon: Palette, tone: 'teal' }
  if (category === 'التواصل') return { Icon: MessageCircle, tone: 'teal' }
  if (/شكل|أشكال/.test(title)) return { Icon: Shapes, tone: 'blue' }
  return { Icon: BookOpen, tone: 'blue' }
}

export default function LessonCover({ lesson }) {
  const [failedSrc, setFailedSrc] = useState(null)
  const images = lesson.images || lesson.image_urls || []
  const src = Array.isArray(images) ? images[0] : undefined
  const { Icon, tone } = artwork(lesson)
  return (
    <div className={`lesson-visual lesson-cover tone-${tone}`}>
      {src && src !== failedSrc
        ? <img src={src} alt={lesson.title} loading="lazy" onError={() => setFailedSrc(src)} />
        : <div className="lesson-artwork" aria-hidden="true"><span className="art-orbit" /><span className="art-dot" /><Icon size={60} strokeWidth={1.65} /><span className="art-lines"><i /><i /><i /></span></div>}
    </div>
  )
}
