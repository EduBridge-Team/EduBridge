import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../theme.dart';
import '../services/onboarding_service.dart';
import '../widgets/brand_lockup.dart';
import 'login_screen.dart';
import 'register_screen.dart';

part 'welcome_page_content.dart';
part 'welcome_background.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});
  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> with TickerProviderStateMixin {
  final _controller = PageController(keepPage: false);
  late final AnimationController _entrance = AnimationController(
    vsync: this, duration: const Duration(milliseconds: 700));
  late final AnimationController _float = AnimationController(
    vsync: this, duration: const Duration(seconds: 4));
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.of(context).disableAnimations;
    if (_reduceMotion) {
      _entrance.value = 1;
      _float.stop();
      _float.value = 0;
    } else {
      if (_tour && !_float.isAnimating) _float.repeat();
      if (_entrance.value == 0) _entrance.forward();
    }
  }

  void _reveal() {
    if (_reduceMotion) { _entrance.value = 1; }
    else { _entrance.forward(from: 0); }
  }

  void _onTourPageChanged(int index) {
    setState(() => _page = index);
    _reveal();
  }

  void _leaveTour() {
    _float.stop();
    setState(() => _tour = false);
    _reveal();
  }

  void _movePage(int delta) {
    final target = (_page + delta).clamp(0, 2).toInt();
    if (_reduceMotion) { _controller.jumpToPage(target); }
    else { _controller.animateToPage(target,
      duration: const Duration(milliseconds: 300), curve: Curves.easeInOut); }
  }

  bool _expanded = false;
  bool _tour = false;
  int _page = 0;
  static const _blue = Color(0xFF1769B8);
  static const _teal = Color(0xFF169CA7);

  @override
  void dispose() {
    _entrance.dispose();
    _float.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _authenticate({bool register = false}) async {
    await OnboardingService.markSeen();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute<void>(
      builder: (_) => register ? const RegisterScreen() : const LoginScreen(),
    ));
  }

  void _startTour() {
    setState(() { _page = 0; _tour = true; });
    if (!_reduceMotion) _float.repeat();
    _reveal();
  }

  Widget _button(String label, IconData icon, VoidCallback action,
      {bool outlined = false}) {
    final child = Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(icon, size: 22), const SizedBox(width: 10),
      Flexible(child: Text(label, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700))),
    ]);
    final shape = RoundedRectangleBorder(borderRadius: BorderRadius.circular(28));
    return SizedBox(width: double.infinity, child: outlined
      ? OutlinedButton(onPressed: action, style: OutlinedButton.styleFrom(
          foregroundColor: _blue, padding: const EdgeInsets.all(16), shape: shape,
          side: const BorderSide(color: Color(0xFFCADFE5))), child: child)
      : FilledButton(onPressed: action, style: FilledButton.styleFrom(
          backgroundColor: _blue, foregroundColor: Colors.white,
          padding: const EdgeInsets.all(16), shape: shape), child: child));
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Directionality(textDirection: TextDirection.rtl, child: Scaffold(
      backgroundColor: dark ? const Color(0xFF101F2C) : const Color(0xFFF6FCFE),
      body: SafeArea(child: _tour ? _buildTour() : SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 520),
          child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              const Flexible(child: BrandLockup(iconSize: 40, fontSize: 27)),
              IconButton.filledTonal(onPressed: toggleThemeMode,
                tooltip: dark ? 'الوضع الفاتح' : 'الوضع الداكن',
                icon: Icon(dark ? Icons.light_mode_outlined : Icons.dark_mode_outlined)),
            ]),
            const SizedBox(height: 24),
            _motion(0, Container(padding: const EdgeInsets.all(26), decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              gradient: const LinearGradient(begin: Alignment.topRight, end: Alignment.bottomLeft,
                colors: [_blue, Color(0xFF087E9A)]),
              boxShadow: [BoxShadow(color: _blue.withValues(alpha: .18), blurRadius: 24, offset: const Offset(0, 10))]),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Text('تعليم ذكي\nوشامل\nلكل طفل', style: TextStyle(color: Colors.white,
                  fontSize: 32, height: 1.35, fontWeight: FontWeight.w800)),
                const SizedBox(height: 14),
                const Text('أدوات تعليمية مرنة تربط الطفل بأسرته ومعلميه ومختصيه في تجربة واحدة آمنة.',
                  style: TextStyle(color: Colors.white, height: 1.8, fontSize: 15)),
                const SizedBox(height: 16),
                Wrap(spacing: 8, runSpacing: 8, children: [
                  _badge('متاح للجميع', Icons.accessibility_new),
                  _badge('تعلم مخصص', Icons.auto_awesome_outlined),
                  _badge('بيئة آمنة', Icons.shield_outlined),
                ]),
              ]))),
            const SizedBox(height: 24),
            _motion(.15, _button('تسجيل الدخول', Icons.login, () => _authenticate())),
            const SizedBox(height: 12),
            _motion(.25, _button('إنشاء حساب جديد', Icons.person_add_alt, () => _authenticate(register: true), outlined: true)),
            const SizedBox(height: 12),
            TextButton(onPressed: () => setState(() => _expanded = !_expanded),
              child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text(_expanded ? 'إخفاء' : 'تعرّف على EduBridge',
                  style: const TextStyle(color: _teal, fontWeight: FontWeight.w700)),
                const SizedBox(width: 8), AnimatedRotation(
                  turns: _expanded ? .5 : 0,
                  duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 220),
                  child: const Icon(Icons.expand_more, color: _teal)),
              ])),
            AnimatedSize(duration: _reduceMotion ? Duration.zero : const Duration(milliseconds: 250),
              alignment: Alignment.topCenter,
              child: _expanded ? _buildAbout() : const SizedBox.shrink()),
          ]))),
      )),
    ));
  }

  Widget _badge(String text, IconData icon) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
    decoration: BoxDecoration(color: Colors.white.withValues(alpha: .16), borderRadius: BorderRadius.circular(10)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(icon, color: Colors.white, size: 16),
      const SizedBox(width: 5), Text(text, style: const TextStyle(color: Colors.white, fontSize: 12))]));
}
