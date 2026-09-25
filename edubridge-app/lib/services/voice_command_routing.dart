// Voice command routing extracted from voice_command_service.dart.
part of 'voice_command_service.dart';

extension _VoiceCommandRoutingExtension on VoiceCommandService {
  // ═══════════════════════════════════════════════════════════
  //  تحميل الأطفال (مع cache)
  // ═══════════════════════════════════════════════════════════
  Future<void> _ensureChildrenLoaded() async {
    if (_childrenCache.isNotEmpty &&
        _childrenCacheTime != null &&
        DateTime.now().difference(_childrenCacheTime!) < VoiceCommandService._cacheDuration) {
      return;
    }
    try {
      final res = await ApiService.authGet('/children');
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        _childrenCache = (data['children'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _childrenCacheTime = DateTime.now();
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════
  //  مطابقة اسم الطفل
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic>? _findChild(String rawText) {
    if (_childrenCache.isEmpty) return null;

    final text = _normalize(rawText);

    // 1. مطابقة كامل الاسم
    for (final child in _childrenCache) {
      final name = _normalize((child['name'] ?? '').toString());
      if (name.isEmpty) continue;
      if (text.contains(name)) return child;
    }

    // 2. مطابقة الجزء الأول من الاسم (مثلاً: "محمد" يطابق "محمد أحمد")
    for (final child in _childrenCache) {
      final name = _normalize((child['name'] ?? '').toString());
      if (name.isEmpty) continue;
      final firstWord = name.split(' ').first;
      if (firstWord.length >= 2 && text.contains(firstWord)) {
        return child;
      }
    }

    // 3. مطابقة أي كلمة في الاسم (طولها 3+)
    for (final child in _childrenCache) {
      final name = _normalize((child['name'] ?? '').toString());
      if (name.isEmpty) continue;
      for (final word in name.split(' ')) {
        if (word.length >= 3 && text.contains(word)) {
          return child;
        }
      }
    }

    return null;
  }

  // ═══════════════════════════════════════════════════════════
  //  تنفيذ الأمر
  // ═══════════════════════════════════════════════════════════
  String? _detectGame(String text) {
    if (_matches(text, ['اصوات', 'الاصوات', 'سمعيه', 'حيوانات صوتيه'])) {
      return 'audio';
    }
    if (_matches(text, ['مطابقه', 'المطابقه', 'اذواج', 'ازواج'])) {
      return 'matching';
    }
    if (_matches(text, ['اشكال', 'الاشكال', 'مربع', 'دايره', 'مثلث'])) {
      return 'shapes';
    }
    if (_matches(text, ['الوان', 'الالوان', 'لون'])) return 'colors';
    if (_matches(text, ['رموز', 'الرموز', 'عمي الالوان', 'انماط'])) {
      return 'symbols';
    }
    if (_matches(text, ['ارقام', 'الارقام', 'العد', 'رقم'])) {
      return 'numbers';
    }
    if (_matches(text, ['حساب', 'الحساب', 'رياضيات', 'سباق'])) {
      return 'math';
    }
    if (_matches(text, ['كلمات بصريه', 'الكلمات البصريه', 'كلمات'])) {
      return 'visual_words';
    }
    if (_matches(text, ['بناء الكلمه', 'بناء كلمه', 'حروف'])) {
      return 'word_builder';
    }
    if (_matches(text, ['ترتيب', 'الترتيب', 'تسلسل'])) return 'sequence';
    if (_matches(text, ['قصه', 'القصه', 'قصص'])) return 'story';
    if (_matches(text, ['اشاره', 'الاشاره', 'الصم'])) return 'sign';
    if (_matches(text, ['حركه سريعه', 'الحركه السريعه', 'نشاط'])) {
      return 'quick';
    }
    if (_matches(text, ['ايقاع', 'الايقاع', 'نقر'])) return 'rhythm';
    return null;
  }

  Widget? _gameWidgetFor(String gameId) {
    const name = 'بطل';
    const age = 8;
    switch (gameId) {
      case 'audio':
        return const AudioMatchingGame(childName: name);
      case 'matching':
        return const MatchingGame(childName: name);
      case 'shapes':
        return const ShapesGame(childName: name, age: age);
      case 'colors':
        return const ColorsGame(childName: name);
      case 'symbols':
        return const SymbolsGame(childName: name);
      case 'numbers':
        return const NumbersGame(childName: name);
      case 'math':
        return const MathRaceGame(childName: name, age: age);
      case 'visual_words':
        return const VisualWordsGame(childName: name, age: age);
      case 'word_builder':
        return const WordBuilderGame(childName: name, age: age);
      case 'sequence':
        return const SequenceGame(childName: name);
      case 'story':
        return const StorySequencerGame(childName: name, age: age);
      case 'sign':
        return const SignLanguageGame(childName: name);
      case 'quick':
        return const QuickActionGame(childName: name);
      case 'rhythm':
        return const RhythmGame(childName: name);
      default:
        return null;
    }
  }

  String _gameDisplayName(String gameId) {
    const names = {
      'audio': 'لعبة الأصوات',
      'matching': 'لعبة المطابقة',
      'shapes': 'لعبة الأشكال',
      'colors': 'لعبة الألوان',
      'symbols': 'لعبة الرموز',
      'numbers': 'لعبة الأرقام',
      'math': 'سباق الحساب',
      'visual_words': 'الكلمات البصرية',
      'word_builder': 'بناء الكلمة',
      'sequence': 'لعبة الترتيب',
      'story': 'رتّب القصة',
      'sign': 'لغة الإشارة',
      'quick': 'الحركة السريعة',
      'rhythm': 'لعبة الإيقاع',
    };
    return names[gameId] ?? 'اللعبة';
  }

  // ═══════════════════════════════════════════════════════════
  //  أدوات مساعدة
  // ═══════════════════════════════════════════════════════════
  String _normalize(String input) {
    var t = input.trim();
    t = t.replaceAll(RegExp(r'[\u064B-\u0652]'), '');
    t = t.replaceAll('\u0640', '');
    t = t.replaceAll(RegExp('[أإآٱ]'), 'ا');
    t = t.replaceAll('ئ', 'ي');
    t = t.replaceAll('ؤ', 'و');
    t = t.replaceAll('ى', 'ي');
    t = t.replaceAll('ة', 'ه');
    t = t.replaceAll(RegExp(r'[،.,!؟?]'), ' ');
    t = t.replaceAll(RegExp(r'\s+'), ' ').trim();
    return t;
  }

  bool _matches(String text, List<String> keywords) {
    for (final k in keywords) {
      if (text.contains(_normalize(k))) return true;
    }
    return false;
  }

  Future<void> _reply(String message) async {
    lastReply.value = message;
    await TtsService.instance.speakLine(message);
  }

  Future<void> _speak(String message) async {
    await TtsService.instance.speakLine(message);
  }
}
