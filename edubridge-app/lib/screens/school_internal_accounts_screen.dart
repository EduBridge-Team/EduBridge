import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/enrollment/enrollment_api_client.dart';
import '../services/schools/school_management_repository.dart';
import '../theme.dart';
import 'enrollment/enrollment_labels.dart';

class SchoolInternalAccountsScreen extends StatefulWidget {
  const SchoolInternalAccountsScreen({super.key, this.repository});
  final SchoolManagementRepository? repository;
  @override
  State<SchoolInternalAccountsScreen> createState() => _SchoolInternalAccountsScreenState();
}

class _SchoolInternalAccountsScreenState extends State<SchoolInternalAccountsScreen> {
  late SchoolManagementRepository _repository;
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController(), _username = TextEditingController(), _password = TextEditingController(), _reset = TextEditingController();
  List<Map> _accounts = [];
  String _role = 'teacher', _domain = '';
  int? _school, _cursor, _resetId;
  bool _loading = false, _saving = false, _authorized = false, _creating = false;
  int _version = 0;
  EnrollmentFailure? _failure;
  @override
  void initState() { super.initState(); _repository = widget.repository ?? SchoolManagementRepository(); _load(); }
  @override
  void didUpdateWidget(covariant SchoolInternalAccountsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) { _repository = widget.repository ?? SchoolManagementRepository(); _creating = false; _resetId = null; _password.clear(); _reset.clear(); _load(); }
  }
  @override
  void dispose() { ++_version; for (final controller in [_name, _username, _password, _reset]) { controller.dispose(); } super.dispose(); }
  Future<void> _load({bool more = false}) async {
    final version = ++_version;
    setState(() { _loading = true; _failure = null; if (!more) { _authorized = false; _accounts = []; } });
    try {
      final data = await _repository.client.get('/school/internal-identities?limit=100${more && _cursor != null ? '&after_id=$_cursor' : ''}');
      if (data['school_id'] is! int || data['identities'] is! List || data['internal_domain'] is! String ||
          (_repository.expectedSchoolId != null && data['school_id'] != _repository.expectedSchoolId)) {
        throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
      }
      if (!mounted || version != _version) return;
      setState(() { _school = data['school_id'] as int; _domain = data['internal_domain'] as String;
        final rows = (data['identities'] as List).whereType<Map>().toList(); _accounts = more ? [..._accounts, ...rows] : rows;
        _cursor = data['has_more'] == true ? data['next_after_id'] as int? : null; _authorized = true; });
    } on EnrollmentApiException catch (error) { if (mounted && version == _version) setState(() => _failure = error.failure); }
    catch (_) { if (mounted && version == _version) setState(() => _failure = EnrollmentFailure.invalidResponse); }
    finally { if (mounted && version == _version) setState(() => _loading = false); }
  }
  Future<void> _write(String path, Map<String, dynamic> body, {String method = 'POST'}) async {
    if (_saving || !_authorized || _school == null) return;
    setState(() { _saving = true; _failure = null; });
    try {
      await _repository.scoped(_school!).mutate(path, method, body);
      if (!mounted) return;
      setState(() { _creating = false; _resetId = null; });
      _name.clear(); _username.clear();
      await _load();
    } on EnrollmentApiException catch (error) { if (mounted) setState(() { _failure = error.failure; if (error.failure == EnrollmentFailure.forbidden || error.failure == EnrollmentFailure.session) { _authorized = false; _accounts = []; } }); }
    finally { _password.clear(); _reset.clear(); if (mounted) setState(() => _saving = false); }
  }
  Future<void> _toggle(Map account) async {
    final en = Localizations.localeOf(context).languageCode == 'en';
    final confirmed = await showDialog<bool>(context: context, builder: (dialog) => AlertDialog(
      title: Text(en ? 'Change account status?' : 'تغيير حالة الحساب؟'), content: Text(en ? 'Existing sessions will be invalidated.' : 'سيتم إلغاء جلسات الحساب القديمة.'),
      actions: [TextButton(onPressed: () => Navigator.pop(dialog, false), child: Text(en ? 'Cancel' : 'إلغاء')), FilledButton(onPressed: () => Navigator.pop(dialog, true), child: Text(en ? 'Confirm' : 'تأكيد'))],
    ));
    if (!mounted || confirmed != true) return;
    await _write('/school/internal-identities/${account['id']}', {'is_active': account['is_active'] == false || account['is_active'] == 0}, method: 'PATCH');
  }
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String t(String ar, String english) => en ? english : ar;
    final roles = {'teacher': t('معلم', 'Teacher'), 'student': t('طالب', 'Student'), 'staff': t('موظف', 'Staff')};
    return PopScope(canPop: !_saving, child: Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(t('الحسابات الداخلية', 'Internal accounts')),
      actions: [IconButton(onPressed: _loading || _saving ? null : _load, tooltip: t('تحديث', 'Refresh'), icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_loading || _saving) const LinearProgressIndicator(),
        if (_failure != null) Text(enrollmentFailureMessage(context.l10n, _failure!)),
        if (_authorized) ...[
          SelectableText(_domain),
          Text(t('معرّفات دخول داخلية وليست صناديق بريد إلكتروني.', 'Internal sign-in identifiers, not email mailboxes.')),
          OutlinedButton.icon(key: const ValueKey('internal-show-create'), onPressed: _saving ? null : () => setState(() { _creating = !_creating; _password.clear(); }), icon: const Icon(Icons.person_add_alt_1), label: Text(t('إضافة حساب', 'Add account'))),
          if (_creating) Form(key: _form, child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            TextFormField(key: const ValueKey('internal-name'), controller: _name, enabled: !_saving, maxLength: 190, decoration: InputDecoration(labelText: t('الاسم', 'Name')), validator: (v) => (v ?? '').trim().isEmpty ? t('الاسم مطلوب', 'Name is required') : null),
            TextFormField(key: const ValueKey('internal-username'), controller: _username, enabled: !_saving, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t('اسم المستخدم', 'Username')), validator: (v) => RegExp(r'^[a-z0-9][a-z0-9._-]{1,63}$').hasMatch((v ?? '').trim()) ? null : t('اسم غير صالح', 'Invalid username')),
            DropdownButtonFormField<String>(initialValue: _role, isExpanded: true, decoration: InputDecoration(labelText: t('نوع الحساب', 'Account type')), items: roles.entries.map((row) => DropdownMenuItem(value: row.key, child: Text(row.value))).toList(), onChanged: _saving ? null : (value) => setState(() => _role = value ?? 'teacher')),
            TextFormField(key: const ValueKey('internal-password'), controller: _password, enabled: !_saving, obscureText: true, autocorrect: false, enableSuggestions: false, decoration: InputDecoration(labelText: t('كلمة المرور', 'Password')), validator: (v) => (v ?? '').length >= 12 && (v ?? '').length <= 128 ? null : t('من 12 إلى 128 حرفًا', '12 to 128 characters')),
            FilledButton(key: const ValueKey('internal-create'), onPressed: _saving ? null : () { if (_form.currentState!.validate()) _write('/school/internal-identities', {'name': _name.text.trim(), 'username': _username.text.trim(), 'role': _role, 'password': _password.text}); }, child: Text(t('إنشاء الحساب', 'Create account'))),
          ])),
          if (!_loading && _accounts.isEmpty) Text(t('لا توجد حسابات بعد.', 'No accounts yet.')),
          for (final account in _accounts) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${account['name']} — ${roles[account['role']] ?? ''}'), SelectableText('${account['username']}@$_domain', textDirection: TextDirection.ltr),
            Text(account['is_active'] == false || account['is_active'] == 0 ? t('معطل', 'Inactive') : t('نشط', 'Active')),
            OutlinedButton(onPressed: _saving ? null : () => _toggle(account), child: Text(t('تفعيل أو تعطيل', 'Activate or deactivate'))),
            OutlinedButton(onPressed: _saving ? null : () => setState(() { _resetId = account['id'] as int; _reset.clear(); }), child: Text(t('إعادة تعيين كلمة المرور', 'Reset password'))),
            if (_resetId == account['id']) ...[
              TextField(controller: _reset, enabled: !_saving, obscureText: true, autocorrect: false, enableSuggestions: false, decoration: InputDecoration(labelText: t('كلمة المرور الجديدة', 'New password'))),
              FilledButton(onPressed: _saving ? null : () { if (_reset.text.length >= 12 && _reset.text.length <= 128) _write('/school/internal-identities/${account['id']}', {'password': _reset.text}, method: 'PATCH'); }, child: Text(t('تأكيد إعادة التعيين', 'Confirm password reset'))),
            ],
          ]))),
          if (_cursor != null) TextButton(onPressed: _loading || _saving ? null : () => _load(more: true), child: Text(t('عرض المزيد', 'Load more'))),
        ],
      ])))),
    ));
  }
}
