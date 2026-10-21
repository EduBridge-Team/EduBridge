// Voice command routing extracted from voice_command_service.dart.
part of 'voice_command_service.dart';

extension _VoiceCommandRoutingExtension on VoiceCommandService {
  // ═══════════════════════════════════════════════════════════
  //  تحميل الأطفال (مع cache)
  // ═══════════════════════════════════════════════════════════
  Future<void> _ensureChildrenLoaded() async {
    final userId = await ApiService.getUserId();
    if (userId != _childrenCacheUserId) clearChildrenCache();
    if (userId == null) return;
    if (_childrenCache.isNotEmpty &&
        _childrenCacheTime != null &&
        DateTime.now().difference(_childrenCacheTime!) < VoiceCommandService._cacheDuration) {
      return;
    }
    try {
      final res = await ApiService.authGet('/children');
      if (res.statusCode == 200 && await ApiService.getUserId() == userId) {
        final data = jsonDecode(res.body);
        _childrenCache = (data['children'] as List? ?? [])
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
        _childrenCacheTime = DateTime.now();
        _childrenCacheUserId = userId;
      }
    } catch (_) {}
  }

  // ═══════════════════════════════════════════════════════════
  //  مطابقة اسم الطفل
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic>? _findChild(String rawText) {
    return findVoiceChild(rawText, _childrenCache);
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

  String _gameDisplayName(String gameId) {
    final game = GameScreenFactory.info(gameId);
    return game == null ? _strings.voiceCommandGamesLabel : GameCatalogDisplay.title(game, _strings);
  }

  // ═══════════════════════════════════════════════════════════
  //  أدوات مساعدة
  // ═══════════════════════════════════════════════════════════
  String _normalize(String input) => normalizeVoiceText(input);

  bool _matches(String text, List<String> keywords) => matchesVoiceCommand(text, keywords);

  Future<void> _reply(String message) async {
    lastReply.value = message;
    await TtsService.instance.speakLine(message, languageCode: _locale.value.languageCode);
  }

}
