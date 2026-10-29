import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// État affiché quand l'écran est ouvert sans studio sélectionné.
class SessionRequestNoStudioState extends StatelessWidget {
  final AppLocalizations l10n;
  final VoidCallback onBack;

  const SessionRequestNoStudioState({
    super.key,
    required this.l10n,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.buildingUser, size: 48, color: theme.colorScheme.outline),
            const SizedBox(height: 16),
            Text(l10n.noStudioSelected, style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              l10n.selectStudioFirst,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.outline),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: onBack,
              icon: const FaIcon(FontAwesomeIcons.arrowLeft, size: 14),
              label: Text(l10n.back),
            ),
          ],
        ),
      ),
    );
  }
}
