import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:smoothandesign_package/smoothandesign.dart';

import '../../l10n/app_localizations.dart';
import '../../widgets/common/permission_dialog.dart';
import '../../widgets/common/snackbar/app_snackbar.dart';

/// Enregistrement audio et envoi de pièces jointes pour [ChatScreen] —
/// extrait le 30/10/2026 (fichier passé au-delà des 250 lignes). Les
/// méthodes prennent un [BuildContext] transitoire (vérifié `.mounted`
/// après chaque `await`) plutôt que de le stocker, pour rester un simple
/// [ChangeNotifier] sans dépendre du cycle de vie du widget.
class ChatInputController extends ChangeNotifier {
  ChatInputController({
    required this.conversationId,
    MessagingStorageService? storageService,
    AudioRecordService? audioService,
  })  : _storageService = storageService ?? MessagingStorageService(),
        _audioService = audioService ?? AudioRecordService();

  final String conversationId;
  final MessagingStorageService _storageService;
  final AudioRecordService _audioService;

  bool isRecording = false;
  int recordingDuration = 0;
  Timer? _recordingTimer;
  String? recordedAudioPath;
  bool showAudioPreview = false;
  bool isUploading = false;

  Future<void> startRecording(BuildContext context) async {
    final granted = await PermissionDialog.requestPermission(
      context,
      type: AppPermissionType.microphone,
    );
    if (!granted) return;

    try {
      final tempDir = await getTemporaryDirectory();
      final filePath =
          '${tempDir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _audioService.startRecording(filePath);

      isRecording = true;
      recordingDuration = 0;
      notifyListeners();

      _recordingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
        recordingDuration++;
        notifyListeners();
      });
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, 'Erreur enregistrement: $e');
    }
  }

  Future<void> stopRecording(BuildContext context) async {
    if (!isRecording) return;
    _recordingTimer?.cancel();

    try {
      final path = await _audioService.stopRecording();
      isRecording = false;
      recordedAudioPath = path;
      showAudioPreview = path != null && recordingDuration >= 1;
      notifyListeners();

      if (recordingDuration < 1) {
        cancelAudioPreview();
        if (context.mounted) {
          AppSnackBar.warning(context, AppLocalizations.of(context)!.recordingTooShort);
        }
      }
    } catch (e) {
      isRecording = false;
      notifyListeners();
      if (context.mounted) AppSnackBar.error(context, 'Erreur arrêt enregistrement: $e');
    }
  }

  Future<void> sendAudioMessage(BuildContext context) async {
    if (recordedAudioPath == null || isUploading) return;
    isUploading = true;
    notifyListeners();

    try {
      final result = await _storageService.uploadAudio(
        file: File(recordedAudioPath!),
        conversationId: conversationId,
        durationSeconds: recordingDuration,
      );

      if (!context.mounted) return;

      if (result.isSuccess && result.data != null) {
        context.read<MessagingBloc>().add(SendAudioMessageEvent(audio: result.data!));
        cancelAudioPreview();
      } else {
        AppSnackBar.error(context, result.message);
      }
    } catch (e) {
      if (context.mounted) AppSnackBar.error(context, 'Erreur envoi audio: $e');
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  void cancelAudioPreview() {
    if (recordedAudioPath != null) {
      final file = File(recordedAudioPath!);
      if (file.existsSync()) file.deleteSync();
    }
    recordedAudioPath = null;
    showAudioPreview = false;
    recordingDuration = 0;
    notifyListeners();
  }

  /// Utilisé par le sélecteur de fichier ET par l'envoi direct depuis le
  /// dossier d'enregistrement (StudioFolderScreen).
  Future<void> sendAttachment(BuildContext context, File file) async {
    isUploading = true;
    notifyListeners();

    try {
      final uploadResult = await _storageService.uploadFile(
        file: file,
        conversationId: conversationId,
      );
      if (!context.mounted) return;
      if (uploadResult.isSuccess && uploadResult.data != null) {
        context.read<MessagingBloc>().add(SendAttachmentMessageEvent(attachment: uploadResult.data!));
      } else {
        AppSnackBar.error(context, uploadResult.message);
      }
    } finally {
      isUploading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _recordingTimer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
