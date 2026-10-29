import 'package:flutter/material.dart';
import '../../../l10n/l10n.dart';
import '../../../services/enrollment/enrollment_api_client.dart';
import '../../../screens/enrollment/enrollment_labels.dart';
import '../../../screens/enrollment/enrollment_state.dart';
import '../../../screens/enrollment/parent_enrollment_screen.dart';
import '../../../screens/evaluation_history/evaluation_history_screen.dart';
import '../../../screens/weekly_report_screen.dart';
import '../../../theme.dart';
import '../data/notification_destination_repository.dart';
import '../domain/notification_destination.dart';

class NotificationChildDestinationScreen extends StatefulWidget {
  const NotificationChildDestinationScreen({super.key, required this.destination, this.gateway});
  final NotificationChildDestination destination;
  final NotificationDestinationGateway? gateway;
  @override
  State<NotificationChildDestinationScreen> createState() => _NotificationChildDestinationScreenState();
}
class _NotificationChildDestinationScreenState extends State<NotificationChildDestinationScreen> with WidgetsBindingObserver {
  late NotificationDestinationGateway _gateway;
  late EnrollmentState<NotificationChildDirectory> _state;
  bool _opening = false;
  bool _suspended = false;
  EnrollmentFailure? _openError;
  String label(String ar, String en) => Localizations.localeOf(context).languageCode == 'en' ? en : ar;
  void _initialize() {
    _gateway = widget.gateway ?? NotificationDestinationRepository();
    _state = EnrollmentState(_gateway.load);
    if (!_suspended) _state.reload();
  }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initialize(); }
  @override
  void didUpdateWidget(covariant NotificationChildDestinationScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway || oldWidget.destination != widget.destination) {
      _state.dispose(); _opening = false; _openError = null; _initialize();
    }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      setState(() {
        _suspended = false;
        _state.dispose();
        _opening = false;
        _openError = null;
        _initialize();
      });
    } else if (!_suspended) {
      setState(() {
        _suspended = true;
        _state.dispose();
        _opening = false;
        _openError = null;
        _state = EnrollmentState(_gateway.load);
      });
    }
  }
  Future<void> _reload() async { if (_opening || _suspended) return; setState(() => _openError = null); await _state.reload(); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  Future<void> _open(int childId) async {
    final controller = _state, gateway = _gateway, expected = _state.snapshot, destination = widget.destination;
    if (_opening || _suspended || !controller.canWrite || expected == null) return;
    setState(() { _opening = true; _openError = null; });
    try {
      final child = await gateway.authorize(expected, childId);
      if (!mounted || !identical(controller, _state)) return;
      final page = switch (destination) {
        NotificationChildDestination.enrollment => ParentEnrollmentScreen(childId: child.id, childName: child.name),
        NotificationChildDestination.evaluations => EvaluationHistoryScreen(childId: child.id, childName: child.name),
        NotificationChildDestination.weeklyReports => WeeklyReportScreen(childId: child.id, childName: child.name),
      };
      await Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => page));
      if (mounted && identical(controller, _state)) await controller.reload();
    } on EnrollmentApiException catch (e) {
      if (mounted && identical(controller, _state)) {
        await controller.reload();
        if (mounted && identical(controller, _state)) setState(() => _openError = e.failure);
      }
    } finally {
      if (mounted && identical(controller, _state)) setState(() => _opening = false);
    }
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final data = _state.loading || _suspended ? null : _state.snapshot;
    final title = switch (widget.destination) {
      NotificationChildDestination.enrollment => label('الالتحاق المدرسي', 'School enrollment'),
      NotificationChildDestination.evaluations => label('سجل التقييمات', 'Evaluation history'),
      NotificationChildDestination.weeklyReports => label('التقارير الأسبوعية', 'Weekly reports'),
    };
    return Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(title), actions: [
      IconButton(tooltip: context.l10n.enrollmentReload, onPressed: _state.loading || _opening || _suspended ? null : _reload, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: _reload, child: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 840), child: ListView(padding: const EdgeInsets.all(16),
          physics: const AlwaysScrollableScrollPhysics(), children: [
            Text(label('الإشعار لا يحدد الطفل. اختر الطفل لفتح سجله الحالي؛ لا يتم اختيار طفل تلقائياً.',
              'This notification does not identify a child. Choose a child to open their current records; no child is selected automatically.')),
            if (_state.loading || _opening) const LinearProgressIndicator(),
            if (_state.error != null || _openError != null) Semantics(liveRegion: true,
              child: Text(enrollmentFailureMessage(context.l10n, _openError ?? _state.error!))),
            if (data != null && _openError == null) ...[
              if (data.children.isEmpty) Text(label('لا يوجد أطفال متاحون لهذا الحساب.', 'No children are available for this account.')),
              for (final child in data.children) OutlinedButton(key: ValueKey('notification-child-${child.id}'),
                onPressed: _opening || _state.loading ? null : () => _open(child.id), child: Text(child.name)),
            ],
          ]),
      )))),
    );
  });
}
