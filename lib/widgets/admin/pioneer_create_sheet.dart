import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:uzme/core/models/pioneer_program.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/main.dart' show pioneerService;

/// Modal sheet to create a new Pioneer cohort. Submits a draft program
/// (status='draft'). Pops with the new programId on success so the
/// caller can navigate to the detail screen.
class PioneerCreateSheet extends StatefulWidget {
  const PioneerCreateSheet({super.key});

  @override
  State<PioneerCreateSheet> createState() => _PioneerCreateSheetState();
}

class _PioneerCreateSheetState extends State<PioneerCreateSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _targetCountController = TextEditingController(text: '100');
  DateTime _deadline = DateTime.now().add(const Duration(days: 30));
  double _wSessions = 5;
  double _wMessages = 1;
  double _wDays = 2;
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _targetCountController.dispose();
    super.dispose();
  }

  Future<void> _pickDeadline() async {
    final locale = Localizations.localeOf(context);
    final picked = await showDatePicker(
      context: context,
      initialDate: _deadline,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      locale: locale,
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() => _submitting = true);
    final messenger = ScaffoldMessenger.of(context);
    final errorColor = Theme.of(context).colorScheme.error;
    try {
      final programId = await pioneerService.createProgram(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        targetCount: int.parse(_targetCountController.text),
        deadline: _deadline,
        weights: PioneerWeights(
          confirmedSessions: _wSessions.round(),
          messagesSent: _wMessages.round(),
          activeDays: _wDays.round(),
        ),
      );
      if (mounted) Navigator.of(context).pop(programId);
    } catch (e) {
      if (mounted) setState(() => _submitting = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(l10n.adminPioneerCreateError(e.toString())),
          backgroundColor: errorColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;
    final locale = Localizations.localeOf(context).toString();
    final df = DateFormat('d MMMM yyyy', locale);
    final viewInsets = MediaQuery.of(context).viewInsets;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + viewInsets.bottom),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.adminPioneerCreateTitle,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: l10n.adminPioneerCreateNameLabel,
                  hintText: l10n.adminPioneerCreateNameHint,
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? l10n.adminPioneerCreateNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descriptionController,
                decoration: InputDecoration(
                  labelText: l10n.adminPioneerCreateDescLabel,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetCountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: l10n.adminPioneerCreateTopNLabel,
                      ),
                      validator: (v) {
                        final n = int.tryParse(v ?? '');
                        if (n == null || n < 1 || n > 5000) {
                          return l10n.adminPioneerCreateTopNError;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: InkWell(
                      onTap: _pickDeadline,
                      borderRadius: BorderRadius.circular(4),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: l10n.adminPioneerCreateDeadlineLabel,
                          suffixIcon: const Icon(
                            Icons.calendar_today,
                            size: 18,
                          ),
                        ),
                        child: Text(df.format(_deadline)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                l10n.adminPioneerCreateWeightsTitle,
                style: theme.textTheme.titleSmall,
              ),
              const SizedBox(height: 4),
              Text(
                l10n.adminPioneerCreateWeightsFormula(
                  _wSessions.round(),
                  _wMessages.round(),
                  _wDays.round(),
                ),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
              const SizedBox(height: 12),
              _WeightSlider(
                label: l10n.adminPioneerCreateWeightSessions,
                icon: FontAwesomeIcons.calendarCheck,
                value: _wSessions,
                onChanged: (v) => setState(() => _wSessions = v),
              ),
              _WeightSlider(
                label: l10n.adminPioneerCreateWeightMessages,
                icon: FontAwesomeIcons.message,
                value: _wMessages,
                onChanged: (v) => setState(() => _wMessages = v),
              ),
              _WeightSlider(
                label: l10n.adminPioneerCreateWeightDays,
                icon: FontAwesomeIcons.fire,
                value: _wDays,
                onChanged: (v) => setState(() => _wDays = v),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _submitting ? null : _submit,
                  icon: _submitting
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const FaIcon(FontAwesomeIcons.check, size: 14),
                  label: Text(
                    _submitting
                        ? l10n.adminPioneerCreateSubmitting
                        : l10n.adminPioneerCreateSubmit,
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WeightSlider extends StatelessWidget {
  final String label;
  final FaIconData icon;
  final double value;
  final ValueChanged<double> onChanged;

  const _WeightSlider({
    required this.label,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          FaIcon(icon, size: 14, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.bodyMedium),
                Slider(
                  value: value,
                  min: 0,
                  max: 10,
                  divisions: 10,
                  label: value.round().toString(),
                  onChanged: onChanged,
                ),
              ],
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '×${value.round()}',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
