import 'package:shared_preferences/shared_preferences.dart';

/// Stores whether the introductory onboarding has already been completed.
///
/// This is intentionally device-local: reinstalling the app is treated as a
/// fresh install and will show onboarding again.
class OnboardingService {
  OnboardingService._();

  static const _seenKey = 'edubridge_onboarding_seen_v1';

  static Future<bool> hasSeen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_seenKey) ?? false;
  }

  static Future<void> markSeen() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_seenKey, true);
  }
}
