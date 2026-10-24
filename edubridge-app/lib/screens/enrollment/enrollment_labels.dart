import '../../l10n/generated/app_localizations.dart';
import '../../model/enrollment/enrollment_models.dart';
import '../../services/enrollment/enrollment_api_client.dart';

String enrollmentStatusLabel(AppLocalizations l10n, EnrollmentStatus status) =>
    switch (status) {
      EnrollmentStatus.pending => l10n.enrollmentPending,
      EnrollmentStatus.approved => l10n.enrollmentApproved,
      EnrollmentStatus.rejected => l10n.enrollmentRejected,
      EnrollmentStatus.cancelled => l10n.enrollmentCancelled,
    };
String enrollmentFailureMessage(
  AppLocalizations l10n,
  EnrollmentFailure failure,
) => switch (failure) {
  EnrollmentFailure.unavailable => l10n.enrollmentUnavailable,
  EnrollmentFailure.session => l10n.enrollmentSession,
  EnrollmentFailure.forbidden => l10n.enrollmentForbidden,
  EnrollmentFailure.validation => l10n.enrollmentValidation,
  EnrollmentFailure.conflict => l10n.enrollmentConflict,
  EnrollmentFailure.rateLimited => l10n.enrollmentRateLimited,
  EnrollmentFailure.network => l10n.enrollmentLoadFailed,
  EnrollmentFailure.uncertain ||
  EnrollmentFailure.invalidResponse ||
  EnrollmentFailure.server => l10n.enrollmentUncertain,
};
