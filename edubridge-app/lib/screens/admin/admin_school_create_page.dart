import 'package:flutter/material.dart';
import '../../services/api_service.dart';

/// Creates a school record only. This does not provision a login account.
class AdminSchoolCreatePage extends StatefulWidget {
  const AdminSchoolCreatePage({super.key});

  @override
  State<AdminSchoolCreatePage> createState() => _AdminSchoolCreatePageState();
}

class _AdminSchoolCreatePageState extends State<AdminSchoolCreatePage> {
  final _formKey = GlobalKey<FormState>();
  final _organizationSlug = TextEditingController();
  final _name = TextEditingController();
  final _schoolSlug = TextEditingController();
  final _address = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _organizationSlug.dispose();
    _name.dispose();
    _schoolSlug.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final slug = _organizationSlug.text.trim().toLowerCase();
      final response = await ApiService.authPost(
        '/institutions/${Uri.encodeComponent(slug)}/schools',
        {
          'name': _name.text.trim(),
          'slug': _schoolSlug.text.trim().toLowerCase(),
          'address': _address.text.trim(),
        },
      );
      if (!mounted) return;
      if (response.statusCode == 201) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم إضافة سجل المدرسة بنجاح')),
        );
        Navigator.of(context).pop(true);
        return;
      }
      final data = ApiService.decodeMap(response.body);
      setState(() {
        _error = (data['error'] ?? data['message'] ??
          'تعذّرت إضافة المدرسة. تأكد من عضويتك وصلاحيتك في المؤسسة.').toString();
      });
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'تعذّر الاتصال بالخادم');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const slugPattern = r'^[a-z0-9][a-z0-9-]*$';
    return Scaffold(
      appBar: AppBar(title: const Text('إضافة مدرسة')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'هذه الشاشة تنشئ سجل مدرسة داخل مؤسسة موجودة، '
                  'ولا تنشئ حساب تسجيل دخول. يجب أن يمتلك المستخدم '
                  'صلاحية إدارة المؤسسة المحددة.',
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _organizationSlug,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'معرّف المؤسسة',
                    hintText: 'demo-institution',
                  ),
                  validator: (value) =>
                      RegExp(slugPattern).hasMatch((value ?? '').trim().toLowerCase())
                          ? null : 'أدخل معرّف مؤسسة صحيحًا',
                ),
                TextFormField(
                  controller: _name,
                  enabled: !_saving,
                  maxLength: 150,
                  decoration: const InputDecoration(labelText: 'اسم المدرسة'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'اسم المدرسة مطلوب' : null,
                ),
                TextFormField(
                  controller: _schoolSlug,
                  enabled: !_saving,
                  maxLength: 80,
                  decoration: const InputDecoration(
                    labelText: 'معرّف المدرسة بالإنجليزية',
                  ),
                  validator: (value) =>
                      RegExp(slugPattern).hasMatch((value ?? '').trim().toLowerCase())
                          ? null : 'استخدم أحرفًا إنجليزية صغيرة وأرقامًا وشرطة',
                ),
                TextFormField(
                  controller: _address,
                  enabled: !_saving,
                  maxLength: 255,
                  decoration: const InputDecoration(labelText: 'العنوان (اختياري)'),
                ),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(_error!,
                        style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                const SizedBox(height: 14),
                FilledButton(
                  onPressed: _saving ? null : _submit,
                  child: Text(_saving ? 'جارٍ الحفظ...' : 'إضافة مدرسة'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
