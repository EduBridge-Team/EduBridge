import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../model/institutions/institution_timetable_draft.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/institution_timetable_repository.dart';
import '../../theme.dart';
import '../enrollment/enrollment_labels.dart';
import 'institution_timetable_create_controller.dart';
import 'institution_timetable_create_fields.dart';

class InstitutionTimetableCreateScreen extends StatefulWidget {
  const InstitutionTimetableCreateScreen({super.key, required this.writer});
  final InstitutionTimetableCreator writer;
  @override
  State<InstitutionTimetableCreateScreen> createState() => _InstitutionTimetableCreateScreenState();
}
class _InstitutionTimetableCreateScreenState extends State<InstitutionTimetableCreateScreen> with WidgetsBindingObserver {
  late InstitutionTimetableCreateController _state;
  final _scroll = ScrollController();
  int _contextVersion = 0;
  void _initialize() { _state = InstitutionTimetableCreateController(widget.writer)..reload(); }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initialize(); }
  @override
  void didUpdateWidget(covariant InstitutionTimetableCreateScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.writer != widget.writer) { _state.dispose(); _contextVersion++; _initialize(); }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); _scroll.dispose(); super.dispose(); }
  Future<void> _save(TimetableEntryDraft draft) async {
    final controller = _state;
    if (!controller.canWrite) return;
    await controller.create(draft);
    if (!mounted || !identical(controller, _state)) return;
    if (controller.saved) { Navigator.pop(context, draft); }
    else if (_scroll.hasClients) { _scroll.jumpTo(0); }
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final l = context.l10n, data = _state.snapshot;
    return PopScope(canPop: !_state.busy, child: Scaffold(
      appBar: BrandAppBar(leading: const BackButton(), title: Text(l.timetableCreate),
        actions: [IconButton(tooltip: l.enrollmentReload, onPressed: _state.loading || _state.busy ? null : _state.reload,
          icon: const Icon(Icons.refresh))]),
      body: SafeArea(child: Center(child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 840),
        child: ListView(controller: _scroll, padding: const EdgeInsets.all(16), children: [
          if (_state.loading || _state.busy) const LinearProgressIndicator(),
          if (_state.error != null) Semantics(liveRegion: true, child: Text(_state.error == EnrollmentFailure.conflict
            ? l.timetableCreateConflict : enrollmentFailureMessage(l, _state.error!))),
          if (data != null) InstitutionTimetableCreateFields(key: ValueKey(_contextVersion), data: data,
            enabled: _state.canWrite, onSubmit: _save),
        ]),
      ))),
    ));
  });
}
