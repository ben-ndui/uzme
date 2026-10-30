import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/tip_item.dart';
import 'package:uzme/widgets/common/ai_guide/ai_guide_tip_card.dart';

/// Une section du guide IA (titre + liste de tips dépliables). Un seul
/// accent bleu pour tout le guide — pas une couleur par catégorie (Ben,
/// 28/10, même correctif que `TipsScreen`).
class AiGuideSection extends StatelessWidget {
  final TipSection section;
  final int sectionIndex;

  const AiGuideSection({
    super.key,
    required this.section,
    required this.sectionIndex,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: FaIcon(section.icon, size: 16, color: accent),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                section.title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...section.tips.asMap().entries.map((entry) {
            final tipIndex = entry.key;
            final tip = entry.value;
            return SlideInRight(
              delay: Duration(milliseconds: 50 * tipIndex),
              duration: const Duration(milliseconds: 300),
              child: AiGuideTipCard(tip: tip, accentColor: accent),
            );
          }),
        ],
      ),
    );
  }
}
