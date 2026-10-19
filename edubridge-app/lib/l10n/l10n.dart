import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

/// Local UI state stores message identities, not a sentence in a previous locale.
enum SharedUiMessage {
  caseDataLoadFailed,
  caseListLoadFailed,
  caseChooseChild,
  homeworkTitleRequired,
  caseChooseParticipant,
  messageSendFailed,
  caseCreateFailed,
  caseResolveFailed,

  homeworkGradeRequired,
  homeworkGradeRange,
  homeworkGradeSaveFailed,
  homeworkChooseStudent,
  homeworkPublishFailed,

  followupSuggestionsLoadFailed,
  reportLoadFailed,
  reportsLoadFailed,
  chooseRecommendationReason,
  recommendationDescriptionMinimum,
  chooseSpecialist,
  recommendationReasonMinimum,
  recommendationSendFailed,
  evaluationSaveFailed,

  chooseDisabilityRequired,
  customDisabilityRequired,
  guardianPhotoRequired,
  kinshipDocumentRequired,
  medicalReportRequired,

  studentProfileRefreshFailed,
  careTeamLoadFailed,
  verificationRequestsLoadFailed,
  usersLoadFailed,
  ticketsLoadFailed,
  ticketResolveFailed,
  lessonsLoadFailed,
  lessonReviewFailed,
  identitySearchFailed,
  changesSaveFailed,
  accountCreateFailed,
  lessonRecommendationFailed,
  homeworksLoadFailed,
  dashboardLoadFailed,
  certificatePhotoRequired,
  idPhotoRequired,
  nationalIdRequired,
  certificateFileRequired,
  certificateTitleRequired,
  connectionFailed,
  enterEmailFirst,
  invalidRecoveryLink,
  passwordConfirmationMismatch,
  passwordEightMinimum,
  pasteRecoveryLinkFirst,
  profileLoadFailed,
  recoveryEmailNotice,
  supportFieldsRequired,
  validEmailRequired,
  verificationEmailNotice,
}

/// Reusable UI retains Arabic defaults in isolated legacy widget hosts.
/// The application root registers delegates for the selected interface locale.
extension LocalizedContext on BuildContext {
  AppLocalizations get l10n =>
      Localizations.of<AppLocalizations>(this, AppLocalizations) ??
      lookupAppLocalizations(const Locale('ar'));

  /// Known UI messages re-resolve on locale changes. Unstructured server errors
  /// retain Arabic detail in Arabic; English uses a safe translated fallback.
  String sharedMessage(Object? message) {
    if (message is SharedUiMessage) {
      return switch (message) {
        SharedUiMessage.caseDataLoadFailed => l10n.caseDataLoadFailed,
        SharedUiMessage.caseListLoadFailed => l10n.caseListLoadFailed,
        SharedUiMessage.caseChooseChild => l10n.caseChooseChild,
        SharedUiMessage.homeworkTitleRequired => l10n.homeworkTitleRequired,
        SharedUiMessage.caseChooseParticipant => l10n.caseChooseParticipant,
        SharedUiMessage.messageSendFailed => l10n.messageSendFailed,
        SharedUiMessage.caseCreateFailed => l10n.caseCreateFailed,
        SharedUiMessage.caseResolveFailed => l10n.caseResolveFailed,

        SharedUiMessage.homeworkGradeRequired => l10n.homeworkGradeRequired,
        SharedUiMessage.homeworkGradeRange => l10n.homeworkGradeRange,
        SharedUiMessage.homeworkGradeSaveFailed => l10n.homeworkGradeSaveFailed,
        SharedUiMessage.homeworkChooseStudent => l10n.homeworkChooseStudent,
        SharedUiMessage.homeworkPublishFailed => l10n.homeworkPublishFailed,

        SharedUiMessage.followupSuggestionsLoadFailed => l10n.followupSuggestionsLoadFailed,
        SharedUiMessage.reportLoadFailed => l10n.reportLoadFailed,
        SharedUiMessage.reportsLoadFailed => l10n.reportsLoadFailed,
        SharedUiMessage.chooseRecommendationReason => l10n.chooseRecommendationReason,
        SharedUiMessage.recommendationDescriptionMinimum => l10n.recommendationDescriptionMinimum,
        SharedUiMessage.chooseSpecialist => l10n.chooseSpecialist,
        SharedUiMessage.recommendationReasonMinimum => l10n.recommendationReasonMinimum,
        SharedUiMessage.recommendationSendFailed => l10n.recommendationSendFailed,
        SharedUiMessage.evaluationSaveFailed => l10n.evaluationSaveFailed,

        SharedUiMessage.chooseDisabilityRequired => l10n.chooseDisabilityRequired,
        SharedUiMessage.customDisabilityRequired => l10n.customDisabilityRequired,
        SharedUiMessage.guardianPhotoRequired => l10n.guardianPhotoRequired,
        SharedUiMessage.kinshipDocumentRequired => l10n.kinshipDocumentRequired,
        SharedUiMessage.medicalReportRequired => l10n.medicalReportRequired,

        SharedUiMessage.studentProfileRefreshFailed => l10n.studentProfileRefreshFailed,
        SharedUiMessage.careTeamLoadFailed => l10n.careTeamLoadFailed,
        SharedUiMessage.verificationRequestsLoadFailed => l10n.verificationRequestsLoadFailed,
        SharedUiMessage.usersLoadFailed => l10n.usersLoadFailed,
        SharedUiMessage.ticketsLoadFailed => l10n.ticketsLoadFailed,
        SharedUiMessage.ticketResolveFailed => l10n.ticketResolveFailed,
        SharedUiMessage.lessonsLoadFailed => l10n.lessonsLoadFailed,
        SharedUiMessage.lessonReviewFailed => l10n.lessonReviewFailed,
        SharedUiMessage.identitySearchFailed => l10n.identitySearchFailed,
        SharedUiMessage.changesSaveFailed => l10n.changesSaveFailed,
        SharedUiMessage.accountCreateFailed => l10n.accountCreateFailed,
        SharedUiMessage.lessonRecommendationFailed => l10n.lessonRecommendationFailed,
        SharedUiMessage.homeworksLoadFailed => l10n.homeworksLoadFailed,
        SharedUiMessage.dashboardLoadFailed => l10n.dashboardLoadFailed,
        SharedUiMessage.certificatePhotoRequired => l10n.certificatePhotoRequired,
        SharedUiMessage.idPhotoRequired => l10n.idPhotoRequired,
        SharedUiMessage.nationalIdRequired => l10n.nationalIdRequired,
        SharedUiMessage.certificateFileRequired => l10n.certificateFileRequired,
        SharedUiMessage.certificateTitleRequired => l10n.certificateTitleRequired,
        SharedUiMessage.connectionFailed => l10n.connectionFailed,
        SharedUiMessage.enterEmailFirst => l10n.enterEmailFirst,
        SharedUiMessage.invalidRecoveryLink => l10n.invalidRecoveryLink,
        SharedUiMessage.passwordConfirmationMismatch => l10n.passwordConfirmationMismatch,
        SharedUiMessage.passwordEightMinimum => l10n.passwordEightMinimum,
        SharedUiMessage.pasteRecoveryLinkFirst => l10n.pasteRecoveryLinkFirst,
        SharedUiMessage.profileLoadFailed => l10n.profileLoadFailed,
        SharedUiMessage.recoveryEmailNotice => l10n.recoveryEmailNotice,
        SharedUiMessage.supportFieldsRequired => l10n.supportFieldsRequired,
        SharedUiMessage.validEmailRequired => l10n.validEmailRequired,
        SharedUiMessage.verificationEmailNotice => l10n.verificationEmailNotice,

      };
    }
    if (l10n.localeName.startsWith('en')) return l10n.genericError;
    return message?.toString() ?? l10n.genericError;
  }
}
