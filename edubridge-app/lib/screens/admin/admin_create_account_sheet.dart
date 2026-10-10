part of 'admin_screen.dart';

class _CreateAccountSheet extends StatefulWidget {
  const _CreateAccountSheet();

  @override
  State<_CreateAccountSheet> createState() => _CreateAccountSheetState();
}

class _CreateAccountSheetState extends State<_CreateAccountSheet> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirmation = TextEditingController();
  String _role = 'institution';
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    for (final controller in [_name, _email, _phone, _password, _confirmation]) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() { _saving = true; _error = null; });
    try {
      final response = await ApiService.authPost('/users', {
        'name': _name.text.trim(),
        'email': _email.text.trim().toLowerCase(),
        'phone': _phone.text.trim(),
        'role': _role,
        'password': _password.text,
        'password_confirmation': _confirmation.text,
      });
      if (!mounted) return;
      if (response.statusCode == 201) {
        Navigator.pop(context, true);
        return;
      }
      final data = ApiService.decodeMap(response.body);
      setState(() => _error = (data['error'] ?? data['message'] ?? 'تعذّر إنشاء الحساب').toString());
    } catch (_) {
      if (mounted) setState(() => _error = 'تعذّر الاتصال بالسيرفر. حاول مجدداً.');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, 24, 20, MediaQuery.viewInsetsOf(context).bottom + 24),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text('إنشاء حساب مؤسسة أو وزارة', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'نوع الحساب'),
                  items: const [
                    DropdownMenuItem(value: 'institution', child: Text('مؤسسة')),
                    DropdownMenuItem(value: 'ministry', child: Text('وزارة')),
                  ],
                  onChanged: _saving ? null : (value) => setState(() => _role = value!),
                ),
                TextFormField(
                  controller: _name, enabled: !_saving, maxLength: 150,
                  decoration: const InputDecoration(labelText: 'اسم المؤسسة أو الوزارة'),
                  validator: (value) => (value ?? '').trim().isEmpty ? 'أدخل الاسم' : null,
                ),
                TextFormField(
                  controller: _email, enabled: !_saving, maxLength: 255,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'البريد الإلكتروني'),
                  validator: (value) => RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch((value ?? '').trim()) ? null : 'أدخل بريداً إلكترونياً صالحاً',
                ),
                TextFormField(
                  controller: _phone, enabled: !_saving, maxLength: 20,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'الهاتف (اختياري)'),
                ),
                TextFormField(
                  controller: _password, enabled: !_saving, obscureText: true,
                  autocorrect: false, enableSuggestions: false,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  validator: (value) => (value ?? '').length < 8 || (value ?? '').length > 128 ? 'استخدم كلمة مرور من 8 إلى 128 حرفاً' : null,
                ),
                TextFormField(
                  controller: _confirmation, enabled: !_saving, obscureText: true,
                  autocorrect: false, enableSuggestions: false,
                  decoration: const InputDecoration(labelText: 'تأكيد كلمة المرور'),
                  validator: (value) => value != _password.text ? 'تأكيد كلمة المرور غير مطابق' : null,
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(_error!, style: const TextStyle(color: AppColors.red)),
                ],
                const SizedBox(height: 20),
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'جارٍ إنشاء الحساب...' : 'إنشاء الحساب'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
