// إعدادات التطبيق
class Config {
  // عنوان الـ API — النسخة المنشورة على alwaysdata (يعمل من أي مكان)
  // للتطوير المحلي بدّل إلى:
  // - جهاز حقيقي عبر USB: `adb reverse tcp:3000 tcp:3000` + http://127.0.0.1:3000/api
  // - محاكي أندرويد: http://10.0.2.2:3000/api
  static const String baseUrl = "https://edubridge.alwaysdata.net/api";
}
