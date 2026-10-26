import 'package:flutter/material.dart';

import '../../l10n/l10n.dart';
import '../../services/enrollment/enrollment_api_client.dart';
import '../../services/evaluations/evaluation_history_repository.dart';
import '../evaluation_history/evaluation_record_screen.dart';
import '../evaluation_history/evaluation_history_labels.dart';

class IepEvaluationReference extends StatefulWidget {
  const IepEvaluationReference({
    super.key,
    required this.childId,
    required this.evaluationId,
    this.gateway,
  });
  final int childId, evaluationId;
  final EvaluationHistoryGateway? gateway;
  @override
  State<IepEvaluationReference> createState() => _IepEvaluationReferenceState();
}

class _IepEvaluationReferenceState extends State<IepEvaluationReference> {
  bool _loading = false;
  EnrollmentFailure? _error;
  Future<void> _open() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    final childId = widget.childId;
    final evaluationId = widget.evaluationId;
    try {
      final history =
          await (widget.gateway ??
                  EvaluationHistoryRepository(childId: childId))
              .load();
      if (!mounted ||
          widget.childId != childId ||
          widget.evaluationId != evaluationId)
        return;
      final records = history.records.where(
        (v) => v.id == evaluationId && v.childId == childId,
      );
      if (history.childId != childId || records.length != 1) {
        throw const EnrollmentApiException(EnrollmentFailure.invalidResponse);
      }
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => EvaluationRecordScreen(record: records.single),
        ),
      );
    } on EnrollmentApiException catch (error) {
      if (mounted) setState(() => _error = error.failure);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      OutlinedButton.icon(
        key: const ValueKey('iep-evaluation-reference'),
        onPressed: _loading ? null : _open,
        icon: const Icon(Icons.description_outlined),
        label: Text(context.l10n.iepReference),
      ),
      if (_loading) const LinearProgressIndicator(),
      if (_error != null)
        Semantics(
          liveRegion: true,
          child: Text(evaluationHistoryError(context.l10n, _error!)),
        ),
    ],
  );
}
