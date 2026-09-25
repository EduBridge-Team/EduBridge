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
}
