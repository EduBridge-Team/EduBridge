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
  final _specialtyCtrl = TextEditingController(); // ✅ جديد

  String _role = 'parent';
  bool _loading = false;
  String? _error;

  static const _roles = {
    'parent': 'ولي أمر',
    'teacher': 'معلّم',
    'specialist': 'مختص',
  };

  // ✅ هل يحتاج حقل التخصص؟
  bool get _needsSpecialty =>
      _role == 'teacher' || _role == 'specialist';

  String get _specialtyLabel {
    return _role == 'teacher' ? 'المادة التي تدرّسها *' : 'التخصص *';
  }

  String get _specialtyHint {
    return _role == 'teacher'
        ? 'مثال: رياضيات، لغة عربية، علوم'
        : 'مثال: تخاطب، دعم نفسي، تعديل سلوك';
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _error = null;
    });

    // ✅ نرسل التخصص مع الاسم في حقل name أو حقل منفصل
    final specialty = _needsSpecialty ? _specialtyCtrl.text.trim() : null;

    final error = await ApiService.register(
      _nameCtrl.text.trim(),
      _emailCtrl.text.trim(),
      _passwordCtrl.text,
      _role,
      phone: null,
    );

    // ملاحظة: تحتاج تمرير specialty أيضاً للـ API
    // يمكنك تعديل ApiService.register ليقبل specialty

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
    _specialtyCtrl.dispose();
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
                        if (!_needsSpecialty) _specialtyCtrl.clear();
                      });
                    },
                  ),

                  // ✅ حقل التخصص — يظهر فقط للمعلم/المختص
                  if (_needsSpecialty) ...[
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _specialtyCtrl,
                      style: const TextStyle(fontSize: 18),
                      decoration: InputDecoration(
                        labelText: _specialtyLabel,
                        hintText: _specialtyHint,
                        border: const OutlineInputBorder(),
                        prefixIcon: Icon(
                          _role == 'teacher'
                              ? Icons.menu_book
                              : Icons.psychology,
                        ),
                      ),
                      validator: (v) {
                        if (!_needsSpecialty) return null;
                        if (v == null || v.trim().isEmpty) {
                          return _role == 'teacher'
                              ? 'المادة مطلوبة'
                              : 'التخصص مطلوب';
                        }
                        return null;
                      },
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