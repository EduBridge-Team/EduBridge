// register_screen.dart — النسخة المحدّثة
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme.dart';
import '../widgets/brand_lockup.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  String _specialty = 'learning_support';

  String _role = 'parent';
  bool _loading = false;
  String? _error;

  static const _roles = {
    'parent': 'ولي أمر',
    'teacher': 'معلّم',
    'specialist': 'مختص',
  };

  bool get _needsSpecialty => _role == 'specialist';

  static const _specialties = {
    'learning_support': 'دعم تعليمي',
    'educational': 'خطط تعلم',
    'communication_support': 'دعم التواصل التعليمي',
    'learning_behavior': 'دعم سلوك التعلم',
  };

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    final specialty = _needsSpecialty ? _specialty : null;

    final error = await ApiService.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _role,
      phone: null,
      specialty: specialty,
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء الحساب بنجاح — سجّل دخولك الآن'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } else {
      setState(() => _error = error);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const JisrAppBar(title: 'إنشاء حساب'),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const BrandLockup(iconSize: 68, fontSize: 38, gap: 10),
                  const SizedBox(height: 14),
                  Text(
                    'ابدأ رحلتك مع EduBridge',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w800,
                      color: JisrColors.of(context).heading,
                    ),
                  ),
                  const SizedBox(height: 22),

                  TextFormField(
                    controller: _nameCtrl,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'الاسم',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'الاسم مطلوب' : null,
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'الإيميل',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.email),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'الإيميل مطلوب';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'صيغة الإيميل غير صحيحة';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    initialValue: _role,
                    style: TextStyle(
                        fontSize: 18, color: JisrColors.of(context).body),
                    decoration: const InputDecoration(
                      labelText: 'الدور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                    items: _roles.entries
                        .map((e) => DropdownMenuItem(
                              value: e.key,
                              child: Text(e.value,
                                  style: const TextStyle(fontSize: 18)),
                            ))
                        .toList(),
                    onChanged: (v) {
                      setState(() {
                        _role = v ?? 'parent';
                        if (_role != 'specialist') {
                          _specialty = 'learning_support';
                        }
                      });
                    },
                  ),

                  if (_needsSpecialty) ...[
                    const SizedBox(height: 16),
                    DropdownButtonFormField<String>(
                      initialValue: _specialty,
                      decoration: const InputDecoration(
                        labelText: 'التخصص',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.school_outlined),
                      ),
                      items: _specialties.entries
                          .map((e) => DropdownMenuItem(
                                value: e.key,
                                child: Text(e.value),
                              ))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _specialty = v ?? 'learning_support'),
                    ),
                  ],

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _passwordCtrl,
                    obscureText: true,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'كلمة المرور مطلوبة';
                      if (v.length < 6) {
                        return 'كلمة المرور 6 أحرف على الأقل';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: true,
                    style: const TextStyle(fontSize: 18),
                    decoration: const InputDecoration(
                      labelText: 'تأكيد كلمة المرور',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    validator: (v) =>
                        v != _passwordCtrl.text ? 'كلمتا المرور غير متطابقتين' : null,
                  ),
                  const SizedBox(height: 16),

                  if (_error != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _error!,
                        style:
                            const TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _register,
                      child: _loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('إنشاء الحساب',
                              style: TextStyle(fontSize: 20)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}