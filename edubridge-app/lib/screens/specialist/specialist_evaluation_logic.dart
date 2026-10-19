// Evaluation flows extracted from specialist_dashboard_logic.dart.
part of 'specialist_screen.dart';

extension _SpecialistEvaluationLogicExtension on _SpecialistDashboardScreenState {
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
          Text(context.l10n.noRecordedEvaluation,
              style: TextStyle(color: c.muted)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.close),
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
                const Icon(AppIcons.evaluate, color: AppColors.brandTeal),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(context.l10n.evaluationDetails,
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
              Text(context.l10n.evaluationDate(MaterialLocalizations.of(context).formatShortDate(date)),
                  style: TextStyle(color: c.muted)),
            const SizedBox(height: 12),
            _detailRow(context.l10n.cognitiveAssessment, evaluation['cognitive_assessment']),
            _detailRow(context.l10n.motorAssessment, evaluation['motor_assessment']),
            _detailRow(
                context.l10n.learningInteraction, evaluation['emotional_assessment']),
            _detailRow(context.l10n.socialAssessment, evaluation['social_assessment']),
            _detailRow(context.l10n.recommendations, evaluation['recommendations']),
            _detailRow(context.l10n.educationalPlan, evaluation['educational_plan']),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                child: Text(context.l10n.close),
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
}
