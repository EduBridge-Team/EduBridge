import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../model/institutions/institution_statistics.dart';
import '../services/institution_statistics_repository.dart';
import '../theme.dart';
import 'enrollment/enrollment_labels.dart';
import 'enrollment/enrollment_state.dart';
import 'institution_statistics/institution_statistics_content.dart';

class InstitutionStatisticsScreen extends StatefulWidget {
  const InstitutionStatisticsScreen({super.key, this.gateway});
  final InstitutionStatisticsGateway? gateway;
  @override
  State<InstitutionStatisticsScreen> createState() => _InstitutionStatisticsScreenState();
}
class _InstitutionStatisticsScreenState extends State<InstitutionStatisticsScreen> with WidgetsBindingObserver {
  late EnrollmentState<InstitutionStatistics> _state;
  DateTimeRange? _range;
  String _label(String ar, String en) => Localizations.localeOf(context).languageCode == 'en' ? en : ar;
  void _initialize() {
    final gateway = widget.gateway ?? InstitutionStatisticsRepository(), range = _range;
    _state = EnrollmentState(() => gateway.load(from: range?.start, to: range?.end))..reload();
  }
  void _filter(DateTimeRange? range) {
    _state.dispose(); setState(() { _range = range; _initialize(); });
  }
  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); _initialize(); }
  @override
  void didUpdateWidget(covariant InstitutionStatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) { _state.dispose(); _range = null; _initialize(); }
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _state.reload();
  }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); _state.dispose(); super.dispose(); }
  Future<void> _chooseRange() async {
    final controller = _state;
    final range = await showDateRangePicker(context: context, firstDate: DateTime(1900), lastDate: DateTime(2100, 12, 31), initialDateRange: _range);
    if (!mounted || !identical(controller, _state) || controller.loading || range == null) return;
    _filter(range);
  }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(animation: _state, builder: (context, _) {
    final data = _state.snapshot, local = MaterialLocalizations.of(context);
    return Scaffold(appBar: BrandAppBar(leading: const BackButton(), title: Text(_label('الإحصائيات الشاملة', 'Comprehensive Statistics')),
      actions: [IconButton(tooltip: context.l10n.enrollmentReload, onPressed: _state.loading ? null : _state.reload, icon: const Icon(Icons.refresh))]),
      body: RefreshIndicator(onRefresh: _state.reload, child: SafeArea(child: Center(child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1000), child: ListView(padding: const EdgeInsets.all(14),
          physics: const AlwaysScrollableScrollPhysics(), children: [
            OutlinedButton(key: const ValueKey('statistics-period'), onPressed: _state.loading ? null : _chooseRange,
              child: Text(_range == null ? _label('اختيار الفترة (كل التواريخ افتراضياً)', 'Choose period (all dates by default)')
                : '${local.formatMediumDate(_range!.start)} — ${local.formatMediumDate(_range!.end)}')),
            if (_range != null) TextButton(key: const ValueKey('statistics-clear'), onPressed: _state.loading ? null : () => _filter(null),
              child: Text(_label('مسح الفترة', 'Clear period'))),
            Text(_label('الفترة تخص جلسات الحضور وحالاته فقط. بقية الأعداد إجماليات حالية وليست إحصاءً تاريخياً للفترة.',
              'The period filters attendance sessions and statuses only. Other counts are current totals, not historical period statistics.')),
            if (_state.loading) const LinearProgressIndicator(),
            if (_state.error != null) Semantics(liveRegion: true, child: Text(enrollmentFailureMessage(context.l10n, _state.error!))),
            if (data != null) ...[
              Text('${_label('وقت جلب التقرير', 'Report fetched at')}: ${local.formatMediumDate(data.loadedAt)} ${local.formatTimeOfDay(TimeOfDay.fromDateTime(data.loadedAt))}'),
              InstitutionStatisticsContent(data: data),
            ],
          ]),
      )))),
    );
  });
}
