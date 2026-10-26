import '../../l10n/generated/app_localizations.dart';
import '../../model/iep/iep_version.dart';
import '../../services/enrollment/enrollment_api_client.dart';

String iepStatusLabel(AppLocalizations l10n, IepVersionStatus status) =>
    switch (status) {
      IepVersionStatus.draft => l10n.iepDraft,
      IepVersionStatus.submitted => l10n.iepSubmitted,
      IepVersionStatus.returned => l10n.iepReturned,
      IepVersionStatus.approved => l10n.iepApproved,
    };
String iepError(AppLocalizations l10n, EnrollmentFailure failure) =>
    switch (failure) {
      EnrollmentFailure.session => l10n.enrollmentSession,
      EnrollmentFailure.forbidden => l10n.iepForbidden,
      EnrollmentFailure.invalidResponse => l10n.iepInvalid,
      EnrollmentFailure.unavailable => l10n.iepUnavailable,
      _ => l10n.iepLoadFailed,
    };
