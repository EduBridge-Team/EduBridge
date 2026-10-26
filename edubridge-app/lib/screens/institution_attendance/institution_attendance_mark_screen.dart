import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_attendance_draft.dart';
import '../../services/institution_attendance_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'institution_attendance_mark_form.dart';
import 'institution_attendance_write_controller.dart';

class InstitutionAttendanceMarkScreen extends StatefulWidget {
  const InstitutionAttendanceMarkScreen({super.key, required this.writer, required this.sessionId, required this.date});
  final InstitutionAttendanceWriter writer;
  final int sessionId;
  final DateTime date;
  @override
  State<InstitutionAttendanceMarkScreen> createState() => _InstitutionAttendanceMarkScreenState();
}
class _InstitutionAttendanceMarkScreenState extends State<InstitutionAttendanceMarkScreen> with WidgetsBindingObserver {
  late AttendanceMarkController _state;
  @override
  void initState() {
    super.initState();
    _state = AttendanceMarkController(widget.writer, widget.sessionId, widget.date)..reload();
    WidgetsBinding.instance.addObserver(this);
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose();
  }
  Future<void> _save(AttendanceEditorData expected, Map<int, AttendanceMark> marks, bool close) async {
    if (!_state.canWrite) return;
    await _state.save(expected, marks, close);
    if (mounted && _state.saved) Navigator.pop(context, true);
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = context.l10n, data = _state.snapshot;
    return PopScope(canPop: !_state.busy, child: Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(l.institutionAttendanceMark),
        actions: [IconButton(tooltip: l.enrollmentReload, onPressed: _state.loading || _state.busy ? null : _state.reload,
          icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(padding: const EdgeInsets.all(16), children: [
          if (_state.loading || _state.busy) const LinearProgressIndicator(),
          if (_state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(l, _state.error!))),
          if (data != null) AttendanceMarkForm(key: ObjectKey(data), data: data, enabled: _state.canWrite, onSave: _save),
        ]),
      ))),
    ));
  });
}
