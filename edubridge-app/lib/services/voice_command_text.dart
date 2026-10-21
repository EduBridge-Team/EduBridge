// Shared, testable Arabic matching rules for voice navigation.
String normalizeVoiceText(String input) => input.toLowerCase()
    .replaceAll(RegExp(r'[\u064B-\u065F\u0670\u0640]'), '')
    .replaceAll(RegExp('[أإآٱ]'), 'ا')
    .replaceAll('ئ', 'ي').replaceAll('ؤ', 'و')
    .replaceAll('ى', 'ي').replaceAll('ة', 'ه')
    .replaceAll(RegExp(r'[،.,!؟?:;\-]'), ' ')
    .replaceAll(RegExp(r'\s+'), ' ').trim();

bool matchesVoiceText(String text, List<String> phrases) {
  final normalized = ' ${normalizeVoiceText(text)} ';
  return phrases.any((phrase) => normalized.contains(' ${normalizeVoiceText(phrase)} '));
}

Map<String, dynamic>? findVoiceChild(String text, List<Map<String, dynamic>> children) {
  final exact = children.where((child) {
    final name = normalizeVoiceText((child['name'] ?? '').toString());
    return name.isNotEmpty && matchesVoiceText(text, [name]);
  }).toList();
  if (exact.length == 1) return exact.single;
  if (exact.length > 1) return null;
  final partial = children.where((child) => normalizeVoiceText((child['name'] ?? '').toString())
    .split(' ').any((word) => word.length >= 3 && matchesVoiceText(text, [word]))).toList();
  return partial.length == 1 ? partial.single : null;
}

/// Explicit command aliases only; child names still use matchesVoiceText.
const voiceCommandEnglishAliases = <String, List<String>> {
  "اوقف القراءه": ["stop reading", "turn off reading", "disable reading"],
  "اقرا": ["read", "start reading", "turn on reading", "reading mode"],
  "اوقف": ["stop", "silence", "quiet"],
  "رييسيه": ["home", "main page"],
  "ارجع": ["go back", "back"],
  "ليلي": ["dark mode", "dark theme"],
  "فاتح": ["light mode", "light theme"],
  "الملف الشخصي": ["profile", "my account", "account settings"],
  "كلمه المرور": ["password", "change password"],
  "توثيق": ["verify identity", "identity verification"],
  "دروس ولي الامر": ["parent lessons", "parent advice"],
  "دروس عامه": ["lesson library", "public lessons"],
  "طلبات الدعم": ["support requests", "learning support requests"],
  "جلسات": ["sessions", "support meetings"],
  "طلب دعم": ["request support", "learning support"],
  "دراسه": ["case study", "case studies", "case discussion"],
  "اطفال": ["children", "students", "child list"],
  "طفل": ["child"],
  "دروس": ["lessons", "lesson"],
  "واجب": ["homework", "assignments"],
  "تقدم": ["progress", "achievements", "rewards"],
  "تقرير": ["report", "reports", "weekly progress"],
  "فريق": ["care team", "team"],
  "العاب": ["games", "game catalog", "play"],
  "اشعارات": ["notifications", "alerts"],
  "محادثات": ["chats", "messages", "contact"],
  "مساعد": ["assistant", "noor"],
  "احتياجات": ["children needs"],
  "تكييف": ["adaptation settings", "accessibility settings"],
  "اضف طفل": ["add child", "new child"],
  "مساعده": ["help", "commands", "help me"],
  "اصوات": ["sounds", "audio matching", "animal sounds"],
  "مطابقه": ["matching", "pairs"],
  "اشكال": ["shapes", "square", "circle", "triangle"],
  "الوان": ["colors", "colours"],
  "رموز": ["symbols", "color blindness", "colour blindness"],
  "ارقام": ["numbers", "counting"],
  "حساب": ["math", "arithmetic"],
  "كلمات بصريه": ["visual words", "sight words"],
  "بناء الكلمه": ["word builder", "letters"],
  "ترتيب": ["sequence", "sequencing"],
  "قصه": ["story", "stories"],
  "اشاره": ["sign language", "signs"],
  "حركه سريعه": ["quick action"],
  "ايقاع": ["rhythm", "tapping"],
};

bool matchesVoiceCommand(String text, List<String> phrases) {
  return matchesVoiceText(text, phrases) || phrases.any((phrase) {
    final aliases = voiceCommandEnglishAliases[normalizeVoiceText(phrase)];
    return aliases != null && matchesVoiceText(text, aliases);
  });
}
