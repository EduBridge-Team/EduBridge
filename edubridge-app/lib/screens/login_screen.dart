// شاشة تسجيل الدخول
import 'package:flutter/material.dart';
import '../services/api_service.dart';
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
      // نجاح — روح للرئيسية
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
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
                // شعار جسر
                Image.asset('assets/icon.png', width: 110, height: 110),
                const SizedBox(height: 16),
                const Text(
                  'EduBridge',
                  style: TextStyle(fontSize: 34, fontWeight: FontWeight.bold),
                ),
                const Text(
                  'جسر تعليمي',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2E7D6B),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'تعلم بلا حدود .. فرص متساوية للجميع',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
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
