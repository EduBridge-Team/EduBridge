// شاشة تقدّم الطفل — ملخّص + تفاصيل التقدّم بكل درس
import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/api_service.dart';

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
      appBar: AppBar(title: Text('تقدّم ${widget.childName}')),
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
        // ListView حتى يعمل السحب للتحديث مع القائمة الفارغة
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
        const SizedBox(height: 16),
        const Text(
          'تفاصيل الدروس',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        ..._progress.map((p) => _buildProgressTile(p)),
      ],
    );
  }

  // بطاقات الملخّص: مكتمل / جاري / لم يبدأ / متوسّط النتيجة
  Widget _buildSummaryCards() {
    final done = int.tryParse('${_summary?['done'] ?? 0}') ?? 0;
    final inProgress = int.tryParse('${_summary?['in_progress'] ?? 0}') ?? 0;
    final notStarted = int.tryParse('${_summary?['not_started'] ?? 0}') ?? 0;
    final avgScore = _summary?['avg_score'];

    return Column(
      children: [
        Row(
          children: [
            _summaryCard('مكتمل', '$done', Icons.check_circle, Colors.green),
            const SizedBox(width: 8),
            _summaryCard(
                'قيد التنفيذ', '$inProgress', Icons.autorenew, Colors.orange),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            _summaryCard(
                'لم يبدأ', '$notStarted', Icons.hourglass_empty, Colors.grey),
            const SizedBox(width: 8),
            _summaryCard(
              'متوسّط النتيجة',
              avgScore != null ? '$avgScore%' : '—',
              Icons.star,
              const Color(0xFF2E7D6B),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, IconData icon, Color color) {
    return Expanded(
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
    );
  }

  // صف تفاصيل التقدّم بدرس واحد
  Widget _buildProgressTile(Map p) {
    final status = p['status'] ?? 'not_started';
    final statusInfo = _statusInfo(status);
    final score = p['score'];
    final completedAt = _formatDate(p['completed_at']);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
    );
  }

  // معلومات العرض لكل حالة (نص + أيقونة + لون)
  ({String label, IconData icon, Color color}) _statusInfo(String status) {
    switch (status) {
      case 'done':
        return (label: 'مكتمل', icon: Icons.check_circle, color: Colors.green);
      case 'in_progress':
        return (
          label: 'قيد التنفيذ',
          icon: Icons.autorenew,
          color: Colors.orange
        );
      default:
        return (
          label: 'لم يبدأ',
          icon: Icons.hourglass_empty,
          color: Colors.grey
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
