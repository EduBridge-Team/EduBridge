// شاشة تقدّم الطفل — ملخّص + تفاصيل التقدّم بكل درس
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../services/tts_service.dart';
import '../theme.dart';
import '../widgets/listen_button.dart';
import '../widgets/speakable.dart';

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
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  @override
  void dispose() {
    TtsService.instance.stop(); // إيقاف القراءة عند مغادرة الشاشة
    super.dispose();
  }

  // جلب الملخّص والتفاصيل معاً
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
        final data = jsonDecode(
            summaryRes.statusCode != 200 ? summaryRes.body : detailsRes.body);
        setState(() {
          _error = data['error'] ?? 'تعذّر جلب التقدّم';
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
    return Scaffold(
      appBar: JisrAppBar(
        title: 'تقدّم ${widget.childName}',
        actions: const [
          // تفعيل وضع القراءة باللمس (accessibility)
          ListenButton(),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadProgress,
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_error!,
                style: const TextStyle(fontSize: 16, color: Colors.red)),
            const SizedBox(height: 16),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 28),
                label:
                    const Text('إعادة المحاولة', style: TextStyle(fontSize: 18)),
                onPressed: _loadProgress,
              ),
            ),
          ],
        ),
      );
    }
    if (_progress.isEmpty) {
      return ListView(
        // قائمة قابلة للتمرير حتى يعمل السحب للتحديث مع القائمة الفارغة — ListView
        children: const [
          SizedBox(height: 120),
          Icon(Icons.insights, size: 72, color: Colors.grey),
          SizedBox(height: 16),
          Center(
            child: Text('لا يوجد تقدّم مسجّل بعد',
                style: TextStyle(fontSize: 18)),
          ),
        ],
      );
    }

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildSummaryCards(),
        const SizedBox(height: 20),
        _buildRewardsSection(),
        const SizedBox(height: 20),
        const Text(
          'تفاصيل الدروس',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._progress.map((p) => _buildProgressTile(p)),
      ],
    );
  }

  // ===== المكافآت: نجوم لكل درس مكتمل + شارات إنجاز =====
  Widget _buildRewardsSection() {
    final c = JisrColors.of(context);
    final done = int.tryParse('${_summary?['done'] ?? 0}') ?? 0;
    final inProgress = int.tryParse('${_summary?['in_progress'] ?? 0}') ?? 0;
    final notStarted = int.tryParse('${_summary?['not_started'] ?? 0}') ?? 0;
    final total = done + inProgress + notStarted;
    final avgScore = double.tryParse('${_summary?['avg_score'] ?? ''}');

    // الشارات: (أيقونة، اسم، شرط التحقيق، تلميح عند القفل)
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
      (
        emoji: '🎓',
        title: 'أكملتها كلها!',
        earned: total > 0 && done == total,
        hint: 'أكمل كل الدروس',
      ),
      if (avgScore != null)
        (
          emoji: '💯',
          title: 'العلامة الرائعة',
          earned: avgScore >= 90,
          hint: 'متوسّط ٩٠٪ فأعلى',
        ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'المكافآت 🎉',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),

        // شريط النجوم: نجمة لكل درس مكتمل (قابل للقراءة باللمس)
        Speakable(
          radius: 18,
          text:
              'جمع ${widget.childName} $done ${done == 1 ? 'نجمة' : done == 2 ? 'نجمتين' : done >= 3 && done <= 10 ? 'نجوم' : 'نجمة'}، نجمة عن كل درس مكتمل',
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: c.tintYellow,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 30)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'جمع ${widget.childName} $done ${done == 1 ? 'نجمة' : done == 2 ? 'نجمتين' : done >= 3 && done <= 10 ? 'نجوم' : 'نجمة'} — نجمة عن كل درس مكتمل',
                    style: TextStyle(
                      fontSize: 15.5,
                      fontWeight: FontWeight.w600,
                      color: c.onTint,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),

        // بطاقات الشارات
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.55,
          children: badges.map((b) => _buildBadgeCard(b)).toList(),
        ),
      ],
    );
  }

  // بطاقة شارة واحدة: ملوّنة عند التحقيق، رمادية بقفل قبل ذلك
  Widget _buildBadgeCard(
      ({String emoji, String title, bool earned, String hint}) badge) {
    final c = JisrColors.of(context);
    // نص القراءة باللمس: اسم الشارة وحالتها (محققة/مقفلة + تلميح)
    final spoken = badge.earned
        ? 'شارة ${badge.title}، محققة'
        : 'شارة ${badge.title}، مقفلة${badge.hint.isNotEmpty ? '، ${badge.hint}' : ''}';
    return Speakable(
      radius: 18,
      text: spoken,
      child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: badge.earned ? c.tintGreen : c.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: badge.earned ? AppColors.green : c.line,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            badge.earned ? badge.emoji : '🔒',
            style: TextStyle(
              fontSize: 28,
              color: badge.earned ? null : c.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            badge.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: badge.earned ? c.success : c.muted,
            ),
          ),
          if (!badge.earned && badge.hint.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              badge.hint,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11.5, color: c.muted),
            ),
          ],
        ],
      ),
      ),
    );
  }

  // بطاقات الملخّص: مكتمل / جاري / لم يبدأ / متوسّط النتيجة
  Widget _buildSummaryCards() {
    final c = JisrColors.of(context);
    final done = int.tryParse('${_summary?['done'] ?? 0}') ?? 0;
    final inProgress = int.tryParse('${_summary?['in_progress'] ?? 0}') ?? 0;
    final notStarted = int.tryParse('${_summary?['not_started'] ?? 0}') ?? 0;
    final avgScore = _summary?['avg_score'];

    // حلقة الإنجاز: نسبة الدروس المكتملة من الإجمالي
    final total = done + inProgress + notStarted;
    final percent = total > 0 ? done / total : 0.0;

    return Column(
      children: [
        // ===== حلقة إنجاز محفّزة (قابلة للقراءة باللمس) =====
        Speakable(
          text: 'نسبة الإنجاز ${(percent * 100).round()} بالمئة',
          radius: 70,
          child: SizedBox(
          width: 130,
          height: 130,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 130,
                height: 130,
                child: CircularProgressIndicator(
                  value: percent,
                  strokeWidth: 11,
                  strokeCap: StrokeCap.round,
                  color: AppColors.green,
                  backgroundColor: c.line,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '${(percent * 100).round()}%',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                  Text(
                    'الإنجاز',
                    style: TextStyle(fontSize: 13, color: c.muted),
                  ),
                ],
              ),
            ],
          ),
        ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            _summaryCard(
                'مكتمل', '$done', Icons.check_circle, c.success),
            const SizedBox(width: 8),
            _summaryCard('قيد التنفيذ', '$inProgress', Icons.autorenew,
                AppColors.orangeDeep),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _summaryCard('لم يبدأ', '$notStarted', Icons.hourglass_empty,
                c.muted),
            const SizedBox(width: 8),
            _summaryCard(
              'متوسّط النتيجة',
              avgScore != null ? '$avgScore%' : '—',
              Icons.star,
              Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      // قابل للقراءة باللمس: يقرأ العنوان وقيمته
      child: Speakable(
        text: '$label: $value',
        child: Card(
          child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: Column(
            children: [
              Icon(icon, size: 36, color: color),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(fontSize: 15),
                  textAlign: TextAlign.center),
            ],
          ),
          ),
        ),
      ),
    );
  }

  // صف تفاصيل التقدّم بدرس واحد
  Widget _buildProgressTile(Map p) {
    final status = p['status'] ?? 'not_started';
    final statusInfo = _statusInfo(status);
    final score = p['score'];
    final completedAt = _formatDate(p['completed_at']);

    // نص القراءة باللمس: عنوان الدرس وحالته ونتيجته
    final spoken = [
      (p['lesson_title'] ?? '').toString(),
      statusInfo.label,
      if (score != null) 'النتيجة $score بالمئة',
      if (completedAt != null) 'أُكمل في $completedAt',
    ].where((s) => s.isNotEmpty).join('، ');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Speakable(
        text: spoken,
        child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Icon(statusInfo.icon, size: 34, color: statusInfo.color),
        title: Text(
          p['lesson_title'] ?? '',
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            [
              statusInfo.label,
              if (score != null) 'النتيجة: $score%',
              if (completedAt != null) 'أُكمل في: $completedAt',
            ].join(' • '),
            style: TextStyle(fontSize: 15, color: statusInfo.color),
          ),
        ),
      ),
      ),
    );
  }

  // معلومات العرض لكل حالة (نص + أيقونة + لون)
  ({String label, IconData icon, Color color}) _statusInfo(String status) {
    switch (status) {
      case 'done':
        return (
          label: 'مكتمل',
          icon: Icons.check_circle,
          color: JisrColors.of(context).success
        );
      case 'in_progress':
        return (
          label: 'قيد التنفيذ',
          icon: Icons.autorenew,
          color: AppColors.orangeDeep
        );
      default:
        return (
          label: 'لم يبدأ',
          icon: Icons.hourglass_empty,
          color: JisrColors.of(context).muted
        );
    }
  }

  // تنسيق التاريخ بشكل مقروء (يوم/شهر/سنة)
  String? _formatDate(dynamic value) {
    if (value == null) return null;
    final date = DateTime.tryParse('$value');
    if (date == null) return null;
    return '${date.day}/${date.month}/${date.year}';
  }
}
