// Specialist dashboard state logic extracted from specialist_screen.dart.
part of 'specialist_screen.dart';

extension _SpecialistDashboardLogicExtension on _SpecialistDashboardScreenState {
  // ═══════════════════════════════════════════════════════════
  //  Helpers — compute stats
  // ═══════════════════════════════════════════════════════════
  bool _isToday(String? ts) {
    if (ts == null || ts.isEmpty) return false;
    final d = DateTime.tryParse(ts.replaceFirst(' ', 'T'));
    if (d == null) return false;
    final now = DateTime.now();
    return d.year == now.year && d.month == now.month && d.day == now.day;
  }

  Map<String, dynamic> _computeStats(List progress) {
    final total = progress.length;
    final done = progress.where((r) => r['status'] == 'done').length;
    final inProgress =
        progress.where((r) => r['status'] == 'in_progress').length;
    final doneToday = progress
        .where((r) =>
            r['status'] == 'done' && _isToday(r['completed_at']?.toString()))
        .length;
    final pct = total > 0 ? ((done / total) * 100).round() : 0;
    final current = progress.cast<Map?>().firstWhere(
          (r) => r?['status'] == 'in_progress',
          orElse: () => null,
        );
    return {
      'total': total,
      'done': done,
      'inProgress': inProgress,
      'doneToday': doneToday,
      'pct': pct,
      'current': current,
    };
  }

  // ═══════════════════════════════════════════════════════════
  //  الفلترة والتخصصات
  // ═══════════════════════════════════════════════════════════
  Set<int> _childSpecialistIds(Map<String, dynamic> child) {
    final ids = <int>{};
    final single = child['specialist_id'];
    if (single is int) ids.add(single);
    if (single is String) {
      final v = int.tryParse(single);
      if (v != null) ids.add(v);
    }
    for (final key in [
      'specialist_ids',
      'assigned_specialist_ids',
      'specialists'
    ]) {
      final list = child[key];
      if (list is List) {
        for (final item in list) {
          if (item is int) ids.add(item);
          if (item is String) {
            final v = int.tryParse(item);
            if (v != null) ids.add(v);
          }
          if (item is Map && item['id'] != null) {
            final v = item['id'] is int
                ? item['id'] as int
                : int.tryParse(item['id'].toString());
            if (v != null) ids.add(v);
          }
        }
      }
    }
    return ids;
  }

  bool _isMyChild(Map<String, dynamic> child) {
    if (_currentUserId == null) return false;
    return _childSpecialistIds(child).contains(_currentUserId);
  }

  bool _hasBothSpecialists(Map<String, dynamic> child) {
    final specIds = _childSpecialistIds(child);
    if (specIds.length < 2) return false;

    int supportCount = 0;
    int eduCount = 0;
    int unknownCount = 0;

    for (final id in specIds) {
      final s = _specialists.firstWhere(
        (u) => u['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      final spec = (s['specialty'] ?? '').toString().toLowerCase();
      if (spec == 'learning_support' || spec.contains('نفس')) {
        supportCount++;
      } else if (spec == 'educational' || spec.contains('تعليم')) {
        eduCount++;
      } else {
        unknownCount++;
      }
    }
    if (supportCount >= 1 && eduCount >= 1) return true;
    if (supportCount + eduCount == 0 && unknownCount >= 2) return true;
    return false;
  }

  bool _hasSpecialistOfType(Map<String, dynamic> child, String type) {
    final specIds = _childSpecialistIds(child);
    for (final id in specIds) {
      final s = _specialists.firstWhere(
        (u) => u['id'] == id,
        orElse: () => <String, dynamic>{},
      );
      final spec = (s['specialty'] ?? '').toString().toLowerCase();
      if (spec == type) return true;
      if (type == 'learning_support' && spec.contains('نفس')) return true;
      if (type == 'educational' && spec.contains('تعليم')) return true;
    }
    return false;
  }

  bool _isInWaitingList(Map<String, dynamic> child) {
    if (_isMyChild(child)) return false;
    if (_hasBothSpecialists(child)) return false;
    if (_mySpecialty == null || _mySpecialty!.isEmpty) {
      return _childSpecialistIds(child).isEmpty;
    }
    if (_mySpecialty == 'learning_support') {
      return !_hasSpecialistOfType(child, 'learning_support');
    }
    if (_mySpecialty == 'educational') {
      return !_hasSpecialistOfType(child, 'educational');
    }
    return false;
  }

  List get _filteredChildren {
    final query = _searchQuery.trim().toLowerCase();
    List<Map<String, dynamic>> base;
    if (_showOnlyMine) {
      base = _rows.where((r) => _isMyChild(r['child'])).toList();
    } else {
      base = _rows.where((r) => _isInWaitingList(r['child'])).toList();
    }
    if (query.isEmpty) return base;
    return base.where((row) {
      final name = (row['child']['name'] ?? '').toString().toLowerCase();
      return name.contains(query);
    }).toList();
  }

  List get _pendingChildren => _rows.where((row) {
        final s = row['child']['status'] ?? '';
        return s != 'evaluated' && s != 'assigned';
      }).toList();

  int get _pendingCount => _pendingChildren.length;
  int get _doneToday =>
      _rows.fold(0, (s, r) => s + (r['stats']['doneToday'] as int));
  int get _pendingProgress =>
      _rows.fold(0, (s, r) => s + (r['stats']['inProgress'] as int));

  // ═══════════════════════════════════════════════════════════
  //  الإجراءات — Approve / Evaluation / Reports
  // ═══════════════════════════════════════════════════════════
  Future<void> _approve(Map<String, dynamic> row) async {
    if (!await _checkVerification()) return;
    final current = row['stats']['current'];
    if (current == null) return;

    final childId = row['child']['id'];
    setState(() => _approvingId = childId);

    try {
      final res = await ApiService.authPost('/progress', {
        'child_id': childId,
        'lesson_id': current['lesson_id'],
        'status': 'done',
      });

      if (res.statusCode == 200 || res.statusCode == 201) {
        await _load();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم اعتماد إنجاز الدرس'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذّر الاتصال بالسيرفر')),
        );
      }
    } finally {
      if (mounted) setState(() => _approvingId = null);
    }
  }

  Future<void> _openEvaluation(Map<String, dynamic> row) async {
    if (!await _checkVerification()) return;
    final child = row['child'];
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EvaluationSheet(
        child: child,
        teachers: _teachers,
        onSaved: (updatedChild) {
          setState(() {
            final index = _rows.indexWhere(
                (r) => r['child']['id'] == updatedChild['id']);
            if (index != -1) {
              _rows[index]['child'] = updatedChild;
            }
          });
          _load();
        },
      ),
    );
  }

  Future<void> _viewEvaluation(int childId) async {
    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FutureBuilder(
        future: ApiService.getChildEvaluations(childId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!.isEmpty) {
            return _buildEmptyEvaluationModal();
          }
          final evaluation = snapshot.data!.last;
          return _buildEvaluationViewModal(evaluation);
        },
      ),
    );
  }

  Widget _buildEmptyEvaluationModal() {
    final c = JisrColors.of(context);
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(AppIcons.evaluate, size: 48, color: AppColors.muted),
          const SizedBox(height: 12),
          Text('لا يوجد تقييم مسجل',
              style: TextStyle(color: c.muted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  Widget _buildEvaluationViewModal(Map evaluation) {
    final c = JisrColors.of(context);
    final date = evaluation['created_at'] != null
        ? DateTime.parse(evaluation['created_at'])
        : null;

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: c.card,
        borderRadius: BorderRadius.circular(24),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(AppIcons.evaluate, color: AppColors.orange),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('تفاصيل التقييم',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: c.heading,
                      )),
                ),
                IconButton(
                  icon: const Icon(AppIcons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            if (date != null)
              Text('التاريخ: ${date.day}/${date.month}/${date.year}',
                  style: TextStyle(color: c.muted)),
            const SizedBox(height: 12),
            _detailRow('التقييم المعرفي', evaluation['cognitive_assessment']),
            _detailRow('التقييم الحركي', evaluation['motor_assessment']),
            _detailRow(
                'التفاعل أثناء التعلم', evaluation['emotional_assessment']),
            _detailRow('التقييم الاجتماعي', evaluation['social_assessment']),
            _detailRow('التوصيات', evaluation['recommendations']),
            _detailRow('الخطة التعليمية', evaluation['educational_plan']),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إغلاق'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  التنقل بين الشاشات
  // ═══════════════════════════════════════════════════════════
  Future<void> _logout() async {
    await ApiService.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
    );
  }

  void _openNotifications() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  void _openLearningSupport() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const LearningSupportMeetingsScreen(),
      ),
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

  void _openSuggestions() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const SpecialistSuggestionsScreen(),
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
    setState(() => _approvingId = child['id']);

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
      if (mounted) setState(() => _approvingId = null);
    }
  }

  // ═══════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════
}
