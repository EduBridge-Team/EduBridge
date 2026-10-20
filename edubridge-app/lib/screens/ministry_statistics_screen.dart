// screens/ministry/ministry_statistics_screen.dart
import 'package:flutter/material.dart';
import '../l10n/l10n.dart';
import '../services/api_service.dart';
import '../widgets/disability/disability_display.dart';
import '../theme.dart';

class MinistryStatisticsScreen extends StatefulWidget {
  const MinistryStatisticsScreen({super.key});

  @override
  State<MinistryStatisticsScreen> createState() =>
      _MinistryStatisticsScreenState();
}

class _MinistryStatisticsScreenState extends State<MinistryStatisticsScreen> {
  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _refresh() => _load(showLoader: false);

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) setState(() => _loading = true);
    try {
      final stats = await ApiService.getMinistryStatistics();
      if (!mounted) return;
      setState(() {
        _stats = stats;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: JisrAppBar(title: context.l10n.ministryStatsPageTitle),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final s = _stats ?? {};
    final byDisability = Map<String, dynamic>.from(
      s['by_disability_type'] ?? {},
    );
    final byAge = Map<String, dynamic>.from(s['by_age_group'] ?? {});

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            _bigStat(
              '${s['total_children'] ?? 0}',
              context.l10n.ministryStatsTotalChildren,
              Icons.child_care,
              AppColors.teal,
            ),
            const SizedBox(width: 8),
            _bigStat(
              '${s['active_children'] ?? 0}',
              context.l10n.ministryStatsActive,
              Icons.trending_up,
              AppColors.green,
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _bigStat(
              '${s['homework_completion_rate'] ?? 0}%',
              context.l10n.ministryStatsHomework,
              Icons.assignment_turned_in,
              AppColors.orange,
            ),
            const SizedBox(width: 8),
            _bigStat(
              '${s['learning_support_meetings_count'] ?? 0}',
              context.l10n.supportMeetingsTitle,
              Icons.school_outlined,
              AppColors.pink,
            ),
          ],
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.lessonByDisability,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...byDisability.entries
            .map((e) => _barRow(DisabilityDisplay.label(e.key, context.l10n), e.value, byDisability)),
        const SizedBox(height: 24),
        Text(
          context.l10n.ministryStatsAge,
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ...byAge.entries.map((e) => _barRow(e.key, e.value, byAge, numericLabel: true)),
      ],
    );
  }

  Widget _bigStat(String value, String label, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 36),
            const SizedBox(height: 8),
            FittedBox(fit: BoxFit.scaleDown, child: Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            )),
            Text(
              label,
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _barRow(String label, dynamic value, Map<String, dynamic> source, {bool numericLabel = false}) {
    final total = source.values
        .fold<int>(0, (sum, v) => sum + (int.tryParse('$v') ?? 0));
    final count = int.tryParse('$value') ?? 0;
    final pct = total == 0 ? 0.0 : count / total;
    final c = JisrColors.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(label, textDirection: numericLabel ? TextDirection.ltr : null)),
              Text(
                '$count (${(pct * 100).toStringAsFixed(0)}%)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: pct,
            minHeight: 10,
            color: AppColors.teal,
            backgroundColor: c.line,
            borderRadius: BorderRadius.circular(5),
          ),
        ],
      ),
    );
  }
}
