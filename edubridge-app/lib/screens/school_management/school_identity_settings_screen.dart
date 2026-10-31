import 'dart:convert';
import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_management_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';

class SchoolIdentitySettingsScreen extends StatefulWidget {
  const SchoolIdentitySettingsScreen({super.key, required this.repository});
  final SchoolManagementRepository repository;
  @override
  State<SchoolIdentitySettingsScreen> createState() => _SchoolIdentitySettingsScreenState();
}
class _SchoolIdentitySettingsScreenState extends State<SchoolIdentitySettingsScreen> {
  final _domain = TextEditingController(), _email = TextEditingController();
  Map<String, dynamic>? _domainData;
  List<Map> _deputies = [];
  final _permissions = <int, Set<String>>{};
  bool _busy = false, _ack = false;
  EnrollmentFailure? _failure;
  @override
  void initState() { super.initState(); _load(); }
  @override
  void dispose() { _domain.dispose(); _email.dispose(); super.dispose(); }
  Future<void> _load() async {
    setState(() { _busy = true; _failure = null; _domainData = null; _deputies = []; });
    try {
      final domain = await widget.repository.client.get('/school/internal-domain');
      final deputies = await widget.repository.client.get('/school/deputies');
      if (mounted) setState(() { _domainData = domain; _deputies = (deputies['deputies'] as List).whereType<Map>().toList(); _permissions.clear(); for (final deputy in _deputies) { final raw = deputy['permissions']; final value = raw is String ? jsonDecode(raw) : raw; _permissions[deputy['id'] as int] = value is List ? value.whereType<String>().toSet() : <String>{}; } });
    } on EnrollmentApiException catch (error) { if (mounted) setState(() => _failure = error.failure); }
    catch (_) { if (mounted) setState(() => _failure = EnrollmentFailure.invalidResponse); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _mutate(String path, Map<String, dynamic> body, {String method = 'POST', int success = 201}) async {
    if (_busy) return;
    setState(() { _busy = true; _failure = null; });
    try {
      await widget.repository.mutate(path, method, body, success: success);
      _email.clear(); _permissions.clear();
      if (mounted) await _load();
    } on EnrollmentApiException catch (error) { if (mounted) setState(() => _failure = error.failure); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String t(String ar, String english) => en ? english : ar;
    final choices = {'academic': t('الهيكل الأكاديمي', 'Academic structure'), 'enrollment': t('التسجيل والترفيع', 'Enrollment and progression'), 'attendance': t('الحضور', 'Attendance'), 'timetable': t('الجدول', 'Timetable'), 'curriculum': t('المنهاج', 'Curriculum'), 'reports': t('التقارير', 'Reports')};
    return Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(t('النطاق والنواب', 'Namespace and deputies')),
      actions: [IconButton(onPressed: _busy ? null : _load, tooltip: t('تحديث', 'Refresh'), icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 720), child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_busy) const LinearProgressIndicator(),
        if (_failure != null) Text(enrollmentFailureMessage(context.l10n, _failure!)),
        if (_domainData != null) ...[
          if (_domainData!['confirmed_at'] != null) SelectableText('${_domainData!['internal_domain']}') else ...[
            TextField(controller: _domain, enabled: !_busy, textDirection: TextDirection.ltr, decoration: InputDecoration(labelText: t('النطاق الداخلي مثل schoolname.edubridge', 'Namespace such as schoolname.edubridge'))),
            CheckboxListTile(value: _ack, onChanged: _busy ? null : (value) => setState(() => _ack = value == true), title: Text(t('أفهم أن النطاق دائم ولا يمكن تغييره.', 'I understand that the namespace is permanent.'))),
            FilledButton(onPressed: _busy || !_ack ? null : () => _mutate('/school/internal-domain/confirm', {'internal_domain': _domain.text.trim().toLowerCase()}, success: 200), child: Text(t('تأكيد النطاق', 'Confirm namespace'))),
          ],
          const SizedBox(height: 24),
          TextField(controller: _email, enabled: !_busy, keyboardType: TextInputType.emailAddress, decoration: InputDecoration(labelText: t('بريد حساب النائب الموثّق', 'Verified deputy account email'))),
          FilledButton(onPressed: _busy ? null : () => _mutate('/school/deputies', {'user_email': _email.text.trim().toLowerCase()}), child: Text(t('تعيين نائب دون صلاحيات تلقائية', 'Appoint deputy without automatic permissions'))),
          for (final deputy in _deputies) Card(child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('${deputy['name']} — ${deputy['email']}'),
            for (final permission in choices.entries) CheckboxListTile(value: _permissions[deputy['id']]?.contains(permission.key) ?? false,
              title: Text(permission.value), onChanged: _busy ? null : (value) => setState(() { final selected = _permissions.putIfAbsent(deputy['id'] as int, () => <String>{}); if (value == true) { selected.add(permission.key); } else { selected.remove(permission.key); } })),
            FilledButton(onPressed: _busy ? null : () => _mutate('/school/deputies/${deputy['id']}/permissions', {'permissions': (_permissions[deputy['id']] ?? <String>{}).toList()}, method: 'PATCH'), child: Text(t('حفظ الصلاحيات المختارة', 'Save selected permissions'))),
            TextButton(onPressed: _busy ? null : () => _mutate('/school/deputies/${deputy['id']}', {}, method: 'DELETE'), child: Text(t('سحب التكليف', 'Revoke appointment'))),
          ]))),
        ],
      ])))),
    );
  }
}
