import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_folder_watcher/smoothandesign_folder_watcher.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/services/studio_folder_preferences.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/app_loader.dart';
import 'package:uzme/widgets/common/studio_folder_file_tile.dart';
import 'package:uzme/widgets/messaging/conversation_picker_sheet.dart';

/// Dossier d'enregistrement surveillé — macOS uniquement
/// (DirectorySurveillance / Xplor, repris le 30/10/2026).
///
/// Ouvert depuis les réglages ingénieur OU studio (Ben, 30/10/2026 : « c'est
/// une fonctionnalité qui peut être utilisée par les studios aussi ») —
/// n'importe quel compte peut enregistrer et envoyer ses fichiers, le
/// dossier choisi est scopé par uid, pas par rôle.
///
/// Choisir un dossier, voir les fichiers apparaître en direct, les envoyer
/// à un artiste sans ouvrir le chat.
class StudioFolderScreen extends StatefulWidget {
  const StudioFolderScreen({super.key});

  @override
  State<StudioFolderScreen> createState() => _StudioFolderScreenState();
}

class _StudioFolderScreenState extends State<StudioFolderScreen> {
  String? _path;
  List<WatchedFile> _files = const [];
  bool _loading = true;
  StreamSubscription<FolderFileChange>? _changesSubscription;

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticatedState ? authState.user.id : '';
  }

  @override
  void initState() {
    super.initState();
    _loadSavedFolder();
  }

  @override
  void dispose() {
    _changesSubscription?.cancel();
    SmoothFolderWatcher.stopWatching();
    super.dispose();
  }

  Future<void> _loadSavedFolder() async {
    final saved = await StudioFolderPreferences.load(_currentUserId);
    if (saved != null) {
      await _watch(saved.path, saved.bookmark);
    } else if (mounted) {
      setState(() => _loading = false);
    }
  }

  Future<void> _pickFolder() async {
    final picked = await SmoothFolderWatcher.pickDirectory();
    if (picked == null) return; // annulé
    await StudioFolderPreferences.save(_currentUserId, picked.path, picked.bookmark);
    await _watch(picked.path, picked.bookmark);
  }

  Future<void> _watch(String path, Uint8List bookmark) async {
    setState(() {
      _path = path;
      _loading = true;
    });

    final files = await SmoothFolderWatcher.listFiles(bookmark);
    if (!mounted) return;
    setState(() {
      _files = files;
      _loading = false;
    });

    await SmoothFolderWatcher.startWatching(bookmark);
    _changesSubscription?.cancel();
    _changesSubscription = SmoothFolderWatcher.changes.listen((_) async {
      // Un seul fichier bouge, mais relister reste simple et sûr : un
      // dossier de session n'a jamais assez de fichiers pour que ça coûte
      // cher, et ça évite de recalculer un diff create/modify/rename à la
      // main depuis le Dart.
      final refreshed = await SmoothFolderWatcher.listFiles(bookmark);
      if (mounted) setState(() => _files = refreshed);
    });
  }

  Future<void> _sendFile(WatchedFile file) async {
    final conversation = await ConversationPickerSheet.show(
      context,
      currentUserId: _currentUserId,
    );
    if (conversation == null || !mounted) return;

    // Ouvre le chat avec le fichier pré-attaché : ChatScreen l'envoie dès
    // que la conversation est effectivement ouverte (initialAttachmentPath).
    context.push('/conversations/${conversation.id}', extra: file.path);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.studioFolderTitle)),
      body: _loading
          ? const AppLoader()
          : _path == null
              ? _buildEmptyState(l10n, theme)
              : _buildFolderContent(l10n, theme),
    );
  }

  Widget _buildEmptyState(AppLocalizations l10n, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            FaIcon(FontAwesomeIcons.folderOpen, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 24),
            Text(
              l10n.studioFolderDescription,
              textAlign: TextAlign.center,
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _pickFolder,
              icon: const FaIcon(FontAwesomeIcons.folderPlus, size: 16),
              label: Text(l10n.studioFolderChoose),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFolderContent(AppLocalizations l10n, ThemeData theme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _path!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              TextButton(onPressed: _pickFolder, child: Text(l10n.studioFolderChange)),
            ],
          ),
        ),
        Expanded(
          child: _files.isEmpty
              ? Center(
                  child: Text(
                    l10n.studioFolderEmpty,
                    style: TextStyle(color: theme.colorScheme.onSurfaceVariant),
                  ),
                )
              : ListView.builder(
                  itemCount: _files.length,
                  itemBuilder: (context, index) {
                    final file = _files[index];
                    return StudioFolderFileTile(
                      file: file,
                      onSend: () => _sendFile(file),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
