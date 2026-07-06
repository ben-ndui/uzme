import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// État d'erreur compact réutilisable pour les listes de données :
/// message + bouton réessayer. À monter quand un bloc émet un état
/// d'erreur — jamais laisser une erreur s'afficher comme une liste
/// vide (« Aucune session ») : c'est trompeur et sans issue.
class ErrorRetryCompact extends StatelessWidget {
  final String? message;
  final VoidCallback? onRetry;

  const ErrorRetryCompact({super.key, this.message, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.circleExclamation,
                size: 36, color: cs.error),
            const SizedBox(height: 12),
            Text(
              message ?? l10n.errorOccurred,
              textAlign: TextAlign.center,
              style: TextStyle(color: cs.onSurfaceVariant),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: onRetry,
                icon: const FaIcon(FontAwesomeIcons.arrowsRotate, size: 14),
                label: Text(l10n.retry),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
