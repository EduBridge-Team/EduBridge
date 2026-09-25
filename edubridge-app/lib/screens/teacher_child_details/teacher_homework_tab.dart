// lib/screens/teacher_child_details/teacher_homework_tab.dart
part of 'teacher_child_details_screen.dart';

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
            .map((e) =>
                Homework.fromJson(Map<String, dynamic>.from(e as Map)))
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
          child: RefreshIndicator(onRefresh: _load, child: _buildBody()),
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
          _filterChip('الكل', 'all', _homeworks.length, AppColors.brandBlue),
          const SizedBox(width: 6),
          _filterChip('لم يُسلَّم', 'pending', _pendingCount, AppColors.orange),
          const SizedBox(width: 6),
          _filterChip('للتصحيح', 'submitted', _submittedCount, AppColors.brandTeal),
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
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
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
            const Icon(AppIcons.error, size: 64, color: AppColors.red),
            const SizedBox(height: 16),
            Text(_error!,
                style: const TextStyle(color: AppColors.red, fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              icon: const Icon(AppIcons.refresh),
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
          Icon(AppIcons.homework,
              size: 80, color: JisrColors.of(context).muted),
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
        statusIcon = AppIcons.warning;
      } else {
        statusColor = AppColors.orange;
        statusLabel = 'لم يُسلَّم بعد';
        statusIcon = AppIcons.clock;
      }
    } else if (isGraded) {
      statusColor = AppColors.green;
      statusLabel = 'مُصحّح';
      statusIcon = AppIcons.check;
    } else {
      statusColor = AppColors.brandTeal;
      statusLabel = 'بانتظار التصحيح';
      statusIcon = AppIcons.clock;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildCardHeader(hw, statusColor, statusLabel, statusIcon, c),
            if (hw.description.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(hw.description,
                  style: TextStyle(fontSize: 14, color: c.body, height: 1.4)),
            ],
            const SizedBox(height: 10),
            Divider(color: c.line, height: 1),
            const SizedBox(height: 10),
            _buildMetaRow(hw, isOverdue, c),
            if (submission != null) ...[
              const SizedBox(height: 12),
              _buildSubmissionBox(submission, isGraded, c),
            ],
            const SizedBox(height: 12),
            _buildActionButton(
                hw, submission, isPending, isGraded, statusColor),
          ],
        ),
      ),
    );
  }

  Widget _buildCardHeader(Homework hw, Color statusColor, String statusLabel,
      IconData statusIcon, JisrColors c) {
    return Row(
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
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
    );
  }

  Widget _buildMetaRow(Homework hw, bool isOverdue, JisrColors c) {
    return Row(
      children: [
        Icon(
          AppIcons.calendar,
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
          const Icon(AppIcons.lesson, size: 15, color: AppColors.brandBlue),
          const SizedBox(width: 4),
          Text(
            hw.subject!,
            style: const TextStyle(fontSize: 12, color: AppColors.brandBlue),
          ),
        ],
      ],
    );
  }

  Widget _buildSubmissionBox(
      HomeworkSubmission submission, bool isGraded, JisrColors c) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isGraded
            ? AppColors.green.withValues(alpha: 0.08)
            : AppColors.brandTeal.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isGraded
              ? AppColors.green.withValues(alpha: 0.3)
              : AppColors.brandTeal.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                submission.isLate ? AppIcons.clock : AppIcons.check,
                size: 16,
                color: submission.isLate ? AppColors.orange : AppColors.green,
              ),
              const SizedBox(width: 6),
              Text(
                submission.isLate ? 'سُلِّم متأخراً' : 'سُلِّم في الوقت',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: submission.isLate ? AppColors.orange : AppColors.green,
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
            Text('إجابة الطالب:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: c.muted,
                )),
            const SizedBox(height: 2),
            Text(submission.textAnswer!,
                style: TextStyle(fontSize: 13, color: c.body, height: 1.4)),
          ],
          if (submission.grade != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(AppIcons.starFilled,
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
              'ملاحظتك: ${submission.feedback}',
              style: TextStyle(
                fontSize: 12,
                color: c.body,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(
    Homework hw,
    HomeworkSubmission? submission,
    bool isPending,
    bool isGraded,
    Color statusColor,
  ) {
    if (isPending) {
      return SizedBox(
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
          icon: const Icon(AppIcons.notifications, size: 18),
          label: const Text('لم يقم الطالب بالتسليم بعد'),
          onPressed: null,
        ),
      );
    }
    if (!isGraded) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.green,
            foregroundColor: Colors.white,
            minimumSize: const Size(0, 46),
          ),
          icon: const Icon(AppIcons.grade, size: 20),
          label: const Text(
            'تصحيح الحل',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
          onPressed: () => _openGradeSheet(hw, submission!),
        ),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandBlue,
          minimumSize: const Size(0, 44),
        ),
        icon: const Icon(AppIcons.edit, size: 18),
        label: const Text('تعديل التصحيح'),
        onPressed: () => _openGradeSheet(hw, submission!),
      ),
    );
  }
}