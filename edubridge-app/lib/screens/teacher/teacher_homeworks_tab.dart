part of 'teacher_screen.dart';

class _TeacherHomeworksTab extends StatefulWidget {
  final List children;
  const _TeacherHomeworksTab({required this.children});

  @override
  State<_TeacherHomeworksTab> createState() => _TeacherHomeworksTabState();
}

class _TeacherHomeworksTabState extends State<_TeacherHomeworksTab> {
  List<Homework> _homeworks = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load({bool showLoader = true}) async {
    if (showLoader) setState(() => _loading = true);
    try {
      final list = await ApiService.getHomeworks();
      if (!mounted) return;
      setState(() {
        _homeworks = list
            .map((e) => Homework.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        _loading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'تعذّر تحميل الواجبات';
      });
    }
  }

  bool _hasUngraded(Homework h) => h.submissions.any((s) => s.grade == null);
  bool _allGraded(Homework h) => h.submissions.isNotEmpty && h.submissions.every((s) => s.grade != null);
  bool _hasMissing(Homework h) => h.submittedCount < h.totalAssigned;

  List<Homework> get _filtered {
    switch (_filter) {
      case 'pending':
        return _homeworks.where(_hasMissing).toList();
      case 'submitted':
        return _homeworks.where(_hasUngraded).toList();
      case 'graded':
        return _homeworks.where(_allGraded).toList();
      default:
        return _homeworks;
    }
  }

  int _count(String key) {
    switch (key) {
      case 'pending': return _homeworks.where(_hasMissing).length;
      case 'submitted': return _homeworks.where(_hasUngraded).length;
      case 'graded': return _homeworks.where(_allGraded).length;
      default: return _homeworks.length;
    }
  }

  Future<void> _createHomework() async {
    final result = await Navigator.push<dynamic>(
      context,
      MaterialPageRoute(
        builder: (_) => CreateHomeworkScreen(children: widget.children),
      ),
    );
    if (result == true && mounted) await _load(showLoader: false);
  }

  Widget _filterChip(String key, String label) {
    final selected = _filter == key;
    return ChoiceChip(
      selected: selected,
      onSelected: (_) => setState(() => _filter = key),
      label: Text('$label  ${_count(key)}'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = JisrColors.of(context);
    return Column(
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _filterChip('all', 'الكل'),
              const SizedBox(width: 8),
              _filterChip('pending', 'لم يُسلّم'),
              const SizedBox(width: 8),
              _filterChip('submitted', 'للتصحيح'),
              const SizedBox(width: 8),
              _filterChip('graded', 'مُصحّح'),
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Positioned.fill(
                child: RefreshIndicator(
                  onRefresh: () => _load(showLoader: false),
                  child: _loading
                      ? const Center(child: CircularProgressIndicator())
                      : _error != null
                          ? ListView(children: [
                              const SizedBox(height: 100),
                              Center(child: Text(_error!, style: const TextStyle(color: AppColors.red))),
                            ])
                          : _filtered.isEmpty
                              ? ListView(children: [
                                  const SizedBox(height: 110),
                                  Icon(AppIcons.homework, size: 64, color: c.muted),
                                  const SizedBox(height: 12),
                                  Center(child: Text('لا توجد واجبات ضمن هذا التصنيف', style: TextStyle(color: c.muted))),
                                ])
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                                  itemCount: _filtered.length,
                                  itemBuilder: (_, i) {
                                    final h = _filtered[i];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 10),
                                      child: Padding(
                                        padding: const EdgeInsets.all(14),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(h.title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: c.heading)),
                                            if ((h.subject ?? '').isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(h.subject!, style: TextStyle(fontSize: 12.5, color: c.muted)),
                                            ],
                                            const SizedBox(height: 8),
                                            Row(children: [
                                              Icon(AppIcons.calendar, size: 16, color: c.muted),
                                              const SizedBox(width: 5),
                                              Text('التسليم: ${h.dueDate.day}/${h.dueDate.month}/${h.dueDate.year}', style: TextStyle(fontSize: 12, color: c.muted)),
                                              const Spacer(),
                                              Text('${h.submittedCount}/${h.totalAssigned}', style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.brandBlue)),
                                            ]),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                ),
                ),
              ),
              Positioned(
                left: 16,
                bottom: 16,
                child: FloatingActionButton.extended(
                  heroTag: 'teacher-create-homework',
                  onPressed: _createHomework,
                  icon: const Icon(AppIcons.add),
                  label: const Text('إنشاء واجب', style: TextStyle(fontWeight: FontWeight.w800)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
