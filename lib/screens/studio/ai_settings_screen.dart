import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/core/services/services_exports.dart';
import 'package:uzme/config/responsive_config.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/ai_guide/ai_guide_header.dart';
import 'package:uzme/widgets/studio/ai_settings/ai_settings_advanced_section.dart';
import 'package:uzme/widgets/studio/ai_settings/ai_settings_card.dart';
import 'package:uzme/widgets/studio/ai_settings/ai_settings_faq_section.dart';
import 'package:uzme/widgets/studio/ai_settings/ai_settings_mode_section.dart';
import 'package:uzme/widgets/studio/ai_settings/ai_settings_tone_section.dart';

/// Écran de configuration de l'assistant IA pour un studio
class AISettingsScreen extends StatefulWidget {
  final String studioId;

  const AISettingsScreen({
    super.key,
    required this.studioId,
  });

  @override
  State<AISettingsScreen> createState() => _AISettingsScreenState();
}

class _AISettingsScreenState extends State<AISettingsScreen> {
  final ChatAssistantService _service = ChatAssistantService();
  StudioAISettings? _settings;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    setState(() => _isLoading = true);
    try {
      final settings = await _service.getSettings(widget.studioId);
      setState(() {
        _settings = settings;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    if (_settings == null) return;

    setState(() => _isSaving = true);
    try {
      await _service.updateSettings(_settings!);
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.settingsSaved)),
        );
      }
    } catch (e) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorWithMessage(e.toString()))),
        );
      }
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _addFAQ(CustomFAQ faq) async {
    setState(() {
      _settings = _settings!.copyWith(
        customFAQs: [..._settings!.customFAQs, faq],
      );
    });
    await _service.addFAQ(widget.studioId, faq);
  }

  Future<void> _removeFAQ(CustomFAQ faq) async {
    setState(() {
      _settings = _settings!.copyWith(
        customFAQs: _settings!.customFAQs.where((f) => f != faq).toList(),
      );
    });
    await _service.removeFAQ(widget.studioId, faq);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.aiAssistant),
        actions: [
          if (_settings != null)
            TextButton(
              onPressed: _isSaving ? null : _saveSettings,
              child: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(l10n.save),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _settings == null
              ? Center(child: Text(l10n.loadingError))
              : _buildContent(l10n),
    );
  }

  Widget _buildContent(AppLocalizations l10n) {
    final settings = _settings!;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AiGuideHeader(
              title: l10n.aiAssistant,
              subtitle: l10n.aiAssistantDescription,
            ),
            const SizedBox(height: 24),
            _buildEnableSection(l10n, settings),
            const SizedBox(height: 24),
            if (settings.enabled) ...[
              AiSettingsModeSection(
                selectedMode: settings.mode,
                onModeSelected: (mode) => setState(() {
                  _settings = settings.copyWith(mode: mode);
                }),
              ),
              const SizedBox(height: 24),
              AiSettingsToneSection(
                selectedTone: settings.tone,
                onToneSelected: (tone) => setState(() {
                  _settings = settings.copyWith(tone: tone);
                }),
              ),
              const SizedBox(height: 24),
              AiSettingsAdvancedSection(
                settings: settings,
                onPriceDiscussionChanged: (value) => setState(() {
                  _settings = settings.copyWith(allowPriceDiscussion: value);
                }),
                onDelayChanged: (value) => setState(() {
                  _settings = settings.copyWith(autoReplyDelayMinutes: value);
                }),
              ),
              const SizedBox(height: 24),
              AiSettingsFaqSection(
                faqs: settings.customFAQs,
                onAdd: _addFAQ,
                onRemove: _removeFAQ,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEnableSection(AppLocalizations l10n, StudioAISettings settings) {
    return AiSettingsCard(
      child: SwitchListTile(
        title: Text(l10n.enableAIAssistant),
        subtitle: Text(settings.enabled ? l10n.aiHelpsRespond : l10n.aiDisabled),
        value: settings.enabled,
        onChanged: (value) => setState(() {
          _settings = settings.copyWith(enabled: value);
        }),
        secondary: FaIcon(
          settings.enabled ? FontAwesomeIcons.solidStar : FontAwesomeIcons.star,
          size: 18,
          color: settings.enabled
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.outline,
        ),
      ),
    );
  }
}
