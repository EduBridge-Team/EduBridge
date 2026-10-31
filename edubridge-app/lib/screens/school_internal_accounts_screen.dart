import 'package:flutter/material.dart';

import '../services/api_service.dart';

/// Director-only account management. The API enforces school authorization.
class SchoolInternalAccountsScreen extends StatefulWidget {
  const SchoolInternalAccountsScreen({super.key});

  @override
  State<SchoolInternalAccountsScreen> createState() =>
      _SchoolInternalAccountsScreenState();
}

class _SchoolInternalAccountsScreenState
    extends State<SchoolInternalAccountsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _username = TextEditingController();
  final _password = TextEditingController();
  String _role = 'teacher';
  bool _loading = false;
  bool _saving = false;
  String? _error;
  List<Map<String, dynamic>> _accounts = [];
  int? _nextCursor;
  bool _hasMore = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _name.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _load({bool more = false}) async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await ApiService.getSchoolInternalAccounts(
        afterId: more ? _nextCursor : null,
      );
      final items = (data['identities'] as List<dynamic>? ?? [])
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList();
      if (!mounted) return;
      setState(() {
        _accounts = more ? [..._accounts, ...items] : items;
        _nextCursor = data['next_after_id'] as int?;
        _hasMore = data['has_more'] == true;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _create() async {
    if (!_formKey.currentState!.validate() || _saving) return;
    setState(() => _saving = true);
    try {
      final created = await ApiService.createSchoolInternalAccount(
        name: _name.text,
        username: _username.text,
        role: _role,
        password: _password.text,
      );
      _password.clear();
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('تم إنشاء الحساب: ${created['login_identifier'] ?? ''}'),
      ));
      await _load();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('تعذر إنشاء الحساب: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _showCreate() {
    _name.clear();
    _username.clear();
    _password.clear();
    _role = 'teacher';
    showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, updateDialog) => AlertDialog(
          title: const Text('إنشاء حساب مدرسي'),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'الاسم'),
                  validator: (value) => (value ?? '').trim().isEmpty
                      ? 'الاسم مطلوب' : null,
                ),
                TextFormField(
                  controller: _username,
                  decoration: const InputDecoration(
                    labelText: 'اسم المستخدم (بالإنجليزية)',
                  ),
                  validator: (value) =>
                      RegExp(r'^[a-z0-9][a-z0-9._-]{1,63}$')
                              .hasMatch((value ?? '').trim())
                          ? null : 'اسم المستخدم غير صالح',
                ),
                DropdownButtonFormField<String>(
                  initialValue: _role,
                  decoration: const InputDecoration(labelText: 'نوع الحساب'),
                  items: const [
                    DropdownMenuItem(value: 'teacher', child: Text('معلم')),
                    DropdownMenuItem(value: 'student', child: Text('طالب')),
                  ],
                  onChanged: (value) {
                    if (value != null) updateDialog(() => _role = value);
                  },
                ),
                TextFormField(
                  controller: _password,
                  obscureText: true,
                  decoration: const InputDecoration(labelText: 'كلمة المرور'),
                  validator: (value) => (value ?? '').length < 12
                      ? 'كلمة المرور 12 حرفًا على الأقل' : null,
                ),
              ]),
            ),
          ),
          actions: [
            TextButton(
              onPressed: _saving ? null : () => Navigator.pop(dialogContext),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: _saving ? null : _create,
              child: const Text('إنشاء'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('حسابات المدرسة')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showCreate,
        icon: const Icon(Icons.person_add_alt_1),
        label: const Text('إضافة حساب'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          children: [
            if (_loading) const LinearProgressIndicator(),
            if (_error != null)
              ListTile(
                title: Text(_error!),
                trailing: IconButton(
                  onPressed: () => _load(),
                  icon: const Icon(Icons.refresh),
                ),
              ),
            if (!_loading && _error == null && _accounts.isEmpty)
              const ListTile(title: Text('لا توجد حسابات داخلية بعد')),
            ..._accounts.map((account) => ListTile(
              leading: Icon(account['role'] == 'teacher'
                  ? Icons.school_outlined : Icons.person_outline),
              title: Text('${account['name'] ?? ''}'),
              subtitle: Text('${account['username'] ?? ''}'),
              trailing: Text(account['role'] == 'teacher' ? 'معلم' : 'طالب'),
            )),
            if (_hasMore)
              TextButton(
                onPressed: _loading ? null : () => _load(more: true),
                child: const Text('عرض المزيد'),
              ),
            const SizedBox(height: 90),
          ],
        ),
      ),
    );
  }
}
