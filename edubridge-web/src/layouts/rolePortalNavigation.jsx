import {
  Accessibility,
  BarChart3,
  BookOpen,
  Home,
  Landmark,
  LifeBuoy,
  MessageCircle,
  Search,
  Settings,
  ShieldCheck,
  Stethoscope,
  Users,
} from 'lucide-react'

export function activeSection(pathname, role, homePath) {
  if (pathname === homePath) return 'home'
  if (/\/children\/[^/]+\/progress$/.test(pathname)) return role === 'parent' ? 'progress' : 'children'
  if (/\/children\/[^/]+\/lessons$/.test(pathname)) return role === 'parent' ? 'lessons' : 'children'
  if (pathname === '/lessons') return 'lessons'
  if (pathname.startsWith('/children')) return 'children'
  if (pathname === '/conversations') return 'conversations'
  if (pathname === '/search') return 'search'
  if (pathname === '/consultations') return 'consultations'
  if (pathname === '/homeworks') return 'homeworks'
  if (pathname === '/weekly-reports') return 'weekly-reports'
  if (pathname === '/learning-support') return 'learning-support'
  if (pathname === '/care-team') return 'care-team'
  if (pathname === '/case-discussions') return 'case-discussions'
  if (pathname === '/specialist-workflow') return 'specialist-workflow'
  if (pathname === '/parent-lessons') return 'parent-lessons'
  if (pathname === '/aac') return 'aac'
  if (pathname === '/admin/verifications') return 'verifications'
  if (pathname === '/ministry' && role === 'admin') return 'curriculum'
  if (pathname === '/support') return 'support'
  if (pathname === '/verify') return 'verify'
  if (pathname.startsWith('/accessibility')) return 'settings'
  if (pathname === '/profile') return 'profile'
  return ''
}

export function createRoleNavItems({
  childrenList,
  conversationCount,
  goToProgress,
  homePath,
  navigate,
  role,
}) {
  const item = (key, label, icon, to, extra = {}) => ({
    key,
    label,
    icon,
    onClick: () => navigate(to),
    ...extra,
  })

  const home = item('home', 'الرئيسية', <Home size={21} />, homePath)
  const conversations = item(
    'conversations',
    'المحادثات',
    <MessageCircle size={21} />,
    '/conversations',
    { badge: conversationCount },
  )

  if (role === 'parent') {
    return [
      home,
      item('children', 'أطفالي', <Users size={21} />, '/children'),
      item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
      item('parent-lessons', 'دروس لولي الأمر', <BookOpen size={21} />, '/parent-lessons'),
      item('aac', 'تواصل بالصور', <MessageCircle size={21} />, '/aac'),
      {
        key: 'progress',
        label: 'التقدم',
        icon: <BarChart3 size={21} />,
        onClick: goToProgress,
        disabled: !childrenList[0],
      },
      item('homeworks', 'الواجبات', <BookOpen size={21} />, '/homeworks'),
      item('weekly-reports', 'التقارير الأسبوعية', <BarChart3 size={21} />, '/weekly-reports'),
      item('learning-support', 'الدعم التعليمي', <BookOpen size={21} />, '/learning-support'),
      item('care-team', 'فريق الدعم التعليمي', <Users size={21} />, '/care-team'),
      conversations,
      item('settings', 'الإعدادات', <Settings size={21} />, '/accessibility'),
    ]
  }

  if (role === 'teacher') {
    return [
      home,
      item('children', 'الطلاب', <Users size={21} />, '/children'),
      item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
      item('aac', 'تواصل بالصور', <MessageCircle size={21} />, '/aac'),
      item('search', 'البحث عن طالب', <Search size={21} />, '/search'),
      item('homeworks', 'الواجبات', <BookOpen size={21} />, '/homeworks'),
      item('weekly-reports', 'التقارير الأسبوعية', <BarChart3 size={21} />, '/weekly-reports'),
      item('case-discussions', 'دراسات الحالة', <Stethoscope size={21} />, '/case-discussions'),
      item('specialist-workflow', 'اقتراح المختصين', <Users size={21} />, '/specialist-workflow'),
      conversations,
      item('settings', 'إعدادات الوصول', <Accessibility size={21} />, '/accessibility'),
    ]
  }

  if (role === 'specialist') {
    return [
      home,
      item('children', 'الأطفال', <Users size={21} />, '/children'),
      item('aac', 'تواصل بالصور', <MessageCircle size={21} />, '/aac'),
      item('specialist-workflow', 'اقتراحات المتابعة', <Users size={21} />, '/specialist-workflow'),
      item('learning-support', 'اجتماعات الدعم', <BookOpen size={21} />, '/learning-support'),
      item('weekly-reports', 'التقارير الأسبوعية', <BarChart3 size={21} />, '/weekly-reports'),
      item('case-discussions', 'دراسات الحالة', <MessageCircle size={21} />, '/case-discussions'),
      item('care-team', 'فريق الدعم التعليمي', <Users size={21} />, '/care-team'),
      item('search', 'البحث', <Search size={21} />, '/search'),
      item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
      conversations,
      item('settings', 'إعدادات الوصول', <Accessibility size={21} />, '/accessibility'),
    ]
  }

  if (role === 'institution') {
    return [
      home,
      item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
      item('search', 'البحث عن طالب', <Search size={21} />, '/search'),
      conversations,
      item('support', 'الدعم', <LifeBuoy size={21} />, '/support'),
    ]
  }

  if (role === 'ministry') {
    return [
      home,
      item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
      item('search', 'البحث', <Search size={21} />, '/search'),
      conversations,
      item('support', 'الدعم', <LifeBuoy size={21} />, '/support'),
    ]
  }

  if (role === 'admin') {
    return [
      home,
      item('verifications', 'مراجعة التوثيق', <ShieldCheck size={21} />, '/admin/verifications'),
      item('curriculum', 'مراجعة المناهج', <Landmark size={21} />, '/ministry'),
      item('children', 'ملفات الأطفال', <Users size={21} />, '/children'),
      item('case-discussions', 'دراسات الحالة', <MessageCircle size={21} />, '/case-discussions'),
      item('specialist-workflow', 'متابعة المختصين', <Users size={21} />, '/specialist-workflow'),
      item('learning-support', 'اجتماعات الدعم', <BookOpen size={21} />, '/learning-support'),
      item('lessons', 'الدروس', <BookOpen size={21} />, '/lessons'),
      item('search', 'البحث', <Search size={21} />, '/search'),
      conversations,
      item('support', 'الدعم الفني', <LifeBuoy size={21} />, '/support'),
    ]
  }

  return [home, conversations]
}
