import 'package:google_sign_in/google_sign_in.dart';

import '../config.dart';

class GoogleAuthService {
  GoogleAuthService._();

  static Future<void>? _initialization;

  static bool get isConfigured => Config.googleServerClientId.trim().isNotEmpty;

  static Future<void> _ensureInitialized() {
    return _initialization ??= GoogleSignIn.instance.initialize(
      serverClientId: Config.googleServerClientId,
    );
  }

  static Future<String> authenticate() async {
    if (!isConfigured) {
      throw StateError('Google Sign-In غير مهيأ لهذا البناء');
    }

    await _ensureInitialized();

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw StateError('تسجيل Google غير مدعوم على هذا الجهاز');
    }

    final account = await GoogleSignIn.instance.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null || idToken.isEmpty) {
      throw StateError('تعذّر الحصول على رمز Google');
    }

    return idToken;
  }

  static Future<void> signOut() async {
    if (_initialization == null) return;
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
  }
}
