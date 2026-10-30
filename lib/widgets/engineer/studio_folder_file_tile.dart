import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_folder_watcher/smoothandesign_folder_watcher.dart';
import 'package:uzme/l10n/app_localizations.dart';

/// Une ligne du dossier d'enregistrement : nom du fichier, taille, date de
/// modification, et le bouton pour l'envoyer à un artiste.
class StudioFolderFileTile extends StatelessWidget {
  const StudioFolderFileTile({
    super.key,
    required this.file,
    required this.onSend,
  });

  final WatchedFile file;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return ListTile(
      leading: FaIcon(FontAwesomeIcons.fileAudio, color: theme.colorScheme.primary),
      title: Text(file.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        '${_formatSize(file.sizeBytes)} · ${_formatDate(file.modifiedAt)}',
        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
      ),
      trailing: TextButton.icon(
        onPressed: onSend,
        icon: const FaIcon(FontAwesomeIcons.paperPlane, size: 14),
        label: Text(l10n.studioFolderSend),
      ),
    );
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes o';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} Ko';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} Mo';
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final sameDay = date.year == now.year && date.month == now.month && date.day == now.day;
    final time = '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    if (sameDay) return time;
    return '${date.day}/${date.month} $time';
  }
}
