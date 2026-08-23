// إعدادات التطبيق
class Config {
  
   // 🔹 للمحاكي (Android Emulator)
    static const String baseUrl = "https://edubridge.alwaysdata.net/api";
  static const String wsUrl = "wss://edubridge.alwaysdata.net/ws";
   
  
  // 🔹 للجهاز الحقيقي (USB) - تحتاج adb reverse
  // static const String baseUrl = "http://127.0.0.1:8000/api";
  // static const String wsUrl = "ws://127.0.0.1:8000";
}
    
