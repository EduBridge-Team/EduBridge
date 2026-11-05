import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../model/statistics/ministry_statistics.dart';
import '../services/ministry_statistics_repository.dart';
import '../services/enrollment/enrollment_api_client.dart';
import '../widgets/disability/disability_display.dart';
import '../theme.dart';
import 'enrollment/enrollment_labels.dart';

/// Ministry-wide aggregates. Unknown data must never be displayed as zero.
class MinistryStatisticsScreen extends StatefulWidget {
  const MinistryStatisticsScreen({super.key, this.gateway});
  final MinistryStatisticsGateway? gateway;

  @override
  State<MinistryStatisticsScreen> createState() => _MinistryStatisticsScreenState();
}

class _MinistryStatisticsScreenState extends State<MinistryStatisticsScreen>
    with WidgetsBindingObserver {
  late MinistryStatisticsGateway _gateway;
  MinistryStatistics? _stats;
  EnrollmentFailure? _failure;
  int _generation = 0;
  bool _loading = true;
  String _group = 'all';

  String t(String ar, String en) =>
      Localizations.localeOf(context).languageCode == 'en' ? en : ar;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _gateway = widget.gateway ?? MinistryStatisticsRepository();
    _load();
  }

  @override
  void didUpdateWidget(covariant MinistryStatisticsScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gateway != widget.gateway) {
      _gateway = widget.gateway ?? MinistryStatisticsRepository();
      _load();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _load();
  }

  @override
  void dispose() {
    ++_generation;
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<void> _load() async {
    final generation = ++_generation;
    setState(() {
      _loading = true;
      _failure = null;
      _stats = null;
    });
    try {
      final stats = await _gateway.load();
      if (mounted && generation == _generation) {
        setState(() => _stats = stats);
      }
    } on EnrollmentApiException catch (error) {
      if (mounted && generation == _generation) {
        setState(() => _failure = error.failure);
      }
    } catch (_) {
      if (mounted && generation == _generation) {
        setState(() => _failure = EnrollmentFailure.invalidResponse);
      }
    } finally {
      if (mounted && generation == _generation) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: JisrAppBar(
      title: context.l10n.ministryStatsPageTitle,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: t('تحديث', 'Refresh'),
          onPressed: _loading ? null : _load,
        ),
      ],
    ),
    body: RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          if (_loading) const LinearProgressIndicator(),
          if (_failure != null) ...[
            Text(
              enrollmentFailureMessage(context.l10n, _failure!),
              key: const ValueKey('ministry-statistics-error'),
            ),
            TextButton(
              onPressed: _loading ? null : _load,
              child: Text(t('إعادة المحاولة', 'Retry')),
            ),
          ],
          if (_stats != null) ...[
            Text(t(
              'مؤشرات إجمالية لكل الفترات. التصفية أدناه تغيّر تفاصيل العرض فقط.',
              'All-time aggregate indicators. Filters only change the displayed breakdown.',
            )),
            const SizedBox(height: 12),
            _metrics(_stats!),
            const SizedBox(height: 16),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final choice in {
                'all': t('الكل', 'All'),
                'disability': t('حسب الإعاقة', 'By disability'),
                'age': t('حسب العمر', 'By age'),
              }.entries)
                ChoiceChip(
                  key: ValueKey('ministry-group-${choice.key}'),
                  label: Text(choice.value),
                  selected: _group == choice.key,
                  onSelected: (_) => setState(() => _group = choice.key),
                ),
            ]),
            if (_group != 'age')
              _distribution(
                context.l10n.lessonByDisability,
                _stats!.disabilities,
                disability: true,
              ),
            if (_group != 'disability')
              _distribution(context.l10n.ministryStatsAge, _stats!.ages),
          ],
        ],
      ),
    ),
  );

  Widget _metrics(MinistryStatistics stats) {
    final metrics = [
      (key: 'total_children', label: context.l10n.ministryStatsTotalChildren,
        icon: Icons.child_care, color: AppColors.teal),
      (key: 'active_children', label: context.l10n.ministryStatsActive,
        icon: Icons.trending_up, color: AppColors.green),
      (key: 'homework_completion_rate', label: context.l10n.ministryStatsHomework,
        icon: Icons.assignment_turned_in, color: AppColors.orange),
      (key: 'learning_support_meetings_count', label: context.l10n.supportMeetingsTitle,
        icon: Icons.school_outlined, color: AppColors.pink),
    ];
    return Column(children: [
      for (var i = 0; i < metrics.length; i += 2) ...[
        Row(children: [
          for (var j = i; j < i + 2; j++) ...[
            if (j != i) const SizedBox(width: 8),
            _bigStat(
              keyName: metrics[j].key,
              value: stats.metrics[metrics[j].key],
              label: metrics[j].label,
              icon: metrics[j].icon,
              color: metrics[j].color,
            ),
          ],
        ]),
        if (i + 2 < metrics.length) const SizedBox(height: 8),
      ],
    ]);
  }

  Widget _bigStat({
    required String keyName,
    required num? value,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    final display = value == null
        ? t('غير متاح', 'Unavailable')
        : '$value${keyName == 'homework_completion_rate' ? '%' : ''}';
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 36),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(display,
              key: ValueKey('ministry-value-$keyName'),
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          Text(label, style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
        ]),
      ),
    );
  }

  Widget _distribution(String title, Map<String, int>? data,
      {bool disability = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 24),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (data == null)
          Text(t('غير متاح', 'Unavailable'))
        else if (data.isEmpty)
          Text(t('لا توجد بيانات لهذا التفصيل.', 'No data for this breakdown.'))
        else
          for (final row in data.entries)
            _barRow(
              disability ? DisabilityDisplay.label(row.key, context.l10n) : row.key,
              row.value, data,
              numericLabel: !disability,
            ),
      ],
    );
  }

  Widget _barRow(String label, int count, Map<String, int> source,
      {bool numericLabel = false}) {
    final total = source.values.fold<int>(0, (sum, count) => sum + count);
    final pct = total == 0 ? 0.0 : count / total;
    final c = JisrColors.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(child: Text(label,
            textDirection: numericLabel ? TextDirection.ltr : null)),
          Text('$count (${(pct * 100).toStringAsFixed(0)}%)',
            style: const TextStyle(fontWeight: FontWeight.bold)),
        ]),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: pct, minHeight: 10, color: AppColors.teal,
          backgroundColor: c.line, borderRadius: BorderRadius.circular(5),
        ),
      ]),
    );
  }
}
