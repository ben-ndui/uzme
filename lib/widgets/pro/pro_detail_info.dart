import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/pro_profile.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Bio, stats (tarif/note), tags (spécialités, genres...) et moyens de
/// paiement d'un pro.
class ProDetailInfo extends StatelessWidget {
  final ProProfile profile;

  const ProDetailInfo({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Column(
      children: [
        if (profile.bio != null) _buildBio(theme),
        _buildStats(theme, l10n),
        _buildTags(theme, l10n),
        if (profile.hasPaymentMethods) _buildPaymentMethods(theme, l10n),
      ],
    );
  }

  Widget _buildBio(ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Text(
        profile.bio!,
        style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
    );
  }

  Widget _buildStats(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          _statChip(
            theme,
            icon: FontAwesomeIcons.euroSign,
            value: profile.hasRate ? profile.formattedRate : l10n.proDetailOnQuote,
          ),
          if (profile.rating != null) ...[
            const SizedBox(width: 12),
            _statChip(
              theme,
              icon: FontAwesomeIcons.solidStar,
              iconColor: Colors.amber,
              value: '${profile.rating!.toStringAsFixed(1)} (${profile.reviewCount ?? 0})',
            ),
          ],
        ],
      ),
    );
  }

  Widget _statChip(
    ThemeData theme, {
    required FaIconData icon,
    required String value,
    Color? iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FaIcon(icon, size: 14, color: iconColor ?? theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildTags(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.start,
        spacing: 8,
        children: [
          if (profile.specialties.isNotEmpty)
            _tagSection(theme, l10n.proDetailSpecialties, profile.specialties),
          if (profile.genres.isNotEmpty) _tagSection(theme, l10n.proDetailGenres, profile.genres),
          if (profile.instruments.isNotEmpty)
            _tagSection(theme, l10n.proDetailInstruments, profile.instruments),
          if (profile.daws.isNotEmpty) _tagSection(theme, l10n.proDetailDaws, profile.daws),
        ],
      ),
    );
  }

  Widget _tagSection(ThemeData theme, String title, List<String> tags) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.outline, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: tags
                .map((tag) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        tag,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w500),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethods(ThemeData theme, AppLocalizations l10n) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.proDetailPaymentMethods,
            style: theme.textTheme.labelMedium
                ?.copyWith(color: theme.colorScheme.outline, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: profile.enabledPaymentMethods
                .map((m) => Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        m.type.label,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: theme.colorScheme.tertiary, fontWeight: FontWeight.w500),
                      ),
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }
}
