import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Device-level interface preference, independent of child adaptation profiles.
/// Authored lessons and user content keep their own language.
class AppLocaleController extends ValueNotifier<Locale> {
  AppLocaleController() : super(const Locale('ar'));

  static final instance = AppLocaleController();
  static const _preferenceKey = 'app_interface_language';
  int _revision = 0;
  Future<void> _pendingWrite = Future<void>.value();

  Future<void> load() async {
    final revision = ++_revision;
    final prefs = await SharedPreferences.getInstance();
    if (revision != _revision) return;
    final saved = prefs.getString(_preferenceKey);
    value = Locale(saved == 'en' ? 'en' : 'ar');
  }

  Future<void> setLocale(Locale locale) {
    final language = locale.languageCode;
    if (language != 'ar' && language != 'en') {
      return Future<void>.error(ArgumentError.value(locale, 'locale'));
    }
    final revision = ++_revision;
    // Serialize writes so rapid changes cannot leave an older choice on disk.
    final operation = _pendingWrite.then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setString(_preferenceKey, language)) {
        throw StateError('Could not save interface language');
      }
      if (revision == _revision) value = Locale(language);
    });
    // A failed save must not prevent later attempts.
    _pendingWrite = operation.catchError((Object _) {});
    return operation;
  }
}
