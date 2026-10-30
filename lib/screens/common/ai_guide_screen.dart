import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:uzme/config/responsive_config.dart';
import 'package:uzme/core/models/tip_item.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/ai_guide/ai_guide_header.dart';
import 'package:uzme/widgets/common/ai_guide/ai_guide_section.dart';
import 'package:uzme/widgets/common/ai_guide/ai_guide_security_notice.dart';

/// Screen displaying AI assistant guide with capabilities by role
class AIGuideScreen extends StatelessWidget {
  final List<TipSection> sections;

  const AIGuideScreen({
    super.key,
    required this.sections,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiGuideTitle),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              FadeInDown(
                duration: const Duration(milliseconds: 400),
                child: AiGuideHeader(
                  title: l10n.aiGuideHeaderTitle,
                  subtitle: l10n.aiGuideHeaderSubtitle,
                ),
              ),
              const SizedBox(height: 16),
              FadeInDown(
                delay: const Duration(milliseconds: 100),
                duration: const Duration(milliseconds: 400),
                child: AiGuideSecurityNotice(
                  title: l10n.aiGuideSecurityTitle,
                  description: l10n.aiGuideSecurityDesc,
                ),
              ),
              const SizedBox(height: 24),
              ...sections.asMap().entries.map((entry) {
                final index = entry.key;
                final section = entry.value;
                return FadeInUp(
                  delay: Duration(milliseconds: 150 + (index * 100)),
                  duration: const Duration(milliseconds: 400),
                  child: AiGuideSection(section: section, sectionIndex: index),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}
