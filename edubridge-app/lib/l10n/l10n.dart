import 'package:flutter/widgets.dart';
import 'generated/app_localizations.dart';

/// Local UI state stores message identities, not a sentence in a previous locale.
enum SharedUiMessage {
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
