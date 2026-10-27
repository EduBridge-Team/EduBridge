import 'package:flutter/material.dart';
import '../../l10n/l10n.dart';
import '../../model/institutions/institution_attendance_report.dart';
import '../../services/institution_attendance_report_repository.dart';
import '../../theme.dart';
import '../academics/academic_choice_field.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/enrollment_state.dart';
import 'institution_attendance_report_content.dart';

class InstitutionAttendanceReportScreen extends StatefulWidget {
  const InstitutionAttendanceReportScreen({super.key, required this.gateway});
  final InstitutionAttendanceReportGateway gateway;
  @override
  State<InstitutionAttendanceReportScreen> createState() => _InstitutionAttendanceReportScreenState();
}
class _InstitutionAttendanceReportScreenState extends State<InstitutionAttendanceReportScreen> with WidgetsBindingObserver {
  late EnrollmentState<InstitutionAttendanceReport> _state;
  DateTimeRange? _range;
  int? _section;
  void _initialize() {
    final gateway = widget.gateway, range = _range, section = _section;
    _state = EnrollmentState(() => gateway.loadReport(from: range?.start, to: range?.end, sectionId: section))..reload();
  }
  void _filters(DateTimeRange? range, int? section) {
    _state.dispose(); setState(() { _range = range; _section = section; _initialize(); });
  }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initialize(); }
  @override
  void didUpdateWidget(covariant InstitutionAttendanceReportScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) { _state.dispose(); _range = null; _section = null; _initialize(); }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  Future<void> _chooseRange() async {
    final controller = _state;
    final range = await showDateRangePicker(context: context, firstDate: DateTime(1900), lastDate: DateTime(2100, 12, 31),
      initialDateRange: _range);
    if (mounted && identical(controller, _state) && !controller.loading && range != null) _filters(range, _section);
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = context.l10n, data = _state.snapshot, local = MaterialLocalizations.of(context);
    return Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(l.attendanceReportTitle),
      actions: [IconButton(tooltip: l.enrollmentReload, onPressed: _state.loading ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: _state.reload, child: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840), child: ListView(padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(), children: [
            OutlinedButton(key: const ValueKey('attendance-report-range'), onPressed: _state.loading ? null : _chooseRange,
              child: Text(_range == null ? l.attendanceReportPeriod : '${local.formatMediumDate(_range!.start)} — ${local.formatMediumDate(_range!.end)}')),
            if (_range != null || _section != null) TextButton(key: const ValueKey('attendance-report-clear'),
              onPressed: _state.loading ? null : () => _filters(null, null), child: Text(l.attendanceReportClear)),
            if (data != null) AcademicChoiceField(key: const ValueKey('attendance-report-section'), label: l.academicSections,
              options: {0: l.all, for (final s in data.academic.sections) s.id:
                '${data.academic.years.firstWhere((y) => y.id == s.yearId).name} — ${data.academic.grades.firstWhere((g) => g.id == s.gradeId).name} — ${s.name}'},
              value: _section ?? 0, requiredMessage: l.academicRequired,
              onChanged: _state.loading ? null : (v) => _filters(_range, v == 0 ? null : v)),
            if (_state.loading) const LinearProgressIndicator(),
            if (_state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(l, _state.error!))),
            if (data != null) InstitutionAttendanceReportContent(data: data),
          ]),
      )))),
    );
  });
}
