import 'package:flutter/material.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/core/services/availability_service.dart';
import 'package:uzme/core/services/engineer_availability_service.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/artist/availability_picker.dart';
import 'package:uzme/widgets/artist/session_request/session_request_exports.dart';

/// Corps du formulaire de réservation : type, durée, salle, créneau,
/// ingénieur, notes et résumé. Extrait de `SessionRequestScreen` pour rester
/// sous la limite de 250 lignes (charte readability.md).
class SessionRequestFormBody extends StatelessWidget {
  final AppLocalizations l10n;
  final String studioId;

  final Set<SessionType> selectedTypes;
  final ValueChanged<Set<SessionType>> onTypesChanged;

  final int durationHours;
  final ValueChanged<int> onDurationChanged;

  final List<StudioRoom> availableRooms;
  final StudioRoom? selectedRoom;
  final bool loadingRooms;
  final ValueChanged<StudioRoom?> onRoomSelected;

  final WorkingHours? studioWorkingHours;
  final bool allowNoEngineer;
  final DateTime? selectedDate;
  final EnhancedTimeSlot? selectedSlot;
  final void Function(DateTime date, EnhancedTimeSlot slot) onSlotSelected;

  final AvailableEngineer? selectedEngineer;
  final VoidCallback onShowEngineerSelector;

  final TextEditingController notesController;

  final bool canSubmit;
  final bool isSubmitting;
  final VoidCallback onSubmit;

  const SessionRequestFormBody({
    super.key,
    required this.l10n,
    required this.studioId,
    required this.selectedTypes,
    required this.onTypesChanged,
    required this.durationHours,
    required this.onDurationChanged,
    required this.availableRooms,
    required this.selectedRoom,
    required this.loadingRooms,
    required this.onRoomSelected,
    required this.studioWorkingHours,
    required this.allowNoEngineer,
    required this.selectedDate,
    required this.selectedSlot,
    required this.onSlotSelected,
    required this.selectedEngineer,
    required this.onShowEngineerSelector,
    required this.notesController,
    required this.canSubmit,
    required this.isSubmitting,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    return Form(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SessionRequestInfoCard(text: l10n.slotInfoText),
          const SizedBox(height: 24),
          SessionRequestSectionTitle(l10n.sessionType),
          const SizedBox(height: 8),
          SessionTypeSelector(
            selectedTypes: selectedTypes,
            onTypesChanged: (types) => onTypesChanged({...types}),
          ),
          const SizedBox(height: 24),
          SessionRequestSectionTitle(l10n.sessionDuration),
          const SizedBox(height: 8),
          SessionDurationSelector(
            selectedHours: durationHours,
            onChanged: onDurationChanged,
          ),
          const SizedBox(height: 24),
          if (availableRooms.isNotEmpty) ...[
            SessionRequestSectionTitle(l10n.selectRoom),
            const SizedBox(height: 8),
            SessionRoomSelector(
              availableRooms: availableRooms,
              selectedRoom: selectedRoom,
              isLoading: loadingRooms,
              onRoomSelected: onRoomSelected,
            ),
            const SizedBox(height: 24),
          ],
          SessionRequestSectionTitle(l10n.chooseSlot),
          const SizedBox(height: 8),
          AvailabilityPicker(
            studioId: studioId,
            durationMinutes: durationHours * 60,
            workingHours: studioWorkingHours,
            allowNoEngineer: allowNoEngineer,
            onSlotSelected: onSlotSelected,
          ),
          const SizedBox(height: 24),
          if (selectedSlot != null &&
              selectedSlot!.availableEngineers.isNotEmpty &&
              (selectedRoom == null || selectedRoom!.requiresEngineer)) ...[
            SessionRequestSectionTitle(l10n.engineerPreference),
            const SizedBox(height: 8),
            SessionEngineerSelector(
              selectedEngineer: selectedEngineer,
              availableCount: selectedSlot!.availableCount,
              onTap: onShowEngineerSelector,
            ),
            const SizedBox(height: 24),
          ],
          if (selectedRoom != null && !selectedRoom!.requiresEngineer) ...[
            const SelfServiceInfoCard(),
            const SizedBox(height: 24),
          ],
          SessionRequestSectionTitle(l10n.notesOptional),
          const SizedBox(height: 8),
          TextFormField(
            controller: notesController,
            maxLines: 3,
            decoration: InputDecoration(hintText: l10n.describeProject),
          ),
          const SizedBox(height: 32),
          if (selectedSlot != null && selectedDate != null)
            SessionRequestSummary(
              date: selectedDate!,
              slotStart: selectedSlot!.start,
              slotEnd: selectedSlot!.end,
              selectedRoom: selectedRoom,
              selectedEngineer: selectedEngineer,
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: canSubmit ? onSubmit : null,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Text(l10n.sendRequest),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
