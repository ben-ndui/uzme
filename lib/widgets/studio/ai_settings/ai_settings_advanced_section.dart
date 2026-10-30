import 'package:flutter/material.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/studio/ai_settings/ai_settings_card.dart';

/// Options avancées de l'assistant IA : discussion de prix et délai
/// d'auto-réponse (visible seulement en mode `autoReply`).
class AiSettingsAdvancedSection extends StatelessWidget {
  final StudioAISettings settings;
  final ValueChanged<bool> onPriceDiscussionChanged;
  final ValueChanged<int> onDelayChanged;

  const AiSettingsAdvancedSection({
    super.key,
    required this.settings,
    required this.onPriceDiscussionChanged,
    required this.onDelayChanged,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AiSettingsCard(
      title: l10n.advancedOptions,
      child: Column(
        children: [
          SwitchListTile(
            title: Text(l10n.priceDiscussion),
            subtitle: Text(l10n.aiCanMentionDiscounts),
            value: settings.allowPriceDiscussion,
            onChanged: onPriceDiscussionChanged,
          ),
          if (settings.mode == AIMode.autoReply) ...[
            const Divider(),
            ListTile(
              title: Text(l10n.autoReplyDelay),
              subtitle: Text(l10n.minutesCount(settings.autoReplyDelayMinutes)),
              trailing: DropdownButton<int>(
                value: settings.autoReplyDelayMinutes,
                items: [1, 2, 5, 10, 15, 30]
                    .map((v) => DropdownMenuItem(value: v, child: Text('$v min')))
                    .toList(),
                onChanged: (value) {
                  if (value != null) onDelayChanged(value);
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
