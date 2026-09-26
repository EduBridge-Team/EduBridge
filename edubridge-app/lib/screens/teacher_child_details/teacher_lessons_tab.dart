// lib/screens/teacher_child_details/teacher_lessons_tab.dart
part of 'teacher_child_details_screen.dart';

class _LessonsTab extends StatefulWidget {
  final int childId;
  final String childName;

  const _LessonsTab({required this.childId, required this.childName});

  @override
  State<_LessonsTab> createState() => _LessonsTabState();
}

class _LessonsTabState extends State<_LessonsTab>
    with AutomaticKeepAliveClientMixin {
  List _lessons = [];
  Map<int, Map> _progressMap = {};
  bool _loading = true;
  String? _error;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final responses = await Future.wait([
        ApiService.authGet('/children/${widget.childId}/lessons'),
        ApiService.authGet('/progress/child/${widget.childId}'),
      ]);

      if (!mounted) return;

      final lessons = ApiService.extractList(responses[0].body, 'lessons');
      final progress = ApiService.extractList(responses[1].body, 'progress');

      final progressMap = <int, Map>{};
      for (final p in progress) {
        final lid = p['lesson_id'];
        if (lid is int) progressMap[lid] = p as Map;
      }

      setState(() {
        _lessons = lessons;
        _progressMap = progressMap;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الدروس';
        _loading = false;
      });
    }
  }

  String _statusOf(int lessonId) {
    final p = _progressMap[lessonId];
    if (p == null) return 'not_started';
    return p['status']?.toString() ?? 'not_started';
  }

  ({String label, Color color, IconData icon}) _statusInfo(String status) {
    switch (status) {
      case 'done':
        return (label: 'مكتمل', color: AppColors.green, icon: AppIcons.check);
      case 'in_progress':
        return (
          label: 'قيد التنفيذ',
          color: AppColors.orange,
          icon: AppIcons.refresh,
        );
      default:
        return (label: 'لم يبدأ', color: AppColors.muted, icon: AppIcons.clock);
    }
  }

  int get _doneCount =>
      _lessons.where((l) => _statusOf(l['id'] as int) == 'done').length;
  int get _inProgressCount =>
      _lessons.where((l) => _statusOf(l['id'] as int) == 'in_progress').length;
  int get _notStartedCount =>
      _lessons.where((l) => _statusOf(l['id'] as int) == 'not_started').length;

  @override
  Widget build(BuildContext context) => buildView(context);

  Widget _buildSummaryCard() {
    final total = _lessons.length;
    final done = _doneCount;
    final percent = total > 0 ? (done / total) : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.headerGradient,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            height: 80,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 80,
                  height: 80,
                  child: CircularProgressIndicator(
                    value: percent,
                    strokeWidth: 8,
                    strokeCap: StrokeCap.round,
                    color: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.25),
                  ),
                ),
                Text(
                  '${(percent * 100).round()}%',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'إجمالي الدروس: $total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _summaryRow('مكتمل', _doneCount, AppColors.brandGreen),
                _summaryRow('قيد التنفيذ', _inProgressCount,
                    Colors.white.withValues(alpha: 0.9)),
                _summaryRow('لم يبدأ', _notStartedCount,
                    Colors.white.withValues(alpha: 0.85)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, int count, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: color, fontSize: 13)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonCard(Map lesson) {
    final c = JisrColors.of(context);
    final lessonId = lesson['id'] as int;
    final title = (lesson['title'] ?? '').toString();
    final status = _statusOf(lessonId);
    final info = _statusInfo(status);
    final progress = _progressMap[lessonId];
    final score = progress?['score'];
    final completedAt = progress?['completed_at']?.toString();

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: info.color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(info.icon, color: info.color, size: 24),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      )),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: info.color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          info.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: info.color,
                          ),
                        ),
                      ),
                      if (score != null) ...[
                        const SizedBox(width: 8),
                        Text(
                          '$score%',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors.greenDeep,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (completedAt != null && completedAt.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      'أُكمل: ${_formatDate(completedAt)}',
                      style: TextStyle(fontSize: 11, color: c.muted),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String raw) {
    try {
      final d = DateTime.parse(raw.replaceFirst(' ', 'T'));
      return '${d.day}/${d.month}/${d.year}';
    } catch (_) {
      return raw;
    }
  }
}