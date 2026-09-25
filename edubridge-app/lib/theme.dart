
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_colors.dart';
part 'theme_builders.dart';
part 'jisr_app_bar.dart';

final ValueNotifier<ThemeMode> jisrThemeMode = ValueNotifier(ThemeMode.light);

Future<void> loadSavedThemeMode() async {
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('dark_mode') ?? false;
  jisrThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
}

Future<void> toggleThemeMode() async {
  final isDark = jisrThemeMode.value != ThemeMode.dark;
  jisrThemeMode.value = isDark ? ThemeMode.dark : ThemeMode.light;
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('dark_mode', isDark);
}
