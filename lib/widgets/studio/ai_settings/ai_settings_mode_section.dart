import 'package:flutter/material.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/studio/ai_settings/ai_settings_card.dart';

/// Choix du mode de fonctionnement de l'assistant IA.
class AiSettingsModeSection extends StatelessWidget {
  final AIMode selectedMode;
  final ValueChanged<AIMode> onModeSelected;

  const AiSettingsModeSection({
    super.key,
    required this.selectedMode,
    required this.onModeSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AiSettingsCard(
      title: AppLocalizations.of(context)!.operatingMode,
      child: Column(
        children: AIMode.values
            .where((m) => m != AIMode.off)
            .map((mode) => _ModeOptionTile(
                  mode: mode,
                  isSelected: selectedMode == mode,
                  onTap: () => onModeSelected(mode),
                ))
            .toList(),
      ),
    );
  }
}

class _ModeOptionTile extends StatelessWidget {
  final AIMode mode;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeOptionTile({
    required this.mode,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Text(mode.icon, style: const TextStyle(fontSize: 24)),
      title: Text(mode.displayName),
      subtitle: Text(
        mode.description,
        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
      ),
      trailing: Icon(
        isSelected ? Icons.check_circle : Icons.circle_outlined,
        color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outline,
      ),
      onTap: onTap,
    );
  }
}
