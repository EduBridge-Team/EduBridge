// lib/screens/child_progress_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import '../app_icons.dart';
import '../services/api_service.dart';
import '../services/reward_service.dart';
import '../theme.dart';
import '../utils/adaptive_helper.dart';
import '../widgets/accessibility/adaptive_card.dart';
import '../widgets/accessibility/adaptive_text.dart';
import '../widgets/accessibility/adaptive_wrapper.dart';

class ChildProgressScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const ChildProgressScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<ChildProgressScreen> createState() => _ChildProgressScreenState();
}

class _ChildProgressScreenState extends State<ChildProgressScreen> {
  Map? _summary;
  List _progress = [];
  int _stars = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgress();
    _loadStars();
  }

  Future<void> _loadStars() async {
    final stars = await RewardService.instance.getStars(widget.childId);
    if (!mounted) return;
    setState(() => _stars = stars);
  }

  Future<void> _loadProgress() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final responses = await Future.wait([
        ApiService.authGet('/progress/child/${widget.childId}/summary'),
        ApiService.authGet('/progress/child/${widget.childId}'),
      ]);

      final summaryRes = responses[0];
      final detailsRes = responses[1];

      if (summaryRes.statusCode == 200 && detailsRes.statusCode == 200) {
        setState(() {
          _summary = jsonDecode(summaryRes.body)['summary'];
          _progress = jsonDecode(detailsRes.body)['progress'] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'تعذّر جلب التقدّم';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'تعذّر الاتصال بالسيرفر';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdaptiveWrapper(
      screenTitle: 'تقدّم ${widget.childName}',
      child: Scaffold(
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              gradient: AppColors.headerGradient,
            ),
          ),
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(AppIcons.progress, color: Colors.white),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  'تقدّم ${widget.childName}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          centerTitle: true,
          actions: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  const Icon(AppIcons.starFilled,
                      size: 18, color: AppColors.yellow),
                  const SizedBox(width: 4),
                  Text(
                    '$_stars',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadProgress,
          child: _buildBody(),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(AdaptiveHelper.spacing * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(AppIcons.error, size: 60, color: AppColors.red),
              SizedBox(height: AdaptiveHelper.spacing),
              AdaptiveText(
                _error!,
                textAlign: TextAlign.center,
                color: AppColors.red,
              ),
            ],
          ),
        ),
      );
    }

    if (_progress.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              AppIcons.progress,
              size: AdaptiveHelper.iconSize * 2,
              color: AppColors.muted,
            ),
            SizedBox(height: AdaptiveHelper.spacing),
            const AdaptiveText(
              'لا يوجد تقدّم مسجّل بعد',
              type: AdaptiveTextType.subtitle,
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: EdgeInsets.all(AdaptiveHelper.spacing),
      children: [
        _buildSummaryCards(),
        SizedBox(height: AdaptiveHelper.spacing * 2),
        _buildRewardsSection(),
        SizedBox(height: AdaptiveHelper.spacing * 2),
        const AdaptiveText(
          'تفاصيل الدروس',
          type: AdaptiveTextType.title,
        ),
        SizedBox(height: AdaptiveHelper.spacing),
        ..._progress.map((p) => _buildProgressTile(p)),
      ],
    );
  }

  Widget _buildSummaryCards() {
    final done = int.tryParse('${_summary?['done'] ?? 0}') ?? 0;
    final inProgress = int.tryParse('${_summary?['in_progress'] ?? 0}') ?? 0;
    final notStarted = int.tryParse('${_summary?['not_started'] ?? 0}') ?? 0;
    final avgScore = _summary?['avg_score'];

    final total = done + inProgress + notStarted;
    final percent = total > 0 ? done / total : 0.0;

    return Column(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 14,
                  strokeCap: StrokeCap.round,
                  color: AppColors.green,
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(percent * 100).round()}%',
                    style: TextStyle(
                      fontSize: AdaptiveHelper.titleFontSize + 10,
                      fontWeight: FontWeight.bold,
                      color: AdaptiveHelper.textColor(context),
                    ),
                  ),
                  const AdaptiveText(
                    'الإنجاز',
                    type: AdaptiveTextType.caption,
                  ),
                ],
              ),
            ],
          ),
        ),
        SizedBox(height: AdaptiveHelper.spacing),
        Row(
          children: [
            _summaryCard('مكتمل', '$done', AppIcons.check, AppColors.green),
            SizedBox(width: AdaptiveHelper.spacing / 2),
            _summaryCard('قيد التنفيذ', '$inProgress', AppIcons.refresh,
                AppColors.orangeDeep),
          ],
        ),
        SizedBox(height: AdaptiveHelper.spacing / 2),
        Row(
          children: [
            _summaryCard('لم يبدأ', '$notStarted', AppIcons.clock,
                AppColors.muted),
            SizedBox(width: AdaptiveHelper.spacing / 2),
            _summaryCard(
              'متوسّط',
              avgScore != null ? '$avgScore%' : '—',
              AppIcons.starFilled,
              AppColors.yellow,
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(
      String label, String value, IconData icon, Color color) {
    return Expanded(
      child: AdaptiveCard(
        child: Column(
          children: [
            Icon(icon, size: AdaptiveHelper.iconSize, color: color),
            SizedBox(height: AdaptiveHelper.spacing / 4),
            Text(
              value,
              style: TextStyle(
                fontSize: AdaptiveHelper.titleFontSize,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            AdaptiveText(label, type: AdaptiveTextType.caption),
          ],
        ),
      ),
    );
  }

  Widget _buildRewardsSection() {
    final done = int.tryParse('${_summary?['done'] ?? 0}') ?? 0;

    final badges = <({String emoji, String title, bool earned, String hint})>[
      (
        emoji: '🌟',
        title: 'البداية المشرقة',
        earned: done >= 1,
        hint: 'أكمل أول درس',
      ),
      (
        emoji: '🏅',
        title: 'نجم المثابرة',
        earned: done >= 5,
        hint: done >= 5 ? '' : 'بقي ${5 - done} دروس',
      ),
      (
        emoji: '🏆',
        title: 'بطل الدروس',
        earned: done >= 10,
        hint: done >= 10 ? '' : 'بقي ${10 - done} دروس',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AdaptiveText(
          'المكافآت',
          type: AdaptiveTextType.title,
        ),
        SizedBox(height: AdaptiveHelper.spacing),

        AdaptiveCard(
          child: Row(
            children: [
              Icon(AppIcons.starFilled,
                  size: AdaptiveHelper.iconSize, color: AppColors.yellow),
              SizedBox(width: AdaptiveHelper.spacing / 2),
              Expanded(
                child: AdaptiveText(
                  'جمع ${widget.childName} $_stars نجمة',
                  type: AdaptiveTextType.body,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: AdaptiveHelper.spacing),

        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: AdaptiveHelper.spacing / 2,
          crossAxisSpacing: AdaptiveHelper.spacing / 2,
          childAspectRatio: 1.4,
          children: badges.map((b) => _buildBadgeCard(b)).toList(),
        ),
      ],
    );
  }

  Widget _buildBadgeCard(
      ({String emoji, String title, bool earned, String hint}) badge) {
    return AdaptiveCard(
      backgroundColor: badge.earned
          ? AppColors.green.withValues(alpha: 0.1)
          : AdaptiveHelper.cardColor(context),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            badge.earned ? AppIcons.trophy : AppIcons.lock,
            size: AdaptiveHelper.iconSize + 8,
            color: badge.earned ? AppColors.green : AppColors.muted,
          ),
          SizedBox(height: AdaptiveHelper.spacing / 4),
          AdaptiveText(
            badge.title,
            type: AdaptiveTextType.caption,
            fontWeight: FontWeight.bold,
            textAlign: TextAlign.center,
            color: badge.earned ? AppColors.green : null,
          ),
          if (!badge.earned && badge.hint.isNotEmpty)
            AdaptiveText(
              badge.hint,
              type: AdaptiveTextType.label,
              textAlign: TextAlign.center,
            ),
        ],
      ),
    );
  }

  Widget _buildProgressTile(Map p) {
    final status = p['status'] ?? 'not_started';
    final statusInfo = _statusInfo(status);
    final score = p['score'];
    final title = (p['lesson_title'] ?? '').toString();

    return Padding(
      padding: EdgeInsets.only(bottom: AdaptiveHelper.spacing / 2),
      child: AdaptiveCard(
        child: Row(
          children: [
            Icon(
              statusInfo.icon,
              size: AdaptiveHelper.iconSize,
              color: statusInfo.color,
            ),
            SizedBox(width: AdaptiveHelper.spacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AdaptiveText(
                    title,
                    type: AdaptiveTextType.body,
                    fontWeight: FontWeight.bold,
                  ),
                  AdaptiveText(
                    statusInfo.label +
                        (score != null ? ' • النتيجة: $score%' : ''),
                    type: AdaptiveTextType.caption,
                    color: statusInfo.color,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  ({String label, IconData icon, Color color}) _statusInfo(String status) {
    switch (status) {
      case 'done':
        return (
          label: 'مكتمل',
          icon: AppIcons.check,
          color: AppColors.green,
        );
      case 'in_progress':
        return (
          label: 'قيد التنفيذ',
          icon: AppIcons.refresh,
          color: AppColors.orangeDeep,
        );
      default:
        return (
          label: 'لم يبدأ',
          icon: AppIcons.clock,
          color: AppColors.muted,
        );
    }
  }
}