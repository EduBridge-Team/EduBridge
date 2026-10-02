import {
  Accessibility,
  BookOpen,
  Building2,
  IdCard,
  Info,
  Landmark,
  LifeBuoy,
  MessageCircle,
  Search,
  Settings,
  ShieldCheck,
  Stethoscope,
  Users,
} from 'lucide-react'

export function buildTopBarStripLinks(user) {
  const is = (...roles) => user && roles.includes(user.role)

  return [
    { to: '/admin', label: 'إدارة النظام', Icon: Settings, show: is('admin') },
    { to: '/admin/verifications', label: 'مراجعة التوثيق', Icon: ShieldCheck, show: is('admin') },
    { to: '/ministry', label: 'مراجعة المناهج', Icon: Landmark, show: is('ministry') },
    { to: '/institution', label: 'لوحة المؤسسة', Icon: Building2, show: is('institution') },
    { to: '/children', label: 'ملفات الأطفال', Icon: Users, show: is('parent', 'teacher', 'specialist', 'admin') },
    { to: '/lessons', label: 'الدروس', Icon: BookOpen, show: Boolean(user) },
    { to: '/accessibility', label: 'إعدادات التكيف', Icon: Accessibility, show: is('specialist') },
    { to: '/search', label: 'البحث برقم الهوية', Icon: Search, show: is('teacher', 'specialist', 'admin', 'ministry', 'institution') },
    { to: '/consultations', label: 'دراسة الحالة', Icon: Stethoscope, show: is('parent', 'teacher', 'specialist') },
    { to: '/verify', label: 'توثيق الحساب', Icon: IdCard, show: Boolean(user) },
    { to: '/support', label: 'الدعم', Icon: LifeBuoy, show: Boolean(user) },
    { to: '/conversations', label: 'المحادثات', Icon: MessageCircle, show: Boolean(user) },
    { to: '/about', label: 'من نحن', Icon: Info, show: Boolean(user) },
  ].filter((link) => link.show)
}
