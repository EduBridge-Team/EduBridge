import '../../l10n/generated/app_localizations.dart';
import '../../model/evaluations/evaluation_record.dart';
import '../../services/enrollment/enrollment_api_client.dart';

String evaluationRecordTitle(AppLocalizations l10n, EvaluationRecord record) =>
    switch (record.type) {
      'initial' => l10n.initialEvaluation,
      'follow_up' => l10n.followUpEvaluation,
      final type when type != null && type.trim().isNotEmpty => type,
      _ => l10n.evaluation,
    };
String evaluationHistoryError(
  AppLocalizations l10n,
  EnrollmentFailure failure,
) => switch (failure) {
  EnrollmentFailure.session => l10n.enrollmentSession,
  EnrollmentFailure.forbidden => l10n.evaluationHistoryForbidden,
  EnrollmentFailure.invalidResponse => l10n.evaluationHistoryInvalidResponse,
  _ => l10n.evaluationHistoryLoadFailed,
};
