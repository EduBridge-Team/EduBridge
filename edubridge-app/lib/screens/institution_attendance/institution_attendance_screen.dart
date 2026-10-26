import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_attendance.dart';
import '../../services/institution_attendance_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import '../enrollment/enrollment_state.dart';
import 'institution_attendance_content.dart';

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
            OutlinedButton.icon(key: const ValueKey('attendance-date'), onPressed: _state.loading ? null : _chooseDate,
              icon: const Icon(Icons.calendar_today), label: Text(_date == null ? l.institutionAttendanceChooseDate
                : MaterialLocalizations.of(context).formatMediumDate(_date!))),
            if (_date != null) TextButton(key: const ValueKey('attendance-clear-date'),
              onPressed: _state.loading ? null : () async {
                setState(() => _date = null);
                await _state.reload();
              }, child: Text(l.institutionAttendanceAllDates)),
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
