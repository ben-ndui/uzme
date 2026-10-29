import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/core/services/services_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/artist/engineer_selector_bottom_sheet.dart';
import 'package:uzme/widgets/artist/session_request/session_request_exports.dart';
import 'package:uzme/config/responsive_config.dart';
import 'package:uzme/widgets/common/snackbar/app_snackbar.dart';
import 'package:uzme/core/utils/app_logger.dart';

/// Session request form for artists to request new sessions
class SessionRequestScreen extends StatefulWidget {
  final String? studioId;
  final String? studioName;

  const SessionRequestScreen({super.key, this.studioId, this.studioName});

  @override
  State<SessionRequestScreen> createState() => _SessionRequestScreenState();
}

class _SessionRequestScreenState extends State<SessionRequestScreen> {
  final _notesController = TextEditingController();
  final _sessionService = SessionService();
  final _roomService = StudioRoomService();

  final Set<SessionType> _selectedTypes = {SessionType.recording};
  DateTime? _selectedDate;
  EnhancedTimeSlot? _selectedSlot;
  AvailableEngineer? _selectedEngineer;
  StudioRoom? _selectedRoom;
  List<StudioRoom> _availableRooms = [];
  bool _loadingRooms = false;
  int _durationHours = 2;
  bool _isSubmitting = false;
  WorkingHours? _studioWorkingHours;
  bool _allowNoEngineer = false;
  String? _studioAddress;

  @override
  void initState() {
    super.initState();
    if (widget.studioId != null) {
      _loadRooms();
      _loadStudioProfile();
    }
  }

  Future<void> _loadStudioProfile() async {
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(widget.studioId).get();
      if (doc.exists) {
        final data = doc.data();
        final studioProfileData = data?['studioProfile'] as Map<String, dynamic>?;
        if (studioProfileData != null) {
          setState(() {
            if (studioProfileData['workingHours'] != null) {
              _studioWorkingHours = WorkingHours.fromMap(
                studioProfileData['workingHours'] as Map<String, dynamic>,
              );
            }
            _allowNoEngineer = studioProfileData['allowNoEngineer'] ?? false;
            _studioAddress = studioProfileData['address']?.toString();
          });
        }
      }
    } catch (e) {
      appLog('Erreur chargement profil studio: $e');
    }
  }

  Future<void> _loadRooms() async {
    setState(() => _loadingRooms = true);
    try {
      final rooms = await _roomService.getActiveRoomsByStudio(widget.studioId!);
      setState(() {
        _availableRooms = rooms;
        _loadingRooms = false;
      });
    } catch (e) {
      setState(() => _loadingRooms = false);
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.studioName != null ? l10n.sessionAt(widget.studioName!) : l10n.sessionRequest),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxFormWidth),
          child: widget.studioId == null
              ? SessionRequestNoStudioState(l10n: l10n, onBack: () => context.pop())
              : SessionRequestFormBody(
                  l10n: l10n,
                  studioId: widget.studioId!,
                  selectedTypes: _selectedTypes,
                  onTypesChanged: (types) => setState(() => _selectedTypes
                    ..clear()
                    ..addAll(types)),
                  durationHours: _durationHours,
                  onDurationChanged: (hours) => setState(() {
                    _durationHours = hours;
                    _selectedSlot = null;
                    _selectedEngineer = null;
                  }),
                  availableRooms: _availableRooms,
                  selectedRoom: _selectedRoom,
                  loadingRooms: _loadingRooms,
                  onRoomSelected: (room) => setState(() {
                    _selectedRoom = room;
                    if (room != null && !room.requiresEngineer) _selectedEngineer = null;
                  }),
                  studioWorkingHours: _studioWorkingHours,
                  allowNoEngineer: _allowNoEngineer,
                  selectedDate: _selectedDate,
                  selectedSlot: _selectedSlot,
                  onSlotSelected: (date, slot) => setState(() {
                    _selectedDate = date;
                    _selectedSlot = slot;
                    _selectedEngineer = null;
                  }),
                  selectedEngineer: _selectedEngineer,
                  onShowEngineerSelector: () => _showEngineerSelector(context),
                  notesController: _notesController,
                  canSubmit: _canSubmit,
                  isSubmitting: _isSubmitting,
                  onSubmit: () => _submitRequest(l10n),
                ),
        ),
      ),
    );
  }

  Future<void> _showEngineerSelector(BuildContext context) async {
    if (_selectedSlot == null) return;
    final selected = await EngineerSelectorBottomSheet.show(
      context,
      _selectedSlot!.availableEngineers,
      selectedEngineer: _selectedEngineer,
    );
    if (mounted) setState(() => _selectedEngineer = selected);
  }

  bool get _canSubmit => _selectedSlot != null && !_isSubmitting;

  Future<void> _submitRequest(AppLocalizations l10n) async {
    if (!_canSubmit) return;

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticatedState) return;

    setState(() => _isSubmitting = true);

    try {
      final session = Session(
        id: '',
        studioId: widget.studioId!,
        studioName: widget.studioName,
        studioAddress: _studioAddress,
        roomId: _selectedRoom?.id,
        roomName: _selectedRoom?.name,
        artistIds: [authState.user.uid],
        artistNames: [authState.user.name ?? 'Artiste'],
        types: _selectedTypes.toList(),
        status: SessionStatus.pending,
        scheduledStart: _selectedSlot!.start,
        scheduledEnd: _selectedSlot!.end,
        durationMinutes: _durationHours * 60,
        engineerId: _selectedEngineer?.user.uid,
        engineerName: _selectedEngineer?.user.name,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final response = await _sessionService.createSession(session);

      if (mounted) {
        if (response.code == 200) {
          AppSnackBar.success(context, l10n.requestSent);
          context.pop();
        } else {
          AppSnackBar.error(context, response.message);
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.error(context, 'Error: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
