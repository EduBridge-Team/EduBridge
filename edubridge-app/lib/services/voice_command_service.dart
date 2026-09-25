// خدمة الأوامر الصوتية — تدعم فتح دروس/واجبات/تقدم طفل معيّن بالاسم
import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_recognition_result.dart'
    show SpeechRecognitionResult;
import 'package:speech_to_text/speech_to_text.dart' as stt;

// ─── الألعاب ───
import '../games/audio_matching_game.dart';
import '../games/colors_game.dart';
import '../games/matching_game.dart';
import '../games/math_race_game.dart';
import '../games/numbers_game.dart';
import '../games/quick_action_game.dart';
import '../games/rhythm_game.dart';
import '../games/sequence_game.dart';
import '../games/shapes_game.dart';
import '../games/sign_language_game.dart';
import '../games/story_sequencer_game.dart';
import '../games/symbols_game.dart';
import '../games/visual_words_game.dart';
import '../games/word_builder_game.dart';

// ─── الشاشات ───
import '../screens/aac_communication_screen.dart';
import '../screens/add_child/add_child_screen.dart';
import '../screens/assistant_screen.dart';
import '../screens/care_team_screen.dart';
import '../screens/case_discussion/case_discussion_screen.dart';
import '../screens/change_password_screen.dart';
import '../screens/chats_screen.dart';
import '../screens/child_accessibility/child_accessibility_settings_screen.dart';
import '../screens/child_homework/child_homework_screen.dart';
import '../screens/child_lessons/child_lessons_screen.dart';
import '../screens/child_progress_screen.dart';
import '../screens/children_accessibility_overview_screen.dart';
import '../screens/children_screen.dart';
import '../screens/create_learning_support_request_screen.dart';
import '../screens/educational_games_screen.dart';
import '../screens/learning_support_requests/learning_support_requests_screen.dart';
import '../screens/lessons_screen.dart';
import '../screens/notifications_screen.dart';
import '../screens/parent_lessons_screen.dart';
import '../screens/learning_support_meetings_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/verify_identity/verify_identity_screen.dart';
import '../screens/weekly_report_screen.dart';

import '../theme.dart';
import '../utils/navigation.dart';
import 'api_service.dart';
import 'tts_service.dart';

class VoiceCommandService {
  VoiceCommandService._();
  static final VoiceCommandService instance = VoiceCommandService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _available = false;

  final ValueNotifier<bool> isListening = ValueNotifier<bool>(false);
  final ValueNotifier<String> lastHeard = ValueNotifier<String>('');
  final ValueNotifier<String> lastReply = ValueNotifier<String>('');

  // ═══════════════════════════════════════════════════════════
  //  Cache الأطفال (يُحدَّث كل 5 دقائق)
  // ═══════════════════════════════════════════════════════════
  List<Map<String, dynamic>> _childrenCache = [];
  DateTime? _childrenCacheTime;
  static const _cacheDuration = Duration(minutes: 5);

  bool get isAvailable => _available;

  Future<bool> initialize() async {
    if (_initialized) return _available;
    _initialized = true;
    try {
      _available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      return _available;
    } catch (_) {
      _available = false;
      return false;
    }
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      isListening.value = false;
    }
  }

  void _onError(dynamic error) => isListening.value = false;

  Future<void> startListening() async {
    if (!await initialize()) {
      await _speak('الميكروفون غير متاح على هذا الجهاز');
      return;
    }
    if (isListening.value) {
      await stopListening();
      return;
    }
    await TtsService.instance.stop();
    lastHeard.value = '';
    lastReply.value = '';
    isListening.value = true;
    await _speech.listen(
      onResult: _onResult,
      listenOptions: stt.SpeechListenOptions(
        localeId: 'ar-SA',
        listenFor: const Duration(seconds: 10),
        pauseFor: const Duration(seconds: 4),
        partialResults: true,
      ),
    );
  }

  Future<void> stopListening() async {
    if (!isListening.value) return;
    isListening.value = false;
    try {
      await _speech.stop();
    } catch (_) {}
  }

  Future<void> cancel() async {
    isListening.value = false;
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  void _onResult(SpeechRecognitionResult result) {
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;
    lastHeard.value = text;
    if (result.finalResult) _executeCommand(text);
  }

  // ═══════════════════════════════════════════════════════════
  //  تحميل الأطفال (مع cache)
  // ═══════════════════════════════════════════════════════════
  Future<void> _ensureChildrenLoaded() async {
    if (_childrenCache.isNotEmpty &&
        _childrenCacheTime != null &&
        DateTime.now().difference(_childrenCacheTime!) < _cacheDuration) {
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
  Future<void> _executeCommand(String rawText) async {
    final text = _normalize(rawText);
    final nav = appNavigatorKey.currentState;

    // ═══ 1. القراءة باللمس ═══
    if (_matches(text, [
      'اقرا', 'اقراء', 'قراءه', 'قرايه',
      'شغل القراءه', 'فعل القراءه', 'ابدا القراءه', 'وضع القراءه',
    ])) {
      if (!TtsService.instance.tapToRead.value) {
        await TtsService.instance.toggleTapToRead();
      }
      await _reply('وضع القراءة باللمس مُفعّل');
      return;
    }
    if (_matches(text, ['اوقف القراءه', 'اقفل القراءه', 'الغ القراءه'])) {
      if (TtsService.instance.tapToRead.value) {
        await TtsService.instance.toggleTapToRead();
      }
      await _reply('أوقفت وضع القراءة');
      return;
    }

    // ═══ 2. الإيقاف ═══
    if (_matches(text, ['اوقف', 'اسكت', 'سكوت', 'هدوء', 'صمت'])) {
      await TtsService.instance.stop();
      await _reply('تم الإيقاف');
      return;
    }

    // ═══ 3. التحقق من التنقل ═══
    if (nav == null) {
      await _reply('تعذّر التنقل');
      return;
    }

    // ═══ 4. الرئيسية / الرجوع ═══
    if (_matches(text, [
      'رئيسيه', 'الرئيسيه', 'رئيسي', 'الصفحه الاولى',
      'البدايه', 'هوم',
    ])) {
      await _reply('سأرجع للرئيسية');
      nav.popUntil((r) => r.isFirst);
      return;
    }
    if (_matches(text, ['ارجع', 'رجوع', 'للخلف', 'خلف', 'باك'])) {
      if (nav.canPop()) {
        nav.pop();
        await _reply('رجعت للخلف');
      } else {
        await _reply('لا يوجد شيء للرجوع');
      }
      return;
    }

    // ═══ 5. الثيم ═══
    if (_matches(text, ['ليلي', 'الليلي', 'ظلام', 'داكن', 'مظلم'])) {
      if (jisrThemeMode.value != ThemeMode.dark) await toggleThemeMode();
      await _reply('بدّلت للوضع الليلي');
      return;
    }
    if (_matches(text, ['فاتح', 'الفاتح', 'نهاري', 'نهار', 'صبح'])) {
      if (jisrThemeMode.value != ThemeMode.light) await toggleThemeMode();
      await _reply('بدّلت للوضع الفاتح');
      return;
    }

    // ═══ 6. الأوامر الخاصة بالطفل (قبل العامة) ═══
    await _ensureChildrenLoaded();

    // ═══ 6.1 دروس الطفل ═══
    if (_matches(text, [
      'دروس', 'الدروس', 'درس', 'افتح دروس', 'دروس الطفل',
    ])) {
      // استثناء: "دروس ولي الأمر" له أولوية أعلى
      if (_matches(text, ['ولي الامر', 'ولي الأمر', 'لولي الامر'])) {
        await _reply('سأفتح دروس ولي الأمر');
        nav.push(MaterialPageRoute(
          builder: (_) => const ParentLessonsScreen(),
        ));
        return;
      }

      final child = _findChild(text);
      if (child != null) {
        await _reply('سأفتح دروس ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => ChildLessonsScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
            age: child['age'] is int ? child['age'] as int : 8,
            disabilityType: child['disability_type']?.toString(),
            parentPhone: child['parent_phone']?.toString(),
          ),
        ));
        return;
      }
      await _reply('سأفتح قائمة الأطفال لاختيار طفل');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return;
    }

    // ═══ 6.2 واجبات الطفل ═══
    if (_matches(text, [
      'واجب', 'واجبات', 'الواجبات', 'الواجب',
      'افتح واجب', 'افتح واجبات',
    ])) {
      final child = _findChild(text);
      if (child != null) {
        await _reply('سأفتح واجبات ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => ChildHomeworkScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return;
      }
      await _reply('سأفتح قائمة الأطفال لاختيار طفل');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return;
    }

    // ═══ 6.3 تقدّم الطفل ═══
    if (_matches(text, [
      'تقدم', 'التقدم', 'انجاز', 'انجازات', 'مكافات',
      'نجوم', 'افتح تقدم', 'تقدم الطفل',
    ])) {
      final child = _findChild(text);
      if (child != null) {
        await _reply('سأفتح تقدّم ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => ChildProgressScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return;
      }
      await _reply('سأفتح قائمة الأطفال');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenScreen(forProgress: true),
      ));
      return;
    }

    // ═══ 6.4 تقرير الطفل ═══
    if (_matches(text, [
      'تقرير', 'التقرير', 'تقارير', 'التقارير',
      'تقرير اسبوعي', 'افتح تقرير',
    ])) {
      final child = _findChild(text);
      if (child != null) {
        await _reply('سأفتح تقرير ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => WeeklyReportScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return;
      }
      await _reply('سأفتح قائمة الأطفال');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenScreen(forProgress: true),
      ));
      return;
    }

    // ═══ 6.5 فريق الطفل ═══
    if (_matches(text, [
      'فريق', 'الفريق', 'فريق الطفل', 'افتح فريق',
    ])) {
      final child = _findChild(text);
      if (child != null) {
        await _reply('سأفتح فريق ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => CareTeamScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return;
      }
      await _reply('سأفتح قائمة الأطفال');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return;
    }

    // ═══ 6.6 طلب دعم تعليمي للطفل ═══
    if (_matches(text, [
      'طلب دعم', 'دعم تعليمي', 'طلب دعم تعليمي',
      'افتح دعم تعليمي',
    ])) {
      final child = _findChild(text);
      if (child != null) {
        await _reply('سأفتح طلب دعم تعليمي لـ ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => CreateLearningSupportRequestScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
          ),
        ));
        return;
      }
      await _reply('سأفتح قائمة الأطفال لاختيار طفل');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return;
    }

    // ═══ 6.7 إعدادات التكييف للطفل ═══
    if (_matches(text, [
      'تكييف', 'إعدادات التكييف', 'اعدادات التكييف',
      'تكييف الطفل',
    ])) {
      final child = _findChild(text);
      if (child != null) {
        await _reply('سأفتح إعدادات تكييف ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => ChildAccessibilitySettingsScreen(
            childId: child['id'],
            childName: (child['name'] ?? '').toString(),
            disabilityTypeHint: child['disability_type']?.toString(),
          ),
        ));
        return;
      }
      await _reply('سأفتح احتياجات الأبناء');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenAccessibilityOverviewScreen(),
      ));
      return;
    }

    // ═══ 6.8 دراسة حالة للطفل ═══
    if (_matches(text, [
      'دراسه', 'دراسة الحاله', 'دراسه الحاله', 'نقاش', 'مناقشه',
    ])) {
      final child = _findChild(text);
      if (child != null) {
        await _reply('سأفتح دراسة حالة ${child['name']}');
        nav.push(MaterialPageRoute(
          builder: (_) => CaseDiscussionScreen(
            filterChildId: child['id'],
          ),
        ));
        return;
      }
      await _reply('سأفتح دراسات الحالة');
      nav.push(MaterialPageRoute(
        builder: (_) => const CaseDiscussionScreen(),
      ));
      return;
    }

    // ═══ 7. الألعاب ═══
    final gameId = _detectGame(text);
    if (gameId != null) {
      final widget = _gameWidgetFor(gameId);
      if (widget != null) {
        await _reply('سأفتح ${_gameDisplayName(gameId)}');
        nav.push(MaterialPageRoute(builder: (_) => widget));
        return;
      }
    }

    if (_matches(text, [
      'الالعاب', 'العاب', 'قائمه الالعاب', 'شاشه الالعاب', 'العب',
    ])) {
      await _reply('سأفتح شاشة الألعاب');
      nav.push(MaterialPageRoute(
        builder: (_) => const EducationalGamesScreen(
          childName: 'بطل',
          age: 8,
        ),
      ));
      return;
    }

    // ═══ 8. الشاشات العامة ═══
    if (_matches(text, [
      'الاطفال', 'اطفال', 'الاولاد', 'اولاد', 'قائمه الاطفال',
    ])) {
      await _reply('سأفتح قائمة الأطفال');
      nav.push(MaterialPageRoute(builder: (_) => const ChildrenScreen()));
      return;
    }

    if (_matches(text, [
      'دروس ولي الامر', 'دروس لولي الامر', 'دروس للاهل', 'نصائح',
    ])) {
      await _reply('سأفتح دروس ولي الأمر');
      nav.push(MaterialPageRoute(
        builder: (_) => const ParentLessonsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'اشعارات', 'الاشعارات', 'تنبيهات', 'جرس',
    ])) {
      await _reply('سأفتح الإشعارات');
      nav.push(MaterialPageRoute(
        builder: (_) => const NotificationsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'محادثات', 'المحادثات', 'رسائل', 'شات',
    ])) {
      await _reply('سأفتح المحادثات');
      nav.push(MaterialPageRoute(builder: (_) => const ChatsScreen()));
      return;
    }

    if (_matches(text, [
      'مساعد', 'المساعد', 'نور', 'روبوت', 'اسال',
    ])) {
      await _reply('سأفتح المساعد نور');
      nav.push(MaterialPageRoute(
        builder: (_) => const AssistantScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'احتياجات', 'الاحتياجات', 'احتياجات الابناء', 'تخصيص',
    ])) {
      await _reply('سأفتح احتياجات الأبناء');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChildrenAccessibilityOverviewScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'الملف الشخصي', 'ملفي', 'بروفايل', 'حسابي',
    ])) {
      await _reply('سأفتح ملفك الشخصي');
      nav.push(MaterialPageRoute(builder: (_) => const ProfileScreen()));
      return;
    }

    if (_matches(text, [
      'كلمه المرور', 'كلمة السر', 'الباسورد',
    ])) {
      await _reply('سأفتح تغيير كلمة المرور');
      nav.push(MaterialPageRoute(
        builder: (_) => const ChangePasswordScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'توثيق', 'توثيق الهويه', 'تحقق', 'هويتي',
    ])) {
      await _reply('سأفتح توثيق الهوية');
      nav.push(MaterialPageRoute(
        builder: (_) => const VerifyIdentityScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'جلسات', 'الجلسات', 'اجتماعات دعم', 'اجتماعات الدعم',
    ])) {
      await _reply('سأفتح الجلسات');
      nav.push(MaterialPageRoute(
        builder: (_) => const LearningSupportMeetingsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'طلبات', 'الطلبات', 'طلبات الدعم',
    ])) {
      await _reply('سأفتح طلبات الدعم');
      nav.push(MaterialPageRoute(
        builder: (_) => const LearningSupportRequestsScreen(),
      ));
      return;
    }

    if (_matches(text, [
      'تواصل', 'التواصل', 'تواصل بالصور', 'aac',
    ])) {
      await _reply('سأفتح التواصل بالصور');
      nav.push(MaterialPageRoute(
        builder: (_) => const AACCommunicationScreen(childName: 'بطل'),
      ));
      return;
    }

    if (_matches(text, [
      'اضف طفل', 'اضافه طفل', 'ضيف طفل', 'طفل جديد',
    ])) {
      final role = await ApiService.getRole();
      if (role != 'parent' && role != 'admin') {
        await _reply('إضافة طفل متاحة لولي الأمر والأدمن فقط');
        return;
      }
      await _reply('سأفتح إضافة طفل جديد');
      nav.push(MaterialPageRoute(
        builder: (_) => const AddChildScreen(),
      ));
      return;
    }

    if (_matches(text, ['دروس عامه', 'الدروس العامه', 'مكتبه الدروس'])) {
      await _reply('سأفتح مكتبة الدروس');
      nav.push(MaterialPageRoute(builder: (_) => const LessonsScreen()));
      return;
    }

    // ═══ 9. المساعدة ═══
    if (_matches(text, [
      'مساعده', 'مساعدة', 'اوامر', 'الاوامر', 'ساعدني',
    ])) {
      await _reply(
        'تقدر تقول: '
        'افتح دروس [اسم الطفل]، افتح واجبات [اسم الطفل]، '
        'افتح تقدم [اسم الطفل]، افتح تقرير [اسم الطفل]، '
        'افتح دراسة حالة [اسم الطفل]. '
        'كمان: الألعاب، الأطفال، الإشعارات، المحادثات، المساعد، '
        'التواصل بالصور، دروس ولي الأمر، احتياجات الأبناء، '
        'الملف الشخصي، توثيق الهوية. '
        'وتقدر تقول: اقرأ، أوقف، ارجع، الرئيسية، الوضع الليلي',
      );
      return;
    }

    // ═══ غير مفهوم ═══
    await _reply(
      'سمعتك تقول: $rawText. جرّب: افتح دروس محمد، أو افتح الألعاب',
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  الألعاب
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

  /// لتفريغ cache (استدعِها بعد إضافة/حذف طفل)
  void clearChildrenCache() {
    _childrenCache = [];
    _childrenCacheTime = null;
  }
}