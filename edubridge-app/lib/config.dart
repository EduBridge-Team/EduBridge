// إعدادات التطبيق
class Config {
  // Production — Taqat Academy + custom EduBridge domain.
  static const String baseUrl = "https://api.edubridge.win/api";
  static const String wsUrl = "wss://api.edubridge.win/ws";

  // 🔹 للجهاز الحقيقي (USB) - تحتاج adb reverse
  // static const String baseUrl = "http://127.0.0.1:8000/api";
  // static const String wsUrl = "ws://127.0.0.1:8000";
}
