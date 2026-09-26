// Dashboard actions extracted from specialist_dashboard_logic.dart.
part of 'specialist_screen.dart';

extension _SpecialistDashboardActionsExtension on _SpecialistDashboardScreenState {
  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openCaseDiscussion({int? childId}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CaseDiscussionScreen(filterChildId: childId),
      ),
    );
  }

  void _openPlanEvaluation(Map<String, dynamic> row) {
    final child = row['child'];
    final planId = child['current_plan_id'] ?? 0;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PlanEvaluationScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
          planId: planId is int ? planId : 0,
        ),
      ),
    );
  }

  Future<void> _openTeacherReport(Map<String, dynamic> row) async {
    final child = row['child'];
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => WeeklyReportScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
  }

  Future<void> _writeProgressBasedOnReport(
      Map<String, dynamic> row) async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    final child = row['child'];
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateSpecialistProgressScreen(
          childId: child['id'],
          childName: (child['name'] ?? '').toString(),
        ),
      ),
    );
    if (result == true) _load();
  }

  Future<void> _recommendLearningSupport(
      Map<String, dynamic> row) async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _RecommendLearningSupportSheet(child: row['child']),
    );
    if (result == true) _load();
  }

  Future<void> _openSuggestSpecialist(
      Map<String, dynamic> row, String specialty) async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    final child = row['child'];
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SuggestSpecialistSheet(
        child: child,
        specialists: _specialists,
        specialty: specialty,
      ),
    );
    if (result == true) _load();
  }

  // ═══════════════════════════════════════════════════════════
  //  إضافة نفسي كمسؤول عن الطفل
  // ═══════════════════════════════════════════════════════════
  Future<void> _addMyselfToChild(Map<String, dynamic> child) async {
    if (!await _checkVerification()) return;
    if (!mounted) return;
    if (_mySpecialty == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('لم يتم تحديد تخصصك — راجع الدعم'),
          backgroundColor: AppColors.red,
        ),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              _mySpecialty == 'learning_support'
                  ? AppIcons.specialist
                  : AppIcons.lesson,
              color: _mySpecialty == 'learning_support'
                  ? AppColors.purple
                  : AppColors.brandBlue,
              size: 28,
            ),
            const SizedBox(width: 8),
            const Text('تأكيد الإضافة'),
          ],
        ),
        content: Text(
          'هل تريد إضافة "${child['name']}" لمتابعتك كـ'
          '${_mySpecialty == 'learning_support' ? 'مختص دعم تعليمي' : 'مختص تعليمي'}؟',
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: _mySpecialty == 'learning_support'
                  ? AppColors.purple
                  : AppColors.brandBlue,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('إضافة'),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    if (!mounted) return;
    _refreshState(() => _approvingId = child['id']);

    try {
      final err = await ApiService.assignSpecialist(
        childId: child['id'],
        specialistId: _currentUserId!,
        specialty: _mySpecialty!,
      );
      if (!mounted) return;
      if (err != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(err), backgroundColor: AppColors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تمت إضافة ${child['name']} لمتابعتك'),
            backgroundColor: AppColors.green,
          ),
        );
        await _load();
      }
    } finally {
      if (mounted) _refreshState(() => _approvingId = null);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════
}
