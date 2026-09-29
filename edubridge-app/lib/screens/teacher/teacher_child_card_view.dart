part of 'teacher_screen.dart';

extension _TeacherChildCardView on _TeacherChildCard {
  Widget buildView(BuildContext context) {
    final name = (child['name'] ?? '').toString();
    final status = child['status'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          // ═══ الرأس ═══
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 26,
              backgroundColor: color,
              child: Text(
                name.isNotEmpty ? name.characters.first : '؟',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            title: Text(
              name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: c.heading,
              ),
            ),
            subtitle: _buildSubtitle(status, c),
            trailing: const Icon(Icons.chevron_left),
            onTap: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TeacherChildDetailsScreen(
                    childId: child['id'],
                    childName: name,
                  ),
                ),
              );
              onReload();
            },
          ),

          // ═══ الإجراءات ═══
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildActionButtons(context, child),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  الإجراءات الأساسية + Bottom Sheet
  // ═══════════════════════════════════════════════════════════
  Widget _buildActionButtons(BuildContext context, Map child) {
    return Column(
      children: [
        // ─── الصف الأساسي: [اكتب تقرير] + [التقدّم] ───
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: AppColors.brandTeal,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(AppIcons.edit, size: 18),
                label: const Text(
                  'اكتب تقرير',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateWeeklyReportScreen(
                        childId: child['id'],
                        childName: (child['name'] ?? '').toString(),
                      ),
                    ),
                  );
                  onReload();
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: AppColors.brandBlue,
                  side: const BorderSide(
                      color: AppColors.brandBlue, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(AppIcons.progress, size: 18),
                label: const Text(
                  'التقدّم',
                  style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.bold),
                ),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ChildProgressScreen(
                      childId: child['id'],
                      childName: (child['name'] ?? '').toString(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // ─── زر "أفعال أخرى" ───
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 46),
              foregroundColor: AppColors.brandBlue,
              side: const BorderSide(
                  color: AppColors.brandBlue, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            icon: const Icon(Icons.more_horiz, size: 20),
            label: const Text(
              'أفعال أخرى',
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _openTeacherChildActionsSheet(context, child),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  Bottom Sheet — للأفعال الثانوية
  // ═══════════════════════════════════════════════════════════
  Future<void> _openTeacherChildActionsSheet(
    BuildContext context,
    Map child,
  ) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TeacherChildActionsSheet(
        childName: (child['name'] ?? '').toString(),
      ),
    );

    if (!context.mounted || action == null) return;

    switch (action) {
      case 'plan':
        await _openApprovedPlan(context, child);
        break;
      case 'reports':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => WeeklyReportScreen(
              childId: child['id'],
              childName: (child['name'] ?? '').toString(),
            ),
          ),
        );
        break;
      case 'case_discussion':
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CaseDiscussionScreen(filterChildId: child['id'] as int),
          ),
        );
        break;
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  Subtitle
  // ═══════════════════════════════════════════════════════════
  Widget _buildSubtitle(String? status, JisrColors c) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (child['disability_type'] != null)
          Text('الإعاقة: ${child['disability_type']}',
              style: TextStyle(fontSize: 13, color: c.muted)),
        if (child['age'] != null)
          Text('العمر: ${child['age']} سنة',
              style: TextStyle(fontSize: 13, color: c.muted)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: _statusColor(status).withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_statusIcon(status), size: 11, color: _statusColor(status)),
              const SizedBox(width: 4),
              Text(_statusText(status),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _statusColor(status),
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'evaluated':
        return AppColors.brandBlue;
      case 'assigned':
        return AppColors.brandTeal;
      default:
        return AppColors.orange;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'evaluated':
        return AppIcons.check;
      case 'assigned':
        return AppIcons.verified;
      default:
        return AppIcons.clock;
    }
  }

  String _statusText(String? status) {
    switch (status) {
      case 'evaluated':
        return 'تم التقييم';
      case 'assigned':
        return 'تم التعيين';
      default:
        return 'قيد الانتظار';
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  Approved Plan (تبقى موجودة كما هي)
  // ═══════════════════════════════════════════════════════════
  Future<void> _openApprovedPlan(BuildContext context, Map child) async {
    Map<String, dynamic>? plan;
    try {
      plan = await ApprovalService.getApprovedPlanForChild(child['id']);
      if (plan == null) {
        final serverPlans =
            await ApiService.getAllApprovals(status: 'approved');
        for (final p in serverPlans) {
          if (p['child_id'] == child['id']) {
            plan = Map<String, dynamic>.from(p);
            break;
          }
        }
      }
    } catch (_) {}

    if (!context.mounted) return;

    if (plan == null) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(AppIcons.clock, color: AppColors.brandBlue, size: 32),
              SizedBox(width: 8),
              Text('الخطة قيد المراجعة'),
            ],
          ),
          content: Text(
            'لم يتم اعتماد خطة "${child['name']}" من الوزارة بعد.\n\n'
            'يمكنك عرض الخطة الأولية من المختص.',
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إغلاق'),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandTeal),
              icon: const Icon(AppIcons.lesson),
              label: const Text('الخطة الأولية'),
              onPressed: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (_) => EducationalPlanSheet(child: child),
                );
              },
            ),
          ],
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ApprovedPlanSheet(plan: plan!),
    );
  }
}

// ═══════════════════════════════════════════════════════════
//  Bottom Sheet — أفعال أخرى للمعلم
// ═══════════════════════════════════════════════════════════
class _TeacherChildActionsSheet extends StatelessWidget {
  final String childName;
  const _TeacherChildActionsSheet({required this.childName});

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);

    final actions =
        <({String id, IconData icon, String label, Color color})>[
      (
        id: 'plan',
        icon: AppIcons.verified,
        label: 'الخطة التعليمية',
        color: AppColors.greenDeep,
      ),
      (
        id: 'reports',
        icon: AppIcons.report,
        label: 'التقارير الأسبوعية',
        color: AppColors.brandBlue,
      ),
      (
        id: 'case_discussion',
        icon: AppIcons.forum,
        label: 'دراسة الحالة مع المختص',
        color: AppColors.purple,
      ),
    ];

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: c.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.brandBlue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(
                    Icons.more_horiz,
                    color: AppColors.brandBlue,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'أفعال أخرى',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: c.heading,
                        ),
                      ),
                      Text(
                        childName,
                        style: TextStyle(fontSize: 13, color: c.muted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...actions.map(
              (a) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Material(
                  color: Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => Navigator.pop(context, a.id),
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: c.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: a.color.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            alignment: Alignment.center,
                            child: Icon(a.icon,
                                color: a.color, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              a.label,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 15,
                                color: c.heading,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.chevron_left,
                            color: c.muted,
                            size: 20,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}