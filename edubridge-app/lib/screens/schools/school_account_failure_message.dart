import '../../l10n/generated/app_localizations.dart';
import '../../services/schools/school_account_repository.dart';

String schoolAccountFailureMessage(
    AppLocalizations l10n, SchoolAccountFailure failure) => switch (failure) {
  SchoolAccountFailure.unavailable => l10n.schoolAccountUnavailable,
  SchoolAccountFailure.unauthorized => l10n.schoolAccountUnauthorized,
  SchoolAccountFailure.forbidden => l10n.schoolAccountForbidden,
  SchoolAccountFailure.validation => l10n.schoolAccountValidation,
  SchoolAccountFailure.conflict => l10n.schoolAccountConflict,
  SchoolAccountFailure.rateLimited => l10n.schoolAccountRateLimited,
  SchoolAccountFailure.network => l10n.schoolAccountNetwork,
  SchoolAccountFailure.uncertain || SchoolAccountFailure.invalidResponse =>
    l10n.schoolAccountUncertain,
  SchoolAccountFailure.server => l10n.schoolAccountServer,
};
