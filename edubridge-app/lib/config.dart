// إعدادات التطبيق
class Config {
  // Production API
  static const String baseUrl = "https://api.edubridge.win/api";

  // WebSocket endpoint is not currently exposed by the Oracle deployment.
  // Keep this empty until a production WebSocket service is explicitly configured.
  static const String wsUrl = "";

  // OAuth Web client ID used as serverClientId by Google Sign-In.
  // Pass at build time with:
  // --dart-define=GOOGLE_SERVER_CLIENT_ID=...
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');
}
