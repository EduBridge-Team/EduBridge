const PAGE_LABELS = [
  [/\/children|\/kids/i, 'صفحة الأطفال'],
  [/\/lessons/i, 'صفحة الدروس'],
  [/\/assignments|\/homework/i, 'صفحة الواجبات'],
  [/\/progress|\/reports/i, 'صفحة التقدم والتقارير'],
  [/\/conversations|\/messages/i, 'صفحة المحادثات'],
  [/\/profile/i, 'الملف الشخصي'],
  [/\/accessibility/i, 'إعدادات التكيف'],
  [/\/notifications/i, 'صفحة الإشعارات'],
]

const ROLE_SUGGESTIONS = {
  parent: [
    'لخّص لي ما يمكنني متابعته اليوم',
    'كيف أساعد طفلي في الدرس الحالي؟',
    'اقترح نشاطاً منزلياً قصيراً',
  ],
  teacher: [
    'اقترح طريقة أبسط لشرح الدرس',
    'أنشئ أسئلة قصيرة على هذا الموضوع',
    'ساعدني في صياغة تغذية راجعة تعليمية',
  ],
  specialist: [
    'ساعدني في تجهيز أهداف الجلسة القادمة',
    'لخّص التقدم الظاهر في الصفحة',
    'اقترح نشاطاً تعليمياً مناسباً للمتابعة',
  ],
  admin: [
    'اشرح لي ما تعرضه هذه الصفحة',
    'ما الخطوة التالية لتنفيذ هذه المهمة؟',
    'لخّص العناصر المهمة الظاهرة هنا',
  ],
  institution: [
    'لخّص المؤشرات التعليمية الظاهرة',
    'اشرح لي ما تعرضه هذه الصفحة',
    'ما الذي يحتاج متابعة هنا؟',
  ],
  ministry: [
    'لخّص المؤشرات التعليمية الظاهرة',
    'اشرح لي هذه البيانات باختصار',
    'ما العناصر التي تحتاج مراجعة؟',
  ],
}

export function assistantSuggestions(user, pathname = '') {
  const role = user?.role || 'user'
  const suggestions = [...(ROLE_SUGGESTIONS[role] || [
    'اشرح لي ما تعرضه هذه الصفحة',
    'بسّط لي هذا الموضوع',
    'اقترح نشاطاً تعليمياً قصيراً',
  ])]

  if (/\/lessons/i.test(pathname)) suggestions.unshift('اشرح الدرس الحالي ببساطة')
  if (/\/assignments|\/homework/i.test(pathname)) suggestions.unshift('ساعدني في فهم الواجب الحالي')
  if (/\/progress|\/reports/i.test(pathname)) suggestions.unshift('لخّص التقدم الظاهر في الصفحة')

  return [...new Set(suggestions)].slice(0, 4)
}

export function buildAssistantContext({ user, location }) {
  const pathname = location?.pathname || '/'
  const pageLabel = PAGE_LABELS.find(([pattern]) => pattern.test(pathname))?.[1] || 'صفحة داخل EduBridge'
  const role = user?.role || 'user'

  return [
    `الدور: ${role}`,
    `الصفحة الحالية: ${pageLabel}`,
    `المسار: ${pathname}`,
    'لا توجد في هذا السياق بيانات طالب أو واجب أو موعد إلا إذا كانت مذكورة صراحة في رسالة المستخدم.',
  ].join('\n')
}
