import { isPortalPathForRole } from '../../portalRoutes.js'
import { dashboardFor } from '../../roleRoutes.js'

export function normalizeVoiceText(input = '') {
  return String(input).toLowerCase().replace(/[\u064B-\u065F\u0670\u0640]/g, '')
    .replace(/[أإآٱ]/g, 'ا').replace(/ئ/g, 'ي').replace(/ؤ/g, 'و').replace(/ى/g, 'ي')
    .replace(/ة/g, 'ه').replace(/[^\p{L}\p{N}\s]/gu, ' ').replace(/\s+/g, ' ').trim()
}

const commands = [
  [['الرئيسية', 'هوم'], '/dashboard'],
  [['إضافة طفل', 'أضف طفل', 'ضيف طفل', 'طفل جديد'], '/children/new'],
  [['الأطفال', 'أطفال', 'الأولاد'], '/children'],
  [['دروس ولي الأمر', 'دروس لولي الأمر', 'دروس للأهل', 'نصائح'], '/parent-lessons'],
  [['الدروس', 'دروس', 'مكتبة الدروس', 'دروس عامة'], '/lessons'],
  [['الواجبات', 'واجبات', 'واجب'], '/homeworks'],
  [['التقارير', 'تقرير', 'التقدم الأسبوعي', 'تقدم أسبوعي'], '/weekly-reports'],
  [['التقدم', 'تقدم الطفل'], '/children'],
  [['اجتماعات الدعم', 'الدعم التعليمي', 'متابعة تعليمية', 'جلسات', 'طلبات الدعم'], '/learning-support'],
  [['فريق الدعم التعليمي', 'فريق الطفل', 'الفريق', 'فريق'], '/care-team'],
  [['دراسات الحالة', 'دراسة حالة', 'دراسة الحالة'], '/case-discussions'],
  [['اقتراحات المختصين', 'متابعة المختصين'], '/specialist-workflow'],
  [['تواصل بالصور', 'التواصل', 'aac'], '/conversations?mode=aac'],
  [['المحادثات', 'محادثات', 'رسائل', 'شات'], '/conversations'],
  [['الإشعارات', 'إشعارات', 'تنبيهات'], '/notifications'],
  [['الملف الشخصي', 'ملفي', 'حسابي'], '/profile'],
  [['توثيق الهوية', 'توثيق', 'هويتي'], '/verify'],
  [['الإعدادات', 'إعدادات التكيف', 'إعدادات التكييف', 'تكيف', 'تكييف', 'احتياجات'], '/accessibility'],
  [['الدعم', 'مساعدة', 'ساعدني'], '/support'],
  [['ارجع', 'رجوع', 'للخلف'], 'back'],
  [['أوقف', 'اسكت', 'صمت'], 'stop'],
  [['الوضع الليلي', 'ليلي', 'داكن'], 'dark'],
  [['الوضع الفاتح', 'فاتح', 'نهاري'], 'light'],
]

export function resolveVoiceCommand(raw, role) {
  const text = ` ${normalizeVoiceText(raw)} `
  const candidates = commands.flatMap(([phrases, target]) => phrases.map(phrase => ({ phrase: normalizeVoiceText(phrase), target })))
    .sort((a, b) => b.phrase.length - a.phrase.length)
  const match = candidates.find(({ phrase }) => text.includes(` ${phrase} `))
  if (!match) return { type: 'unknown' }
  const path = match.target === '/dashboard' ? dashboardFor(role) : match.target
  if (!path.startsWith('/')) return { type: path }
  return isPortalPathForRole(path.split('?')[0], role)
    ? { type: 'navigate', path } : { type: 'denied' }
}
