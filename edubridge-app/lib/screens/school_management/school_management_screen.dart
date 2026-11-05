import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/schools/school_management_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/school_annual_promotion_screen.dart';
import '../enrollment/school_dashboard_screen.dart';
import '../school_internal_accounts_screen.dart';
import '../school_transfers/school_transfers_screen.dart';
import '../../services/transfers/school_transfer_repository.dart';
import '../../services/school_specialist_assignments_repository.dart';
import '../institution_specialists/school_specialists_screen.dart';
import '../specialist_schools/independent_specialist_employment_screen.dart';
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
  bool _independent = false;
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
    setState(() { _loading = true; _data = null; _failure = null; _independent = false; });
    try {
      final data = await _repository.context();
      var independent = false;
      if (data['role'] == 'director') {
        try {
          final identity = await _repository.client.get('/school/context');
          final bound = identity['school'];
          independent = bound is Map && bound['id'] == (data['school'] as Map)['id'] &&
              bound.containsKey('organization_id') && bound['organization_id'] == null;
        } on EnrollmentApiException { /* Fail closed, retain other school operations. */ }
      }
      if (mounted && version == _version) setState(() { _data = data; _independent = independent; });
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
    final school = _data?['school'] as Map?;
    final schoolId = school?['id'] as int?;
    final isDirector = _data?['role'] == 'director';
    final entries = <({String label, IconData icon, VoidCallback open})>[];
    if (schoolId != null) {
      final scoped = _repository.scoped(schoolId);
      if (isDirector) {
        entries.add((label: t('النطاق والنواب', 'Namespace and deputies'), icon: Icons.admin_panel_settings_outlined,
          open: () => _open(SchoolIdentitySettingsScreen(repository: scoped))));
        entries.add((label: t('الحسابات الداخلية', 'Internal accounts'), icon: Icons.manage_accounts_outlined,
          open: () => _open(SchoolInternalAccountsScreen(repository: scoped))));
        if (_independent) {
          entries.add((label: t('الكادر الوظيفي للمختصين', 'Specialist employment'), icon: Icons.person_add_alt_1_outlined,
            open: () => _open(SchoolSpecialistEmploymentScreen(schoolId: schoolId))));
          entries.add((label: t('أخصائيو المدرسة', 'School specialists'), icon: Icons.medical_services_outlined,
            open: () => _open(SchoolSpecialistsScreen(gateway:
              SchoolSpecialistAssignmentsRepository.independent(schoolId: schoolId, client: _repository.client)))));
        }
      }
      const operationIcons = <String, IconData>{
        'academic': Icons.school_outlined,
        'enrollment': Icons.groups_outlined,
        'attendance': Icons.fact_check_outlined,
        'timetable': Icons.calendar_month_outlined,
        'curriculum': Icons.menu_book_outlined,
        'reports': Icons.bar_chart_outlined,
      };
      for (final permission in permissions.where(labels.containsKey)) {
        entries.add((label: labels[permission]!, icon: operationIcons[permission] ?? Icons.grid_view_outlined,
          open: () => _open(SchoolOperationsScreen(repository: scoped, category: permission, schoolId: schoolId))));
      }
      if (permissions.contains('enrollment')) {
        entries.add((label: t('النقل بين المدارس', 'School transfers'), icon: Icons.swap_horiz_outlined,
          open: () => _open(SchoolTransfersScreen(gateway: SchoolTransferRepository(schoolId: schoolId, repository: scoped)))));
        entries.add((label: t('طلبات التسجيل', 'Enrollment requests'), icon: Icons.assignment_outlined,
          open: () => _open(const SchoolDashboardScreen())));
        entries.add((label: t('الترفيع السنوي', 'Annual progression'), icon: Icons.trending_up_outlined,
          open: () => _open(SchoolAnnualPromotionScreen(
            gateway: ManagedAcademicRepository(_repository.scoped(schoolId)), enableApproval: true))));
      }
    }
    return Scaffold(
      appBar: BrandAppBar(
        leading: const BackButton(),
        title: Text(t('إدارة المدرسة', 'School administration')),
        actions: [IconButton(onPressed: _loading ? null : _load,
          tooltip: t('تحديث', 'Refresh'), icon: const Icon(Icons.refresh))],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 840),
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              children: [
                if (_loading) const LinearProgressIndicator(),
                if (_failure != null) Text(enrollmentFailureMessage(context.l10n, _failure!)),
                if (school != null) ...[
                  Text('${school['name']}', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  LayoutBuilder(builder: (context, constraints) {
                    final columns = constraints.maxWidth < 560 ? 2 : constraints.maxWidth < 800 ? 3 : 4;
                    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
                    final tileHeight = 112.0 + (textScale - 1.0).clamp(0.0, 3.0) * 72.0;
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: columns,
                        mainAxisSpacing: 10,
                        crossAxisSpacing: 10,
                        mainAxisExtent: tileHeight,
                      ),
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        return OutlinedButton(
                          onPressed: entry.open,
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(entry.icon, size: 26),
                              const SizedBox(height: 8),
                              Text(entry.label, textAlign: TextAlign.center,
                                maxLines: 2, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                            ],
                          ),
                        );
                      },
                    );
                  }),
                ],
                if (widget.personalHome != null) ...[
                  const SizedBox(height: 12),
                  TextButton.icon(
                    onPressed: () => _open(widget.personalHome!()),
                    icon: const Icon(Icons.person_outline),
                    label: Text(t('حسابي الشخصي', 'My personal account')),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
