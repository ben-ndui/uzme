import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/constants/feature_flag_keys.dart';
import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/main.dart' show featureFlagsService;
import 'package:uzme/widgets/admin/feature_rollout_l10n.dart';

/// Modal sheet to create or edit a feature flag.
/// Pass [existing] to edit, leave null to create.
/// On success, pops with the saved flag's key.
class FeatureFlagEditSheet extends StatefulWidget {
  final FeatureFlag? existing;
  const FeatureFlagEditSheet({super.key, this.existing});

  @override
  State<FeatureFlagEditSheet> createState() => _FeatureFlagEditSheetState();
}

class _FeatureFlagEditSheetState extends State<FeatureFlagEditSheet> {
  final _formKey = GlobalKey<FormState>();
  final _keyController = TextEditingController();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _categoryController = TextEditingController();
  final _betaUidController = TextEditingController();
  final _announcementTitleController = TextEditingController();
  final _announcementBodyController = TextEditingController();
  FeatureRollout _rollout = FeatureRollout.disabled;
  List<String> _betaUserIds = [];
  bool _submitting = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final f = widget.existing;
    if (f != null) {
      _keyController.text = f.key;
      _titleController.text = f.title;
      _descController.text = f.description;
      _categoryController.text = f.category ?? '';
      _announcementTitleController.text = f.announcementTitle;
      _announcementBodyController.text = f.announcementBody;
      _rollout = f.rollout;
      _betaUserIds = List.of(f.betaUserIds);
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    _titleController.dispose();
    _descController.dispose();
    _categoryController.dispose();
    _betaUidController.dispose();
    _announcementTitleController.dispose();
    _announcementBodyController.dispose();
    super.dispose();
  }

  /// Pre-fill the form from a catalogue spec when the admin picks one.
  /// Only invoked in create mode — the catalog selector is hidden on edit.
  void _applySpec(FeatureFlagSpec spec) {
    setState(() {
      _keyController.text = spec.key;
      _titleController.text = spec.title;
      _descController.text = spec.description;
      _categoryController.text = spec.category;
    });
  }

  void _addBetaUid() {
    final v = _betaUidController.text.trim();
    if (v.isEmpty) return;
    setState(() {
      if (!_betaUserIds.contains(v)) _betaUserIds.add(v);
      _betaUidController.clear();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    final l10n = AppLocalizations.of(context)!;
    try {
      await featureFlagsService.upsertFlag(
        key: _keyController.text.trim(),
        title: _titleController.text.trim(),
        description: _descController.text.trim(),
        rollout: _rollout,
        betaUserIds: _betaUserIds,
        metadata: _categoryController.text.trim().isEmpty
            ? const {}
            : {'category': _categoryController.text.trim()},
        announcementTitle: _announcementTitleController.text.trim(),
        announcementBody: _announcementBodyController.text.trim(),
      );
      if (mounted) Navigator.of(context).pop(_keyController.text.trim());
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.featureFlagSubmitError(e.toString())),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewInsets = MediaQuery.of(context).viewInsets;
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isEdit
                    ? l10n.featureFlagSheetEditTitle
                    : l10n.featureFlagSheetCreateTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              if (!_isEdit) ...[
                _CatalogSelector(onSelected: _applySpec),
                const SizedBox(height: 16),
              ],
              TextFormField(
                controller: _keyController,
                enabled: !_isEdit,
                decoration: InputDecoration(
                  labelText: l10n.featureFlagKeyLabel,
                  hintText: l10n.featureFlagKeyHint,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'[a-z0-9_]'),
                  ),
                ],
                validator: (v) {
                  final s = v?.trim() ?? '';
                  if (s.isEmpty) return l10n.featureFlagKeyValidatorRequired;
                  if (!RegExp(r'^[a-z0-9_]+$').hasMatch(s)) {
                    return l10n.featureFlagKeyValidatorPattern;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: l10n.featureFlagTitleLabel,
                  hintText: l10n.featureFlagTitleHint,
                ),
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descController,
                decoration: InputDecoration(
                  labelText: l10n.featureFlagDescriptionLabel,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _categoryController,
                decoration: InputDecoration(
                  labelText: l10n.featureFlagCategoryLabel,
                  hintText: l10n.featureFlagCategoryHint,
                ),
              ),
              const SizedBox(height: 20),
              // Announcement section — collapsible block separated from
              // the technical config. Empty title = silent activation.
              _AnnouncementBlock(
                titleController: _announcementTitleController,
                bodyController: _announcementBodyController,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<FeatureRollout>(
                initialValue: _rollout,
                decoration: InputDecoration(
                  labelText: l10n.featureFlagRolloutLabel,
                ),
                items: FeatureRollout.values
                    .map((r) => DropdownMenuItem(
                          value: r,
                          child: Text(featureRolloutLabel(l10n, r)),
                        ))
                    .toList(),
                onChanged: (v) => setState(() => _rollout = v ?? _rollout),
              ),
              if (_rollout == FeatureRollout.beta) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.featureFlagBetaTestersTitle,
                  style: theme.textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _betaUidController,
                        decoration: InputDecoration(
                          hintText: l10n.featureFlagBetaUidHint,
                          isDense: true,
                        ),
                        onSubmitted: (_) => _addBetaUid(),
                      ),
                    ),
                    IconButton(
                      icon: const FaIcon(FontAwesomeIcons.plus, size: 14),
                      onPressed: _addBetaUid,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _betaUserIds
                      .map((uid) => Chip(
                            label: Text(
                              uid.length > 12 ? '${uid.substring(0, 12)}…' : uid,
                              style: const TextStyle(fontSize: 12),
                            ),
                            onDeleted: () => setState(
                                () => _betaUserIds.remove(uid)),
                          ))
                      .toList(),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: _submitting ? null : _submit,
                icon: _submitting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const FaIcon(FontAwesomeIcons.check, size: 14),
                label: Text(_submitting
                    ? l10n.featureFlagSubmitting
                    : (_isEdit
                        ? l10n.featureFlagSubmitUpdate
                        : l10n.featureFlagSubmitCreate)),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Dropdown that lets the admin pick a feature flag from the centralised
/// catalogue ([FeatureFlagKeys.all]). Selecting a spec calls [onSelected]
/// which pre-fills the parent form. Doesn't replace free-form input —
/// admins can still type a custom key for flags pending future features.
class _CatalogSelector extends StatefulWidget {
  final ValueChanged<FeatureFlagSpec> onSelected;
  const _CatalogSelector({required this.onSelected});

  @override
  State<_CatalogSelector> createState() => _CatalogSelectorState();
}

class _CatalogSelectorState extends State<_CatalogSelector> {
  FeatureFlagSpec? _value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    // Group specs by category for the dropdown sections.
    final groups = <String, List<FeatureFlagSpec>>{};
    for (final spec in FeatureFlagKeys.all) {
      groups.putIfAbsent(spec.category, () => []).add(spec);
    }
    final categories = groups.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: theme.colorScheme.outlineVariant,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              FaIcon(
                FontAwesomeIcons.list,
                size: 12,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                l10n.featureFlagCatalogSelectorTitle,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<FeatureFlagSpec>(
            initialValue: _value,
            isExpanded: true,
            decoration: InputDecoration(
              hintText: l10n.featureFlagCatalogSelectorHint,
              isDense: true,
            ),
            items: [
              for (final cat in categories) ...[
                DropdownMenuItem(
                  enabled: false,
                  child: Text(
                    cat.toUpperCase(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: theme.colorScheme.outline,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                ...groups[cat]!.map(
                  (spec) => DropdownMenuItem(
                    value: spec,
                    child: Text(spec.title, overflow: TextOverflow.ellipsis),
                  ),
                ),
              ],
            ],
            onChanged: (spec) {
              if (spec == null) return;
              setState(() => _value = spec);
              widget.onSelected(spec);
            },
          ),
          if (_value != null) ...[
            const SizedBox(height: 6),
            Text(
              _value!.description,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Section "Annonce in-app" du formulaire admin — un titre + un body
/// optionnels qui, s'ils sont remplis, déclenchent un bottomsheet
/// "Nouvelle fonctionnalité" la première fois qu'un user accède au
/// flag. Affichage replié par défaut pour ne pas cluttrer le form.
class _AnnouncementBlock extends StatefulWidget {
  final TextEditingController titleController;
  final TextEditingController bodyController;
  const _AnnouncementBlock({
    required this.titleController,
    required this.bodyController,
  });

  @override
  State<_AnnouncementBlock> createState() => _AnnouncementBlockState();
}

class _AnnouncementBlockState extends State<_AnnouncementBlock> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    // Auto-expand if either field already has content (edit mode).
    _expanded = widget.titleController.text.trim().isNotEmpty ||
        widget.bodyController.text.trim().isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.tertiaryContainer.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  FaIcon(
                    FontAwesomeIcons.bullhorn,
                    size: 12,
                    color: theme.colorScheme.tertiary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      l10n.featureAnnouncementSheetHeader,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: theme.colorScheme.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  FaIcon(
                    _expanded
                        ? FontAwesomeIcons.chevronUp
                        : FontAwesomeIcons.chevronDown,
                    size: 12,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
            ),
          ),
          if (_expanded) ...[
            const SizedBox(height: 8),
            Text(
              l10n.featureAnnouncementSheetHelp,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.outline,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.titleController,
              decoration: InputDecoration(
                labelText: l10n.featureAnnouncementSheetTitleLabel,
                hintText: l10n.featureAnnouncementSheetTitleHint,
                isDense: true,
              ),
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: widget.bodyController,
              decoration: InputDecoration(
                labelText: l10n.featureAnnouncementSheetBodyLabel,
                hintText: l10n.featureAnnouncementSheetBodyHint,
                isDense: true,
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
          ],
        ],
      ),
    );
  }
}
