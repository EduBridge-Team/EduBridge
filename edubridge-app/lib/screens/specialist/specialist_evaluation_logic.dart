// Evaluation flows extracted from specialist_dashboard_logic.dart.
part of 'specialist_screen.dart';

extension _SpecialistEvaluationLogicExtension
    on _SpecialistDashboardScreenState {
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
          _refreshState(() {
            final index = _rows.indexWhere(
              (r) => r['child']['id'] == updatedChild['id'],
            );
            if (index != -1) {
              _rows[index]['child'] = updatedChild;
            }
          });
          _load();
        },
      ),
    );
  }

  Future<void> _viewEvaluation(int childId, {String childName = ''}) async {
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) =>
            EvaluationHistoryScreen(childId: childId, childName: childName),
      ),
    );
  }
}
