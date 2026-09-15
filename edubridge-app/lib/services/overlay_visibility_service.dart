import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// يحفظ تفضيلات ظهور الأدوات العائمة ويتيح تغييرها من قائمة التطبيق.
class OverlayVisibilityService {
  OverlayVisibilityService._();

  static const _assistantKey = 'show_noor_assistant';
  static const _microphoneKey = 'show_voice_microphone';

  static final assistantVisible = ValueNotifier<bool>(true);
  static final microphoneVisible = ValueNotifier<bool>(true);

  static Future<void> initialize() async {
    final preferences = await SharedPreferences.getInstance();
    assistantVisible.value = preferences.getBool(_assistantKey) ?? true;
    microphoneVisible.value = preferences.getBool(_microphoneKey) ?? true;
  }

  static Future<void> setAssistantVisible(bool visible) async {
    assistantVisible.value = visible;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_assistantKey, visible);
  }

  static Future<void> setMicrophoneVisible(bool visible) async {
    microphoneVisible.value = visible;
    final preferences = await SharedPreferences.getInstance();
    await preferences.setBool(_microphoneKey, visible);
  }
}
