import 'package:flutter/material.dart';

/// UI prepared for independent school accounts (not linked to an institution).
///
/// Backend account creation is deliberately disabled until an authorized
/// endpoint for the school role exists. Never send credentials to the existing
/// institution/ministry account or institution-scoped school endpoints.
class AdminSchoolCreatePage extends StatefulWidget {
  const AdminSchoolCreatePage({super.key});

  @override
  State<AdminSchoolCreatePage> createState() => _AdminSchoolCreatePageState();
}

class _AdminSchoolCreatePageState extends State<AdminSchoolCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();

  @override
  void dispose() {
    for (final controller in [
      _name, _email, _phone, _address, _password, _confirmation,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('إنشاء حساب مدرسة')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'حساب مدرسة مستقلة لا تتبع لأي مؤسسة.',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _name,
                  maxLength: 150,
                  decoration: const InputDecoration(labelText: 'اسم المدرسة'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'اسم المدرسة مطلوب' : null,
                ),
                TextFormField(
                  controller: _email,
                  maxLength: 255,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني للمدرسة'),
                  validator: (value) =>
                      RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                              .hasMatch((value ?? '').trim())
                          ? null : 'أدخل بريدًا إلكترونيًا صالحًا',
                ),
                TextFormField(
                  controller: _phone,
                  maxLength: 20,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'رقم الهاتف (اختياري)'),
                ),
                TextFormField(
                  controller: _address,
                  maxLength: 255,
                  decoration: const InputDecoration(labelText: 'عنوان المدرسة (اختياري)'),
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  validator: (value) => (value ?? '').length < 8 ||
                          (value ?? '').length > 128
                      ? 'كلمة المرور يجب أن تكون بين 8 و128 حرفًا' : null,
                ),
                TextFormField(
                  controller: _confirmation,
                  obscureText: true,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                  validator: (value) => value == _password.text
                      ? null : 'كلمتا المرور غير متطابقتين',
                ),
                const SizedBox(height: 12),
                const Text(
                  'إنشاء حساب المدرسة غير متاح حاليًا. سيتم تفعيل الحفظ '
                  'بعد إضافة دعم الحسابات المدرسية في السيرفر.',
                ),
                const SizedBox(height: 16),
                const FilledButton(
                  onPressed: null,
                  child: Text('إنشاء الحساب — بانتظار ربط السيرفر'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
