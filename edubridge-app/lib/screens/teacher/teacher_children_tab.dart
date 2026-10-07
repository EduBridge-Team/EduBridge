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
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 90),
        Center(
          child: Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: c.tintTeal,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.people_outline_rounded,
              size: 40,
              color: AppColors.brandBlue,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'لا يوجد أطفال موزّعون عليك حالياً',
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: c.heading,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          'سيظهر الأطفال هنا فور إسنادهم إلى حسابك.',
          style: TextStyle(fontSize: 13.5, color: c.muted),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  return ListView.builder(
    padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
    itemCount: children.length,
    itemBuilder: (context, i) => _TeacherChildCard(
      child: Map<String, dynamic>.from(children[i] as Map),
      color: AppColors.kidPalette[i % AppColors.kidPalette.length],
      c: c,
      onReload: reload,
    ),
  );
}

class _TeacherChildCard extends StatefulWidget {
  final Map<String, dynamic> child;
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
  State<_TeacherChildCard> createState() => _TeacherChildCardState();
}

class _TeacherChildCardState extends State<_TeacherChildCard> {
  void _toggleExpanded() => setState(() => _expanded = !_expanded);
  bool _expanded = false;

  Map<String, dynamic> get child => widget.child;
  Color get color => widget.color;
  JisrColors get c => widget.c;
  Future<void> Function() get onReload => widget.onReload;

  @override
  Widget build(BuildContext context) => buildView(context);

  double get _progressPercent {
    final candidates = [
      child['progress_percentage'],
      child['progress_percent'],
      child['completion_rate'],
      child['progress'],
    ];
    for (final value in candidates) {
      if (value is num) return value.toDouble().clamp(0, 100).toDouble();
      final parsed = double.tryParse('${value ?? ''}');
      if (parsed != null) return parsed.clamp(0, 100).toDouble();
    }
    return 0;
  }

  String get _followStatus {
    final status = (child['status'] ?? '').toString().toLowerCase();
    return switch (status) {
      'completed' || 'done' => 'طالب مكتمل المتابعة',
      'pending' => 'طالب بانتظار المتابعة',
      _ => 'طالب قيد المتابعة',
    };
  }

  Future<void> _openProfile(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherChildProfileScreen(child: child),
      ),
    );
    await onReload();
  }

  Future<void> _openDetailsTab(BuildContext context, int tab) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TeacherChildDetailsScreen(
          childId: child['id'] as int,
          childName: (child['name'] ?? '').toString(),
          initialTab: tab,
          showBottomNavigation: false,
        ),
      ),
    );
    await onReload();
  }

  Widget _quickAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: c.card,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          constraints: const BoxConstraints(minHeight: 72),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: c.line, width: 1.2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 22, color: color),
              const SizedBox(width: 9),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: c.heading,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
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
