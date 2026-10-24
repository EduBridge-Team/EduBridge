import '../../../l10n/generated/app_localizations.dart';
import '../../../model/schools/director_evidence.dart';

String directorDocumentLabel(
  AppLocalizations l10n,
  DirectorDocumentKind kind,
) => switch (kind) {
  DirectorDocumentKind.identity => l10n.directorDocumentIdentity,
  DirectorDocumentKind.qualification => l10n.directorDocumentQualification,
  DirectorDocumentKind.appointment => l10n.directorDocumentAppointment,
  DirectorDocumentKind.other => l10n.directorDocumentOther,
};
String directorVerificationLabel(
  AppLocalizations l10n,
  DirectorVerificationStatus status,
) => switch (status) {
  DirectorVerificationStatus.notSubmitted => l10n.directorVerificationNone,
  DirectorVerificationStatus.pending => l10n.directorVerificationPending,
  DirectorVerificationStatus.approved => l10n.directorVerificationApproved,
  DirectorVerificationStatus.rejected => l10n.directorVerificationRejected,
};
