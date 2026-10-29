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
          context.l10n.noAssignedTeacherChildren,
          style: TextStyle(
            fontSize: 19,
            fontWeight: FontWeight.w800,
            color: c.heading,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        Text(
          context.l10n.assignedChildrenDescription,
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
      key: ValueKey((children[i] as Map)['id']),
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
    super.key,
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

  double? get _progressPercent {
    final candidates = [
      child['progress_percentage'],
      child['progress_percent'],
      child['completion_rate'],
      child['progress'],
    ];
    for (final value in candidates) {
      if (value is num && value.isFinite) return value.toDouble().clamp(0, 100).toDouble();
      final parsed = double.tryParse('${value ?? ''}');
      if (parsed != null && parsed.isFinite) return parsed.clamp(0, 100).toDouble();
    }
    return null;
  }

  String get _followStatus {
    final status = (child['status'] ?? '').toString().toLowerCase();
    return switch (status) {
      'completed' || 'done' => context.l10n.followUpCompleted,
      'pending' => context.l10n.followUpPending,
      'active' || 'assigned' || 'evaluated' => context.l10n.followUpActive,
      _ => '—',
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
          title: Row(
            children: [
              Icon(AppIcons.clock, color: AppColors.brandBlue, size: 32),
              SizedBox(width: 8),
              Expanded(child: Text(context.l10n.planUnderReview)),
            ],
          ),
          content: Text(
            context.l10n.planPendingForChild((child['name'] ?? '').toString()),
            style: const TextStyle(fontSize: 15, height: 1.6),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(context.l10n.close),
            ),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.brandTeal),
              icon: const Icon(AppIcons.lesson),
              label: Text(context.l10n.preliminaryPlan),
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
