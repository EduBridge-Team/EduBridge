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

part 'voice_command_routing.dart';

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

  /// لتفريغ cache (استدعِها بعد إضافة/حذف طفل)
  void clearChildrenCache() {
    _childrenCache = [];
    _childrenCacheTime = null;
  }
}