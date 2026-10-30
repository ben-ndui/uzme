import 'package:flutter/material.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/studio/ai_settings/ai_settings_card.dart';

/// Choix du ton de réponse de l'assistant IA.
class AiSettingsToneSection extends StatelessWidget {
  final String selectedTone;
  final ValueChanged<String> onToneSelected;

  const AiSettingsToneSection({
    super.key,
    required this.selectedTone,
    required this.onToneSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final tones = [
      ('professional', l10n.toneProfessional, l10n.toneProfessionalDesc),
      ('friendly', l10n.toneFriendly, l10n.toneFriendlyDesc),
      ('casual', l10n.toneCasual, l10n.toneCasualDesc),
    ];

    return AiSettingsCard(
      title: l10n.responseTone,
      child: Column(
        children: tones.map((tone) {
          final isSelected = selectedTone == tone.$1;
          return ListTile(
            title: Text(tone.$2),
            subtitle: Text(tone.$3),
            trailing: Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
            ),
            onTap: () => onToneSelected(tone.$1),
          );
        }).toList(),
      ),
    );
  }
}
