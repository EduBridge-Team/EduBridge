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

}
