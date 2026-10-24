import '../../l10n/generated/app_localizations.dart';
import '../../services/schools/director_api_client.dart';

String directorFailureMessage(AppLocalizations l10n, DirectorFailure error) =>
    switch (error) {
      DirectorFailure.unavailable => l10n.directorUnavailable,
      DirectorFailure.session => l10n.directorSession,
      DirectorFailure.forbidden => l10n.directorPermission,
      DirectorFailure.validation => l10n.directorValidation,
      DirectorFailure.conflict => l10n.directorConflict,
      DirectorFailure.rateLimited => l10n.directorRateLimited,
      DirectorFailure.network => l10n.directorLoadFailed,
      DirectorFailure.uncertain ||
      DirectorFailure.invalidResponse ||
      DirectorFailure.server => l10n.directorUncertain,
    };
