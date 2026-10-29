import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Carte ingénieur assigné, sur l'écran de détail de session.
class SessionDetailEngineerCard extends StatelessWidget {
  final Session session;
  final AppLocalizations l10n;
  final ThemeData theme;

  const SessionDetailEngineerCard({super.key, required this.session, required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: FaIcon(FontAwesomeIcons.headphones, size: 18, color: theme.colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.engineer, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(session.engineerName ?? '-', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: theme.colorScheme.onSurface)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(l10n.confirmed, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.green)),
          ),
        ],
      ),
    );
  }
}

/// Carte "ingénieur à assigner", affichée tant qu'aucun n'est confirmé.
class SessionDetailPendingEngineerCard extends StatelessWidget {
  final AppLocalizations l10n;
  final ThemeData theme;

  const SessionDetailPendingEngineerCard({super.key, required this.l10n, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(10)),
            child: const FaIcon(FontAwesomeIcons.headphones, size: 18, color: Colors.orange),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.engineer, style: TextStyle(fontSize: 12, color: theme.colorScheme.onSurfaceVariant)),
                const SizedBox(height: 4),
                Text(l10n.toBeAssigned, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.orange)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
