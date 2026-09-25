// lib/screens/teacher/teacher_children_tab.dart
part of 'teacher_screen.dart';

Widget _buildChildrenTab(
  BuildContext context,
  JisrColors c,
  List children,
  String query,
  ValueChanged<String> onQueryChanged,
  String? Function(int?) typeName,
  Future<void> Function() reload,
) {
  if (children.isEmpty) {
    return ListView(
      children: [
        const SizedBox(height: 80),
        Icon(Icons.people_outline, size: 72, color: c.muted),
        const SizedBox(height: 16),
        Center(
          child: Text('لا يوجد أطفال موزّعين عليك حالياً',
              style: TextStyle(fontSize: 18, color: c.muted),
              textAlign: TextAlign.center),
        ),
      ],
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.all(12),
    itemCount: children.length,
    itemBuilder: (context, i) => _TeacherChildCard(
      child: children[i],
      color: AppColors.kidPalette[i % AppColors.kidPalette.length],
      c: c,
      onReload: reload,
    ),
  );
}

class _TeacherChildCard extends StatelessWidget {
  final Map child;
  final Color color;
  final JisrColors c;
  final Future<void> Function() onReload;

  const _TeacherChildCard({
    required this.child,
    required this.color,
    required this.c,
    required this.onReload,
  });

  @override
  Widget build(BuildContext context) {
    final name = (child['name'] ?? '').toString();
    final status = child['status'];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            title: Text(name,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: c.heading,
                )),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: _buildActionButtons(context, child),
          ),
        ],
      ),
    );
  }

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

  Widget _buildActionButtons(BuildContext context, Map child) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(AppIcons.verified, size: 16),
                label: const Text('الخطة'),
                onPressed: () => _openApprovedPlan(context, child),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                icon: const Icon(AppIcons.progress, size: 16),
                label: const Text('التقدّم'),
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
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  backgroundColor: AppColors.brandTeal,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(AppIcons.edit, size: 16),
                label: const Text('اكتب تقرير'),
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
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(0, 38),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: AppColors.brandBlue,
                ),
                icon: const Icon(AppIcons.view, size: 16),
                label: const Text('التقارير'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WeeklyReportScreen(
                      childId: child['id'],
                      childName: (child['name'] ?? '').toString(),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 40),
              foregroundColor: AppColors.purple,
              side: const BorderSide(color: AppColors.purple, width: 1.5),
            ),
            icon: const Icon(AppIcons.forum, size: 18),
            label: const Text('دراسة الحالة مع المختص',
                style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    CaseDiscussionScreen(filterChildId: child['id'] as int),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String? status) {
    switch (status) {
      case 'evaluated': return AppColors.brandBlue;
      case 'assigned': return AppColors.brandTeal;
      default: return AppColors.orange;
    }
  }

  IconData _statusIcon(String? status) {
    switch (status) {
      case 'evaluated': return AppIcons.check;
      case 'assigned': return AppIcons.verified;
      default: return AppIcons.clock;
    }
  }

  String _statusText(String? status) {
    switch (status) {
      case 'evaluated': return 'تم التقييم';
      case 'assigned': return 'تم التعيين';
      default: return 'قيد الانتظار';
    }
  }

  Future<void> _openApprovedPlan(BuildContext context, Map child) async {
    Map<String, dynamic>? plan;
    try {
      plan = await ApprovalService.getApprovedPlanForChild(child['id']);
      if (plan == null) {
        final serverPlans = await ApiService.getAllApprovals(status: 'approved');
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandTeal),
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