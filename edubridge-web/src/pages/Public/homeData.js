import {
  Accessibility,
  BarChart3,
  BookOpen,
  ClipboardCheck,
  Heart,
  MessageCircle,
  ShieldCheck,
  Users,
} from 'lucide-react'

export const AUDIENCES = [
  {
    Icon: Users,
    title: 'ولي الأمر',
    text: 'تابع تقدّم طفلك وادعمه في كل خطوة',
    points: ['مراقبة التقدّم والتقارير', 'أنشطة مخصصة للمنزل', 'تواصل مباشر مع المعلمين'],
    tone: 'tone-parent',
  },
  {
    Icon: BookOpen,
    title: 'المعلم',
    text: 'أدوات ذكية لتعليم أكثر فاعلية',
    points: ['خطط دروس مرنة', 'محتوى تفاعلي متنوع', 'متابعة أداء الطلاب'],
    tone: 'tone-teacher',
  },
  {
    Icon: Heart,
    title: 'المختص',
    text: 'دعم احترافي يصنع فرقاً حقيقياً',
    points: ['أدوات تقييم متقدمة', 'برامج تدخل مخصصة', 'تعاون مع فريق العمل'],
    tone: 'tone-specialist',
  },
]

export const SERVICES = [
  {
    Icon: BookOpen,
    title: 'التعلّم والدروس',
    text: 'دروس وأنشطة تعليمية يمكن تكييفها مع مستوى الطفل واحتياجاته، مع محتوى متنوع يدعم رحلة التعلّم اليومية.',
    audience: 'للطفل والمعلم',
  },
  {
    Icon: BarChart3,
    title: 'متابعة وتقييم التقدّم',
    text: 'متابعة واضحة للإنجاز والتقدّم تساعد الأسرة والمعلم على فهم ما تحقق وتحديد الخطوة التعليمية التالية.',
    audience: 'للأسرة وفريق التعليم',
  },
  {
    Icon: MessageCircle,
    title: 'التواصل والتعاون',
    text: 'مساحة منظمة تجمع ولي الأمر والمعلم والمختص لتبادل المتابعة والملاحظات حول احتياجات الطفل وتقدّمه.',
    audience: 'للفريق الداعم',
  },
  {
    Icon: ClipboardCheck,
    title: 'الدعم التعليمي المتخصص',
    text: 'إدارة طلبات الدعم والتقييم والمتابعة مع المختصين ضمن رحلة مترابطة تساعد على بناء تدخلات تعليمية أوضح.',
    audience: 'للأسرة والمختص',
  },
]

export const FEATURES = [
  { Icon: Accessibility, title: 'وصول أسهل', text: 'واجهة تراعي اختلاف القدرات وتدعم تجربة استخدام أكثر شمولاً' },
  { Icon: ShieldCheck, title: 'خصوصية وصلاحيات', text: 'وصول منظم للمعلومات بحسب دور المستخدم وصلاحياته' },
]

export const GETTING_STARTED = [
  { Icon: Users, title: 'أنشئ حسابك', text: 'اختر نوع حسابك: ولي أمر أو معلم أو مختص، وأكمل بيانات التسجيل.' },
  { Icon: BookOpen, title: 'استكشف أدواتك', text: 'بعد تسجيل الدخول، تعرّف على الدروس وأدوات المتابعة المتاحة لدورك.' },
  { Icon: MessageCircle, title: 'ابدأ وتابع', text: 'استخدم أنشطة التعلّم والتواصل مع الفريق، وتابع التقدّم من لوحة حسابك.' },
]
