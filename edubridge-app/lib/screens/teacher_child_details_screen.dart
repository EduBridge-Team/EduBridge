// شاشة تفاصيل الطفل — للمعلم
// تبويبان: الواجبات (مع تصحيح) + الدروس (مع حالة كل درس)
import 'package:flutter/material.dart';
import '../model/homework_model.dart';
import '../services/api_service.dart';
import '../theme.dart';

class TeacherChildDetailsScreen extends StatefulWidget {
  final int childId;
  final String childName;

  const TeacherChildDetailsScreen({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<TeacherChildDetailsScreen> createState() =>
      _TeacherChildDetailsScreenState();
}

class _TeacherChildDetailsScreenState
    extends State<TeacherChildDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.headerGradient,
          ),
        ),
        title: Text(
          widget.childName,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle:
              const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          tabs: const [
            Tab(icon: Icon(Icons.assignment, size: 22), text: 'الواجبات'),
            Tab(icon: Icon(Icons.menu_book, size: 22), text: 'الدروس'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _HomeworkTab(
            childId: widget.childId,
            childName: widget.childName,
          ),
          _LessonsTab(
            childId: widget.childId,
            childName: widget.childName,
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Tab 1: الواجبات
// ═══════════════════════════════════════════════════════════
class _HomeworkTab extends StatefulWidget {
  final int childId;
  final String childName;

  const _HomeworkTab({required this.childId, required this.childName});

  @override
  State<_HomeworkTab> createState() => _HomeworkTabState();
}

class _HomeworkTabState extends State<_HomeworkTab>
    with AutomaticKeepAliveClientMixin {
  List<Homework> _homeworks = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

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
      final list = await ApiService.getHomeworks(childId: widget.childId);
      if (!mounted) return;
      setState(() {
        _homeworks = list
            .map((e) => Homework.fromJson(
                Map<String, dynamic>.from(e as Map)))
            .toList();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'تعذّر تحميل الواجبات';
        _loading = false;
      });
    }
  }

  HomeworkSubmission? _submissionFor(Homework hw) {
    for (final s in hw.submissions) {
      if (s.childId == widget.childId) return s;
    }
    return null;
  }

  List<Homework> get _filtered {
    switch (_filter) {
      case 'pending':
        return _homeworks.where((h) => _submissionFor(h) == null).toList();
      case 'submitted':
        return _homeworks.where((h) {
          final s = _submissionFor(h);
          return s != null && s.grade == null;
        }).toList();
      case 'graded':
        return _homeworks.where((h) {
          final s = _submissionFor(h);
          return s != null && s.grade != null;
        }).toList();
      default:
        return _homeworks;
    }
  }

  int get _pendingCount =>
      _homeworks.where((h) => _submissionFor(h) == null).length;

  int get _submittedCount => _homeworks.where((h) {
        final s = _submissionFor(h);
        return s != null && s.grade == null;
      }).length;

  int get _gradedCount => _homeworks.where((h) {
        final s = _submissionFor(h);
        return s != null && s.grade != null;
      }).length;

  Future<void> _openGradeSheet(
      Homework hw, HomeworkSubmission submission) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _GradeHomeworkSheet(
        homework: hw,
        submission: submission,
      ),
    );
    if (result == true) _load();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Column(
      children: [
        _buildFilterBar(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _load,
            child: _buildBody(),
          ),
        ),
      ],
    );
  }

  Widget _buildFilterBar() {
    final c = JisrColors.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      color: c.card,
      child: Row(
        children: [
          _filterChip('الكل', 'all', _homeworks.length, AppColors.navy),
          const SizedBox(width: 6),
          _filterChip(
              'لم يُسلَّم', 'pending', _pendingCount, AppColors.orange),
          const SizedBox(width: 6),
          _filterChip('للتصحيح', 'submitted', _submittedCount,
              AppColors.teal),
          const SizedBox(width: 6),
          _filterChip('مُصحّح', 'graded', _gradedCount, AppColors.green),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String value, int count, Color color) {
    final selected = _filter == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filter = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: selected
                ? color.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? color : Colors.grey.shade300,
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.bold,
                  color: selected ? color : Colors.grey.shade600,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 3),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected ? color : Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    final list = _filtered;
    if (list.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 80),
          Icon(
            Icons.assignment_outlined,
            size: 80,
            color: JisrColors.of(context).muted,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              _homeworks.isEmpty
                  ? 'لا توجد واجبات لهذا الطفل'
                  : 'لا توجد واجبات في هذا التصنيف',
              style: TextStyle(
                fontSize: 17,
                color: JisrColors.of(context).muted,
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: list.length,
      itemBuilder: (context, i) => _buildHomeworkCard(list[i]),
    );
  }

  Widget _buildHomeworkCard(Homework hw) {
    final c = JisrColors.of(context);
    final submission = _submissionFor(hw);
    final isPending = submission == null;
    final isGraded = submission?.grade != null;
    final isOverdue = hw.isOverdue && isPending;

    Color statusColor;
    String statusLabel;
    IconData statusIcon;

    if (isPending) {
      if (isOverdue) {
        statusColor = AppColors.red;
        statusLabel = 'متأخر — لم يُسلَّم';
        statusIcon = Icons.warning_amber;
      } else {
        statusColor = AppColors.orange;
        statusLabel = 'لم يُسلَّم بعد';
        statusIcon = Icons.hourglass_empty;
      }
    } else if (isGraded) {
      statusColor = AppColors.green;
      statusLabel = 'مُصحّح ✓';
      statusIcon = Icons.check_circle;
    } else {
      statusColor = AppColors.teal;
      statusLabel = 'بانتظار التصحيح';
      statusIcon = Icons.pending_actions;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    hw.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 14, color: statusColor),
                      const SizedBox(width: 4),
                      Text(
                        statusLabel,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hw.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                hw.description,
                style: TextStyle(fontSize: 14, color: c.body, height: 1.4),
              ),
            ],
            const SizedBox(height: 10),
            Divider(color: c.line, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 15,
                  color: isOverdue ? AppColors.red : c.muted,
                ),
                const SizedBox(width: 4),
                Text(
                  'التسليم: ${hw.dueDate.day}/${hw.dueDate.month}/${hw.dueDate.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isOverdue ? AppColors.red : c.muted,
                    fontWeight: isOverdue ? FontWeight.bold : null,
                  ),
                ),
                if (hw.subject != null && hw.subject!.isNotEmpty) ...[
                  const SizedBox(width: 12),
                  const Icon(Icons.book,
                      size: 15, color: AppColors.tealDeep),
                  const SizedBox(width: 4),
                  Text(
                    hw.subject!,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.tealDeep),
                  ),
                ],
              ],
            ),
            if (submission != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isGraded
                      ? AppColors.green.withValues(alpha: 0.08)
                      : AppColors.teal.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isGraded
                        ? AppColors.green.withValues(alpha: 0.3)
                        : AppColors.teal.withValues(alpha: 0.3),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          submission.isLate
                              ? Icons.schedule
                              : Icons.check_circle,
                          size: 16,
                          color: submission.isLate
                              ? AppColors.orange
                              : AppColors.green,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          submission.isLate
                              ? 'سُلِّم متأخراً'
                              : 'سُلِّم في الوقت',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: submission.isLate
                                ? AppColors.orange
                                : AppColors.green,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '${submission.submittedAt.day}/${submission.submittedAt.month} '
                          '${submission.submittedAt.hour}:${submission.submittedAt.minute.toString().padLeft(2, '0')}',
                          style: TextStyle(fontSize: 11, color: c.muted),
                        ),
                      ],
                    ),
                    if (submission.textAnswer != null &&
                        submission.textAnswer!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'إجابة الطالب:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: c.muted,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        submission.textAnswer!,
                        style: TextStyle(
                            fontSize: 13, color: c.body, height: 1.4),
                      ),
                    ],
                    if (submission.grade != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.star,
                              color: AppColors.yellow, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            'الدرجة: ${submission.grade}/100',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: AppColors.greenDeep,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (submission.feedback != null &&
                        submission.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        '💬 ملاحظتك: ${submission.feedback}',
                        style: TextStyle(
                          fontSize: 12,
                          color: c.body,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (isPending)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.orange,
                    side: BorderSide(
                      color: AppColors.orange.withValues(alpha: 0.5),
                      width: 1.5,
                    ),
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.notifications_active, size: 18),
                  label: const Text('لم يقم الطالب بالتسليم بعد'),
                  onPressed: null,
                ),
              )
            else if (!isGraded)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 46),
                  ),
                  icon: const Icon(Icons.grade, size: 20),
                  label: const Text(
                    'تصحيح الحل',
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: () => _openGradeSheet(hw, submission),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.tealDeep,
                    minimumSize: const Size(0, 44),
                  ),
                  icon: const Icon(Icons.edit, size: 18),
                  label: const Text('تعديل التصحيح'),
                  onPressed: () => _openGradeSheet(hw, submission),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Tab 2: الدروس — حالة كل درس
// ═══════════════════════════════════════════════════════════
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
    final s = p['status']?.toString() ?? 'not_started';
    return s;
  }

  ({String label, Color color, IconData icon}) _statusInfo(String status) {
    switch (status) {
      case 'done':
        return (
          label: 'مكتمل',
          color: AppColors.green,
          icon: Icons.check_circle,
        );
      case 'in_progress':
        return (
          label: 'قيد التنفيذ',
          color: AppColors.orange,
          icon: Icons.autorenew,
        );
      default:
        return (
          label: 'لم يبدأ',
          color: AppColors.muted,
          icon: Icons.hourglass_empty,
        );
    }
  }

  int get _doneCount =>
      _lessons.where((l) => _statusOf(l['id'] as int) == 'done').length;

  int get _inProgressCount => _lessons
      .where((l) => _statusOf(l['id'] as int) == 'in_progress')
      .length;

  int get _notStartedCount =>
      _lessons.where((l) => _statusOf(l['id'] as int) == 'not_started').length;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: Colors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              onPressed: _load,
            ),
          ],
        ),
      );
    }

    if (_lessons.isEmpty) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          Icon(
            Icons.menu_book_outlined,
            size: 80,
            color: JisrColors.of(context).muted,
          ),
          const SizedBox(height: 16),
          Center(
            child: Text(
              'لا توجد دروس متاحة لهذا الطفل',
              style: TextStyle(
                fontSize: 17,
                color: JisrColors.of(context).muted,
              ),
            ),
          ),
        ],
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          _buildSummaryCard(),
          const SizedBox(height: 16),
          const Text(
            'تفاصيل الدروس',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          ..._lessons.map((l) => _buildLessonCard(l)),
        ],
      ),
    );
  }

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
                    backgroundColor:
                        Colors.white.withValues(alpha: 0.25),
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
                _summaryRow('✅ مكتمل', _doneCount, Colors.white),
                _summaryRow('🕒 قيد التنفيذ', _inProgressCount,
                    Colors.white.withValues(alpha: 0.9)),
                _summaryRow('⏳ لم يبدأ', _notStartedCount,
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
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
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
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: c.heading,
                    ),
                  ),
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
                          '⭐ $score%',
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

// ═══════════════════════════════════════════════════════════
//  BottomSheet التصحيح
// ═══════════════════════════════════════════════════════════
class _GradeHomeworkSheet extends StatefulWidget {
  final Homework homework;
  final HomeworkSubmission submission;

  const _GradeHomeworkSheet({
    required this.homework,
    required this.submission,
  });

  @override
  State<_GradeHomeworkSheet> createState() => _GradeHomeworkSheetState();
}

class _GradeHomeworkSheetState extends State<_GradeHomeworkSheet> {
  final _gradeCtrl = TextEditingController();
  final _feedbackCtrl = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.submission.grade != null) {
      _gradeCtrl.text = widget.submission.grade.toString();
    }
    if (widget.submission.feedback != null) {
      _feedbackCtrl.text = widget.submission.feedback!;
    }
  }

  @override
  void dispose() {
    _gradeCtrl.dispose();
    _feedbackCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final gradeText = _gradeCtrl.text.trim();
    if (gradeText.isEmpty) {
      setState(() => _error = 'الدرجة مطلوبة');
      return;
    }
    final grade = int.tryParse(gradeText);
    if (grade == null || grade < 0 || grade > 100) {
      setState(() => _error = 'الدرجة يجب أن تكون بين 0 و 100');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    try {
      final ok = await ApiService.gradeHomework(
        submissionId: widget.submission.id,
        grade: grade,
        feedback: _feedbackCtrl.text.trim().isEmpty
            ? null
            : _feedbackCtrl.text.trim(),
      );

      if (!mounted) return;

      if (ok) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ تم حفظ التصحيح وإرساله للطالب'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _error = 'فشل حفظ التصحيح';
          _saving = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _saving = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: c.card,
          borderRadius: BorderRadius.circular(24),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.grade, color: AppColors.green, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'تصحيح: ${widget.homework.title}',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: c.tintTeal,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '📝 إجابة الطالب:',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: c.onTint,
                      ),
                    ),
                    const SizedBox(height: 6),
                    if (widget.submission.textAnswer != null &&
                        widget.submission.textAnswer!.isNotEmpty)
                      Text(
                        widget.submission.textAnswer!,
                        style: TextStyle(
                            fontSize: 14,
                            color: c.onTint,
                            height: 1.5),
                      )
                    else
                      Text(
                        '— لم يكتب إجابة نصية —',
                        style: TextStyle(
                          fontSize: 13,
                          color: c.muted,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _gradeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الدرجة (0-100) *',
                  prefixIcon: Icon(Icons.star),
                  hintText: 'مثال: 85',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _feedbackCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'ملاحظتك للطالب (اختياري)',
                  prefixIcon: Icon(Icons.comment),
                  alignLabelWithHint: true,
                  hintText: 'مثال: عمل ممتاز، لكن راجع النقطة الثانية',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _error!,
                    style:
                        const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                      child: const Text('إلغاء'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        minimumSize: const Size(0, 48),
                      ),
                      icon: _saving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check),
                      label: Text(
                        _saving ? 'جارٍ الحفظ...' : 'حفظ التصحيح',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _saving ? null : _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}