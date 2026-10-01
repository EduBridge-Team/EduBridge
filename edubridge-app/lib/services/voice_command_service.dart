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
import 'voice_command_text.dart';

part 'voice_command_routing.dart';
part 'voice_command_execution.dart';
part 'voice_command_child_navigation.dart';

class VoiceCommandService {
  VoiceCommandService._();
  static final VoiceCommandService instance = VoiceCommandService._();

  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _initialized = false;
  bool _available = false;
  bool _starting = false;
  bool _acceptResults = false;
  bool _commandHandled = false;
  int? _childrenCacheUserId;
  int _session = 0;
  String? _localeId;

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
    try {
      _available = await _speech.initialize(
        onStatus: _onStatus,
        onError: _onError,
      );
      _initialized = _available;
      if (_available) {
        final locales = await _speech.locales();
        for (final locale in locales) {
          if (locale.localeId.toLowerCase().startsWith('ar')) {
            _localeId = locale.localeId;
            break;
          }
        }
      }
      return _available;
    } catch (_) {
      _available = false;
      _initialized = false;
      return false;
    }
  }

  void _onStatus(String status) {
    if (status == 'done' || status == 'notListening') {
      isListening.value = false;
    }
  }

  void _onError(dynamic error) {
    isListening.value = false;
    _acceptResults = false;
    lastReply.value = 'تعذّر سماع الأمر. تأكد من إذن الميكروفون ثم حاول مجدداً';
  }

  Future<void> startListening() async {
    if (_starting || isListening.value) {
      await cancel();
      return;
    }
    _starting = true;
    final session = ++_session;
    try {
      if (!await initialize()) {
        await _reply('الميكروفون غير متاح. تأكد من إذن الميكروفون ثم حاول مجدداً');
        return;
      }
      if (session != _session) return;
      if (_localeId == null) {
        await _reply('التعرف على الكلام العربي غير متاح. أضف اللغة العربية إلى خدمة الكلام على الجهاز');
        return;
      }
      await TtsService.instance.stop();
      if (session != _session) return;
      lastHeard.value = '';
      lastReply.value = '';
      _acceptResults = true;
      _commandHandled = false;
      isListening.value = true;
      await _speech.listen(
        onResult: (result) { if (session == _session) _onResult(result); },
        listenOptions: stt.SpeechListenOptions(
          localeId: _localeId,
          listenFor: const Duration(seconds: 10),
          pauseFor: const Duration(seconds: 4),
          partialResults: true,
        ),
      );
    } catch (_) {
      isListening.value = false;
      _acceptResults = false;
      await _reply('تعذّر تشغيل الميكروفون. حاول مجدداً');
    } finally {
      _starting = false;
    }
  }

  Future<void> stopListening() async {
    await cancel();
  }

  Future<void> cancel() async {
    _session++;
    _acceptResults = false;
    isListening.value = false;
    try {
      await _speech.cancel();
    } catch (_) {}
  }

  void _onResult(SpeechRecognitionResult result) {
    if (!_acceptResults || _commandHandled) return;
    final text = result.recognizedWords.trim();
    if (text.isEmpty) return;
    lastHeard.value = text;
    if (result.finalResult) {
      _commandHandled = true;
      _acceptResults = false;
      isListening.value = false;
      unawaited(_executeCommand(text).catchError((Object _) => _reply('تعذّر تنفيذ الأمر. حاول مجدداً')));
    }
  }

  /// لتفريغ cache (استدعِها بعد إضافة/حذف طفل)
  void clearChildrenCache() {
    _childrenCache = [];
    _childrenCacheTime = null;
    _childrenCacheUserId = null;
  }
}
