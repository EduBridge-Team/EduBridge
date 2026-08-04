// شاشة تسجيل الدخول
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import 'home_screen.dart';
import 'register_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final error = await ApiService.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      // نجاح — روح للرئيسية مع تنظيف كل الشاشات السابقة (الترحيبية وغيرها)
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } else {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // شعار جسر داخل هالة لونية ناعمة (متكيّفة مع الوضع)
                Builder(builder: (context) {
                  final c = JisrColors.of(context);
                  return Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [
                          c.tintTeal,
                          c.tintGreen,
                          c.tintOrange,
                          c.tintTeal,
                        ],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(26),
                      ),
                      child: Image.asset('assets/icon.png',
                          width: 88, height: 88),
                    ),
                  );
                }),
                const SizedBox(height: 18),
                Text(
                  'جسر التعليمي',
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: JisrColors.of(context).heading,
                  ),
                ),
                Text(
                  'تعلم بلا حدود',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'فرص متساوية للجميع',
                  style: TextStyle(
                      fontSize: 15, color: JisrColors.of(context).muted),
                ),
                const SizedBox(height: 40),

                // حقل الإيميل
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'الإيميل',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 16),

                // حقل الباسورد
                TextField(
                  controller: _passwordCtrl,
                  obscureText: true,
                  style: const TextStyle(fontSize: 18),
                  decoration: const InputDecoration(
                    labelText: 'كلمة المرور',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 16),

                // رسالة الخطأ
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                    ),
                  ),

                // زر الدخول — كبير لسهولة الوصول
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _login,
                    child: _loading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('دخول', style: TextStyle(fontSize: 20)),
                  ),
                ),
                const SizedBox(height: 12),

                // رابط إنشاء حساب جديد
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const RegisterScreen()),
                    );
                  },
                  child: const Text(
                    'ليس لديك حساب؟ أنشئ حساباً جديداً',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
