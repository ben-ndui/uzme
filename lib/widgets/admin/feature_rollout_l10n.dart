import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// L10n adapter for [FeatureRollout]. Kept out of the model so the
/// model stays pure (no Flutter / l10n imports) — the admin UI calls
/// `featureRolloutLabel(l10n, rollout)` instead of `rollout.label`.
String featureRolloutLabel(AppLocalizations l10n, FeatureRollout rollout) {
  switch (rollout) {
    case FeatureRollout.disabled:
      return l10n.featureRolloutDisabled;
    case FeatureRollout.pioneer:
      return l10n.featureRolloutPioneer;
    case FeatureRollout.beta:
      return l10n.featureRolloutBeta;
    case FeatureRollout.enabled:
      return l10n.featureRolloutEnabled;
  }
}
