// lib/screens/login_screen.dart
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../services/google_auth_service.dart';
import '../services/google_role_login_service.dart';
import '../theme.dart';
import '../utils/home_router.dart';
import '../widgets/brand_lockup.dart';
import 'register_screen.dart';
import 'password_recovery_screen.dart';
part 'login_screen_view.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  void _refreshState(VoidCallback callback) => setState(callback);

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  bool _obscurePassword = true;
  String _googleRole = 'parent';
  String? _error;
  String? _notice;

  static const _googleRoles = {
    'parent': 'ولي أمر',
    'teacher': 'معلّم',
    'specialist': 'مختص',
  };

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    final error = await ApiService.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      final home = await homeScreenForRole();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => home),
        (route) => false,
      );
    } else {
      setState(() => _error = error);
    }
  }

  Future<void> _googleLogin() async {
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });

    try {
      final idToken = await GoogleAuthService.authenticate();
      final error = await GoogleRoleLoginService.login(
        idToken,
        role: _googleRole,
      );

      if (!mounted) return;
      if (error != null) {
        setState(() {
          _loading = false;
          _error = error;
        });
        return;
      }

      final home = await homeScreenForRole();
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => home),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Bad state: ', '');
      });
    }
  }

  Future<void> _resendVerification() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() {
        _error = 'أدخل بريدك الإلكتروني أولاً';
        _notice = null;
      });
      return;
    }

    setState(() {
      _error = null;
      _notice = null;
    });

    final error = await ApiService.resendEmailVerification(email);
    if (!mounted) return;

    if (error == null) {
      setState(() => _notice =
          'إذا كان الحساب بحاجة للتحقق فستصلك رسالة جديدة على بريدك الإلكتروني.');
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) => buildView(context);
}

class _GlowCircle extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowCircle({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
