import 'package:add_2_calendar/add_2_calendar.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/snackbar/app_snackbar.dart';

/// Bouton "Ajouter au calendrier" de l'écran de détail de session.
class SessionDetailAddToCalendarButton extends StatelessWidget {
  final Session session;
  final AppLocalizations l10n;

  const SessionDetailAddToCalendarButton({super.key, required this.session, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () => _addToCalendar(context),
        icon: const FaIcon(FontAwesomeIcons.calendarPlus, size: 16),
        label: Text(l10n.addToCalendar),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _addToCalendar(BuildContext context) {
    final event = Event(
      title: l10n.sessionCalendarTitle(session.typeLabel),
      description: session.notes ?? '',
      startDate: session.scheduledStart,
      endDate: session.scheduledEnd,
    );

    Add2Calendar.addEvent2Cal(event).then((success) {
      if (success && context.mounted) {
        AppSnackBar.success(context, l10n.addedToCalendar);
      }
    });
  }
}
