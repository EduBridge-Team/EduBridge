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

const ROLE_NAVIGATION = {
  parent: [
    ['الدروس', '/lessons'],
    ['الواجبات', '/homeworks'],
    ['التقدم الأسبوعي', '/weekly-reports'],
    ['المحادثات', '/conversations'],
    ['الإشعارات', '/notifications'],
  ],
  teacher: [
    ['الدروس', '/lessons'],
    ['الواجبات', '/homeworks'],
    ['التقدم الأسبوعي', '/weekly-reports'],
    ['المحادثات', '/conversations'],
    ['الإشعارات', '/notifications'],
  ],
  specialist: [
    ['الدروس', '/lessons'],
    ['الواجبات', '/homeworks'],
    ['التقدم الأسبوعي', '/weekly-reports'],
    ['المحادثات', '/conversations'],
    ['الإشعارات', '/notifications'],
  ],
  admin: [
    ['الدروس', '/lessons'],
    ['الواجبات', '/homeworks'],
    ['المحادثات', '/conversations'],
    ['الإشعارات', '/notifications'],
  ],
  institution: [
    ['الدروس', '/lessons'],
    ['المحادثات', '/conversations'],
    ['الإشعارات', '/notifications'],
  ],
  ministry: [
    ['الدروس', '/lessons'],
    ['المحادثات', '/conversations'],
    ['الإشعارات', '/notifications'],
  ],
}

const SENSITIVE_LINE = /(رقم\s*(?:الهوية|الهويه|الوطني)|هوية|هويه|جواز|هاتف|جوال|موبايل|بريد\s*إلكتروني|email|address|العنوان|كلمة\s*المرور|password|مستند|وثيقة|شهادة\s*ميلاد|تقرير\s*طبي)/i
const EMAIL = /[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}/giu
const LONG_NUMBER = /(?<!\d)(?:\d[\s-]?){7,15}(?!\d)/gu

function visiblePageFacts() {
  if (typeof document === 'undefined') return ''

  const root = document.querySelector('main, [role="main"], .pp-content, .dashboard-content')
  if (!root) return ''

  const lines = (root.innerText || '')
    .split(/\n+/)
    .map(line => line.trim())
    .filter(Boolean)
    .filter(line => !SENSITIVE_LINE.test(line))
    .map(line => line.replace(EMAIL, '[بريد محذوف]').replace(LONG_NUMBER, '[رقم محذوف]'))
    .filter(line => line.length <= 220)

  const unique = [...new Set(lines)]
  const facts = []
  let total = 0

  for (const line of unique) {
    if (facts.length >= 18 || total + line.length > 850) break
    facts.push(line)
    total += line.length
  }

  return facts.join('\n')
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

export function assistantNavigationActions(user, pathname = '') {
  const role = user?.role || 'user'
  const items = ROLE_NAVIGATION[role] || [
    ['الدروس', '/lessons'],
    ['الإشعارات', '/notifications'],
  ]

  return items
    .filter(([, path]) => path !== pathname)
    .slice(0, 4)
    .map(([label, path]) => ({ label, path }))
}

export function buildAssistantContext({ user, location }) {
  const pathname = location?.pathname || '/'
  const pageLabel = PAGE_LABELS.find(([pattern]) => pattern.test(pathname))?.[1] || 'صفحة داخل EduBridge'
  const role = user?.role || 'user'
  const pageFacts = visiblePageFacts()

  return [
    `الدور: ${role}`,
    `الصفحة الحالية: ${pageLabel}`,
    `المسار: ${pathname}`,
    pageFacts ? `بيانات مرئية آمنة من الصفحة:\n${pageFacts}` : null,
    pageFacts
      ? 'استخدم فقط البيانات المذكورة أعلاه عند الحديث عن طالب أو واجب أو موعد أو تقدم.'
      : 'لا توجد بيانات فعلية من الصفحة في هذا السياق؛ لا تخمّن طالباً أو واجباً أو موعداً أو تقدماً.',
  ].filter(Boolean).join('\n')
}
