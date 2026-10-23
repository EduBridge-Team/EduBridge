import 'package:flutter/material.dart';
import '../theme.dart';

/// Account provisioning for schools belonging to an institution.
/// The existing API cannot provision school login accounts yet.
class InstitutionSchoolAccountScreen extends StatefulWidget {
  const InstitutionSchoolAccountScreen({super.key});

  @override
  State<InstitutionSchoolAccountScreen> createState() =>
      _InstitutionSchoolAccountScreenState();
}

class _InstitutionSchoolAccountScreenState
    extends State<InstitutionSchoolAccountScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmPassword = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    for (final controller in [
      _name, _email, _phone, _password, _confirmPassword,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Column(
      children: [
        Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: AppColors.appBarGradient,
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 20),
              child: Row(children: [
                IconButton(
                  tooltip: 'العودة إلى الرئيسية',
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_forward_rounded, color: Colors.white),
                ),
                const Expanded(
                  child: Text('إنشاء حساب مدرسة تابعة للمؤسسة',
                    style: TextStyle(fontSize: 20, color: Colors.white,
                      fontWeight: FontWeight.w800)),
                ),
              ]),
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('بيانات حساب المدرسة',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextFormField(controller: _name,
                    decoration: const InputDecoration(labelText: 'اسم المدرسة'),
                    validator: (value) => (value ?? '').trim().isEmpty
                        ? 'اسم المدرسة مطلوب' : null),
                  TextFormField(controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                    validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                        .hasMatch((value ?? '').trim()) ? null : 'بريد إلكتروني غير صالح'),
                  TextFormField(controller: _phone,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)')),
                  TextFormField(controller: _password,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'كلمة المرور'),
                    validator: (value) => (value ?? '').length >= 8
                        ? null : 'كلمة المرور يجب أن تكون 8 أحرف على الأقل'),
                  TextFormField(controller: _confirmPassword,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                    validator: (value) => value == _password.text
                        ? null : 'كلمتا المرور غير متطابقتين'),
                  const SizedBox(height: 20),
                  const Text(
                    'هذه الشاشة جاهزة للتصميم فقط. إنشاء حساب دخول '
                    'لمدرسة تابعة للمؤسسة ينتظر توفير API مخصص من السيرفر. '
                    'لن تُرسل بيانات الدخول إلى واجهة غير مدعومة.',
                  ),
                  const SizedBox(height: 12),
                  const FilledButton(
                    onPressed: null,
                    child: Text('إنشاء الحساب — بانتظار ربط السيرفر'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
}
