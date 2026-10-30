import 'package:flutter/material.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/studio/ai_settings/ai_settings_card.dart';

/// Liste des FAQ personnalisées de l'assistant IA + ajout/suppression.
class AiSettingsFaqSection extends StatelessWidget {
  final List<CustomFAQ> faqs;
  final ValueChanged<CustomFAQ> onAdd;
  final ValueChanged<CustomFAQ> onRemove;

  const AiSettingsFaqSection({
    super.key,
    required this.faqs,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AiSettingsCard(
      title: l10n.customFAQs,
      trailing: IconButton(
        icon: Icon(Icons.add_circle_outline, color: Theme.of(context).colorScheme.primary),
        onPressed: () => _showAddFAQDialog(context),
      ),
      child: Column(
        children: [
          if (faqs.isEmpty)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.customFAQsEmpty,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            )
          else
            ...faqs.map((faq) => ListTile(
                  title: Text(
                    faq.question,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  subtitle: Text(
                    faq.answer,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => onRemove(faq),
                  ),
                )),
        ],
      ),
    );
  }

  void _showAddFAQDialog(BuildContext context) {
    final questionController = TextEditingController();
    final answerController = TextEditingController();
    final l10n = AppLocalizations.of(context)!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.addFAQ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: questionController,
              decoration: InputDecoration(
                labelText: l10n.question,
                hintText: l10n.questionHint,
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: answerController,
              decoration: InputDecoration(
                labelText: l10n.answer,
                hintText: l10n.answerHint,
              ),
              maxLines: 3,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.cancel),
          ),
          ElevatedButton(
            onPressed: () {
              if (questionController.text.isNotEmpty && answerController.text.isNotEmpty) {
                onAdd(CustomFAQ(
                  question: questionController.text,
                  answer: answerController.text,
                ));
                Navigator.pop(context);
              }
            },
            child: Text(l10n.add),
          ),
        ],
      ),
    );
  }
}
