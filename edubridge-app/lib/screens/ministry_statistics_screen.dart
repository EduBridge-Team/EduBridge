import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../model/statistics/ministry_statistics.dart';
import '../services/ministry_statistics_repository.dart';
import '../services/enrollment/enrollment_api_client.dart';
import '../widgets/disability/disability_display.dart';
import '../theme.dart';
import 'enrollment/enrollment_labels.dart';

class MinistryStatisticsScreen extends StatefulWidget {
  const MinistryStatisticsScreen({super.key, this.gateway});
  final MinistryStatisticsGateway? gateway;
  @override
  State<MinistryStatisticsScreen> createState() =>
      _MinistryStatisticsScreenState();
}

class _MinistryStatisticsScreenState extends State<MinistryStatisticsScreen>
    with WidgetsBindingObserver {
  late MinistryStatisticsGateway _gateway;
  MinistryStatistics? _stats;
  EnrollmentFailure? _failure;
  bool _loading = true;
  int _generation = 0;
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
    _generation++;
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
      if (mounted && generation == _generation) setState(() => _stats = stats);
    } on EnrollmentApiException catch (e) {
      if (mounted && generation == _generation)
        setState(() => _failure = e.failure);
    } catch (_) {
      if (mounted && generation == _generation)
        setState(() => _failure = EnrollmentFailure.invalidResponse);
    } finally {
      if (mounted && generation == _generation)
        setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: BrandAppBar(
            leading: const BackButton(),
            title: Text(context.l10n.ministryStatsPageTitle),
            actions: [
              IconButton(
                  onPressed: _loading ? null : _load,
                  tooltip: t('تحديث', 'Refresh'),
                  icon: const Icon(Icons.refresh)),
            ]),
        body: RefreshIndicator(
            onRefresh: _load,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              children: [
                if (_loading) const LinearProgressIndicator(),
                if (_failure != null) ...[
                  Text(enrollmentFailureMessage(context.l10n, _failure!),
                      key: const ValueKey('ministry-statistics-error')),
                  TextButton(
                      onPressed: _loading ? null : _load,
                      child: Text(t('إعادة المحاولة', 'Retry'))),
                ],
                if (_stats != null) ...[
                  Text(t(
                      'مؤشرات إجمالية لكل الفترات. التصفية أدناه تغيّر نوع التفصيل المعروض فقط.',
                      'All-time aggregate indicators. The filter below changes only the displayed breakdown.')),
                  const SizedBox(height: 12),
                  _metrics(_stats!),
                  const SizedBox(height: 16),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    for (final item in {
                      'all': t('الكل', 'All'),
                      'disability': t('حسب الإعاقة', 'By disability'),
                      'age': t('حسب العمر', 'By age')
                    }.entries)
                      ChoiceChip(
                          key: ValueKey('ministry-group-${item.key}'),
                          label: Text(item.value),
                          selected: _group == item.key,
                          onSelected: (_) => setState(() => _group = item.key)),
                  ]),
                  if (_group != 'age')
                    _distribution(
                        context.l10n.lessonByDisability, _stats!.disabilities,
                        disability: true),
                  if (_group != 'disability')
                    _distribution(context.l10n.ministryStatsAge, _stats!.ages),
                ],
              ],
            )),
      );
  Widget _metrics(MinistryStatistics stats) {
    final labels = {
      'total_children': context.l10n.ministryStatsTotalChildren,
      'active_children': context.l10n.ministryStatsActive,
      'homework_completion_rate': context.l10n.ministryStatsHomework,
      'learning_support_meetings_count': context.l10n.supportMeetingsTitle
    };
    return LayoutBuilder(
        builder: (context, constraints) =>
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final entry in labels.entries)
                SizedBox(
                    width: (constraints.maxWidth - 8) / 2,
                    child: Card(
                        margin: EdgeInsets.zero,
                        child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(children: [
                              Text(
                                  stats.metrics[entry.key] == null
                                      ? t('غير متاح', 'Unavailable')
                                      : '${stats.metrics[entry.key]}${entry.key == 'homework_completion_rate' ? '%' : ''}',
                                  key: ValueKey('ministry-value-${entry.key}'),
                                  style:
                                      Theme.of(context).textTheme.titleLarge),
                              const SizedBox(height: 8),
                              Text(entry.value, textAlign: TextAlign.center),
                            ])))),
            ]));
  }

  Widget _distribution(String title, Map<String, int>? values,
      {bool disability = false}) {
    final total = values?.values.fold<int>(0, (sum, value) => sum + value) ?? 0;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      const SizedBox(height: 20),
      Text(title, style: Theme.of(context).textTheme.titleLarge),
      if (values == null)
        Text(t('غير متاح', 'Unavailable'))
      else if (values.isEmpty)
        Text(t('لا توجد بيانات لهذا التفصيل.', 'No data for this breakdown.'))
      else
        for (final row in values.entries)
          Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(disability
                        ? DisabilityDisplay.label(row.key, context.l10n)
                        : row.key),
                    Text(total == 0
                        ? '${row.value}'
                        : '${row.value} (${(row.value * 100 / total).toStringAsFixed(0)}%)'),
                    LinearProgressIndicator(
                        value: total == 0 ? 0 : row.value / total,
                        minHeight: 8),
                  ])),
    ]);
  }
}
