import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_management_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/school_annual_promotion_screen.dart';
import '../enrollment/school_dashboard_screen.dart';
import '../school_internal_accounts_screen.dart';
import 'school_identity_settings_screen.dart';
import 'school_operations_screen.dart';

class SchoolManagementScreen extends StatefulWidget {
  const SchoolManagementScreen({super.key, this.repository, this.personalHome});
  final SchoolManagementRepository? repository;
  final Widget Function()? personalHome;
  @override
  State<SchoolManagementScreen> createState() => _SchoolManagementScreenState();
}

class _SchoolManagementScreenState extends State<SchoolManagementScreen> with WidgetsBindingObserver {
  late SchoolManagementRepository _repository;
  Map<String, dynamic>? _data;
  EnrollmentFailure? _failure;
  int _version = 0;
  bool _loading = false;
  @override
  void initState() { super.initState(); _repository = widget.repository ?? SchoolManagementRepository(); WidgetsBinding.instance.addObserver(this); _load(); }
  @override
  void didUpdateWidget(covariant SchoolManagementScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.repository != widget.repository) { _repository = widget.repository ?? SchoolManagementRepository(); _load(); }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) _load(); }
  @override
  void dispose() { ++_version; WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  Future<void> _load() async {
    final version = ++_version;
    setState(() { _loading = true; _data = null; _failure = null; });
    try {
      final data = await _repository.context();
      if (mounted && version == _version) setState(() => _data = data);
    } on EnrollmentApiException catch (error) {
      if (mounted && version == _version) setState(() => _failure = error.failure);
    } catch (_) { if (mounted && version == _version) setState(() => _failure = EnrollmentFailure.network); }
    finally { if (mounted && version == _version) setState(() => _loading = false); }
  }
  void _open(Widget page) => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page)).then((_) { if (mounted) _load(); });
  @override
  Widget build(BuildContext context) {
    final en = Localizations.localeOf(context).languageCode == 'en';
    String t(String ar, String english) => en ? english : ar;
    final permissions = (_data?['permissions'] as List? ?? []).whereType<String>().toList();
    final labels = <String, String>{'academic': t('الهيكل والمعلمون', 'Structure and teachers'), 'enrollment': t('الطلاب', 'Students'),
      'attendance': t('الحضور', 'Attendance'), 'timetable': t('الجدول', 'Timetable'), 'curriculum': t('المنهاج', 'Curriculum'), 'reports': t('التقارير', 'Reports')};
    return Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(t('إدارة المدرسة', 'School administration')),
      actions: [IconButton(onPressed: _loading ? null : _load, tooltip: t('تحديث', 'Refresh'), icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840), child: ListView(padding: const EdgeInsets.all(16), children: [
        if (_loading) const LinearProgressIndicator(),
        if (_failure != null) Text(enrollmentFailureMessage(context.l10n, _failure!)),
        if (_data != null) ...[
          Text('${(_data!['school'] as Map)['name']}', style: Theme.of(context).textTheme.headlineSmall),
          if (_data!['role'] == 'director') ...[
            OutlinedButton.icon(onPressed: () => _open(SchoolIdentitySettingsScreen(repository: _repository.scoped((_data!['school'] as Map)['id'] as int))), icon: const Icon(Icons.admin_panel_settings_outlined), label: Text(t('النطاق والنواب', 'Namespace and deputies'))),
            OutlinedButton.icon(onPressed: () => _open(SchoolInternalAccountsScreen(repository: _repository.scoped((_data!['school'] as Map)['id'] as int))), icon: const Icon(Icons.manage_accounts_outlined), label: Text(t('الحسابات الداخلية', 'Internal accounts'))),
          ],
          for (final permission in permissions.where(labels.containsKey))
            OutlinedButton(onPressed: () => _open(SchoolOperationsScreen(repository: _repository.scoped((_data!['school'] as Map)['id'] as int), category: permission, schoolId: (_data!['school'] as Map)['id'] as int)), child: Text(labels[permission]!)),
          if (permissions.contains('enrollment')) ...[
            OutlinedButton(onPressed: () => _open(const SchoolDashboardScreen()), child: Text(t('طلبات التسجيل', 'Enrollment requests'))),
            FilledButton(onPressed: () => _open(SchoolAnnualPromotionScreen(gateway: ManagedAcademicRepository(_repository.scoped((_data!['school'] as Map)['id'] as int)), enableApproval: true)), child: Text(t('الترفيع السنوي', 'Annual progression'))),
          ],
        ],
        if (widget.personalHome != null) TextButton(onPressed: () => _open(widget.personalHome!()), child: Text(t('حسابي الشخصي', 'My personal account'))),
      ])))),
    );
  }
}
