import 'package:flutter/material.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();
final ValueNotifier<bool> assistantScreenVisible = ValueNotifier(false);

/// صحيح طالما في bottom sheet (أو أي modal مشابه) مفتوح فوق الشاشة.
/// نستخدمه لإخفاء أيقونة المساعد الذكي العائمة حتى لا تتراكب فوق
/// أزرار أي modal (إضافة شهادة، الدعم الفني، التقييم، ...).
final ValueNotifier<bool> modalSheetOpen = ValueNotifier(false);

/// النوافذ المرسومة داخل الصفحة نفسها (وليست Route في Navigator)، مثل
/// نافذة إضافة درس في لوحتي المعلّم والمختص.
final ValueNotifier<bool> inlineModalOpen = ValueNotifier(false);

/// كائن ثابت حتى لا يفقد عدد النوافذ المفتوحة عند إعادة بناء [MaterialApp]
/// بعد تغيير الثيم أو إعدادات سهولة الوصول.
final JisrModalRouteObserver jisrModalRouteObserver =
    JisrModalRouteObserver();

/// يرصد فتح/إغلاق أي نافذة منبثقة على أي Navigator بالتطبيق
/// ويحدّث [modalSheetOpen] تلقائيًا — بدون الحاجة لتعديل كل استدعاء
/// showModalBottomSheet أو showDialog على حدة.
class JisrModalRouteObserver extends NavigatorObserver {
  int _openCount = 0;

  bool _isModalRoute(Route<dynamic>? route) => route is PopupRoute<dynamic>;

  void _update() {
    modalSheetOpen.value = _openCount > 0;
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isModalRoute(route)) {
      _openCount++;
      _update();
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isModalRoute(route)) {
      if (_openCount > 0) _openCount--;
      _update();
    }
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (_isModalRoute(route)) {
      if (_openCount > 0) _openCount--;
      _update();
    }
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (_isModalRoute(oldRoute) && _openCount > 0) _openCount--;
    if (_isModalRoute(newRoute)) _openCount++;
    _update();
  }
}
