import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../theme.dart';
import 'api_service.dart';
import 'overlay_visibility_service.dart';

/// Keeps lightweight UI preferences synchronized between devices.
/// Local storage remains the fallback when the API is unavailable.
class UserSettingsSyncService {
  UserSettingsSyncService._();

  static Future<void> syncFromServer() async {
    try {
      final response = await ApiService.authGet('/settings');
      if (response.statusCode != 200 || response.body.isEmpty) return;

      final decoded = jsonDecode(response.body);
      if (decoded is! Map) return;

      final settingsRaw = decoded['settings'];
      if (settingsRaw is! Map) return;
      final settings = Map<String, dynamic>.from(settingsRaw);

      final prefs = await SharedPreferences.getInstance();
      final themeMode = settings['theme_mode']?.toString();
      if (themeMode == 'dark' || themeMode == 'light') {
        final isDark = themeMode == 'dark';
        jisrThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
        await prefs.setBool('dark_mode', isDark);
      }

      final assistantVisible = settings['assistant_visible'];
      if (assistantVisible is bool) {
        await OverlayVisibilityService.setAssistantVisible(assistantVisible);
      }

      final microphoneVisible = settings['microphone_visible'];
      if (microphoneVisible is bool) {
        await OverlayVisibilityService.setMicrophoneVisible(microphoneVisible);
      }
    } catch (_) {
      // Offline or old backend: keep the local preferences without blocking UI.
    }
  }

  static Future<void> pushCurrent() async {
    try {
      await ApiService.authPut('/settings', {
        'theme_mode':
            jisrThemeMode.value == ThemeMode.dark ? 'dark' : 'light',
        'assistant_visible': OverlayVisibilityService.assistantVisible.value,
        'microphone_visible': OverlayVisibilityService.microphoneVisible.value,
      });
    } catch (_) {
      // Local settings are already saved. A failed sync must not revert them.
    }
  }
}
