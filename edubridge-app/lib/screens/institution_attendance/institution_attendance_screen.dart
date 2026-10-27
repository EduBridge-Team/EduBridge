import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_attendance.dart';
import '../../services/institution_attendance_repository.dart';
import '../../theme.dart';
import '../../services/institution_attendance_report_repository.dart';
import 'institution_attendance_report_screen.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/enrollment_state.dart';
import 'institution_attendance_content.dart';
import 'institution_attendance_create_screen.dart';
import 'institution_attendance_mark_screen.dart';

class InstitutionAttendanceScreen extends StatefulWidget {
  const InstitutionAttendanceScreen({super.key, required this.gateway, this.sessionId, this.date});
  final InstitutionAttendanceGateway gateway;
  final int? sessionId;
  final DateTime? date;
  @override
  State<InstitutionAttendanceScreen> createState() => _InstitutionAttendanceScreenState();
}
class _InstitutionAttendanceScreenState extends State<InstitutionAttendanceScreen> with WidgetsBindingObserver {
  late EnrollmentState<InstitutionAttendanceView> _state;
  DateTime? _date;
  void _initialize() {
    _date = widget.date;
    // Capture gateway and session identity so an obsolete read cannot use a new scope.
    final gateway = widget.gateway, sessionId = widget.sessionId;
    _state = EnrollmentState(() => gateway.load(date: _date, sessionId: sessionId))..reload();
  }
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }
  @override
  void didUpdateWidget(covariant InstitutionAttendanceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway || oldWidget.sessionId != widget.sessionId || oldWidget.date != widget.date) {
      _state.dispose();
      _initialize();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _state.dispose();
    super.dispose();
  }
  Future<void> _chooseDate() async {
    final controller = _state;
    final date = await showDatePicker(context: context, initialDate: _date ?? DateTime.now(),
      firstDate: DateTime(1900), lastDate: DateTime(2100, 12, 31));
    if (!mounted || date == null || !identical(controller, _state) || controller.loading) return;
    setState(() => _date = date);
    await controller.reload();
  }
  Future<void> _report() async {
    final gateway = widget.gateway;
    if (_state.loading || gateway is! InstitutionAttendanceReportGateway) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      InstitutionAttendanceReportScreen(gateway: gateway as InstitutionAttendanceReportGateway)));
  }
  Future<void> _create() async {
    final gateway = widget.gateway;
    final controller = _state;
    if (controller.loading || controller.snapshot == null || gateway is! InstitutionAttendanceWriter) return;
    final result = await Navigator.of(context).push<(int, DateTime)>(MaterialPageRoute(builder: (_) =>
      InstitutionAttendanceCreateScreen(writer: gateway, initialDate: _date)));
    if (!mounted || !identical(controller, _state) || result == null) return;
    setState(() => _date = result.$2);
    await controller.reload();
    if (mounted && identical(controller, _state)) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.enrollmentSaved)));
      await _open(result.$1);
    }
  }
  Future<void> _edit() async {
    final gateway = widget.gateway;
    final controller = _state;
    final session = controller.snapshot?.session;
    if (controller.loading || session == null || session.closed || gateway is! InstitutionAttendanceWriter) return;
    final saved = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) =>
      InstitutionAttendanceMarkScreen(writer: gateway, sessionId: session.id, date: session.date)));
    if (mounted && identical(controller, _state)) {
      await controller.reload();
      if (mounted && saved == true) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.enrollmentSaved)));
    }
  }
  Future<void> _open(int id) async {
    final controller = _state;
    if (controller.loading || controller.snapshot == null) return;
    await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) =>
      InstitutionAttendanceScreen(gateway: widget.gateway, sessionId: id, date: _date)));
    if (mounted && identical(controller, _state)) await controller.reload();
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = context.l10n;
    final data = _state.snapshot;
    return Scaffold(
      appBar: BrandAppBar(leading: const BackButton(),
        title: Text(widget.sessionId == null ? l.institutionAttendanceTitle : l.institutionAttendanceDetails),
        actions: [IconButton(tooltip: l.enrollmentReload, onPressed: _state.loading ? null : _state.reload,
          icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: _state.reload, child: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(padding: const EdgeInsets.all(16), physics: const AlwaysScrollableScrollPhysics(), children: [
          if (widget.sessionId == null) ...[
            if (widget.gateway is InstitutionAttendanceReportGateway) OutlinedButton(key: const ValueKey('attendance-open-report'),
              onPressed: _state.loading ? null : _report, child: Text(l.attendanceReportTitle)),
            OutlinedButton.icon(key: const ValueKey('attendance-date'), onPressed: _state.loading ? null : _chooseDate,
              icon: const Icon(Icons.calendar_today), label: Text(_date == null ? l.institutionAttendanceChooseDate
                : MaterialLocalizations.of(context).formatMediumDate(_date!))),
            if (_date != null) TextButton(key: const ValueKey('attendance-clear-date'),
              onPressed: _state.loading ? null : () async {
                setState(() => _date = null);
                await _state.reload();
              }, child: Text(l.institutionAttendanceAllDates)),
          ],
          if (data != null && widget.gateway is InstitutionAttendanceWriter) ...[
            if (widget.sessionId == null) FilledButton(key: const ValueKey('attendance-open-create'),
              onPressed: _state.loading ? null : _create, child: Text(l.institutionAttendanceCreate)),
            if (data.session != null && !data.session!.closed) FilledButton(key: const ValueKey('attendance-open-mark'),
              onPressed: _state.loading ? null : _edit, child: Text(l.institutionAttendanceMark)),
          ],
          if (_state.loading) const LinearProgressIndicator(),
          if (_state.error != null) Semantics(liveRegion: true,
            child: Text(enrollmentFailureMessage(l, _state.error!))),
          if (data != null) InstitutionAttendanceContent(data: data, onOpen: _state.loading ? null : _open),
        ]),
      )))),
    );
  });
}
