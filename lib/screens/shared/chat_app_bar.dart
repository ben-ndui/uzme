import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:go_router/go_router.dart';
import 'package:smoothandesign_package/smoothandesign.dart';

import '../../l10n/app_localizations.dart';

/// AppBar de [ChatScreen] — extrait le 30/10/2026 (fichier passé au-delà
/// des 250 lignes). Affiche l'avatar et le nom du correspondant, ou le
/// nombre de participants pour un groupe.
class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ChatAppBar({
    super.key,
    required this.conversation,
    required this.currentUserId,
  });

  final BaseConversation conversation;
  final String currentUserId;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final displayName = conversation.getDisplayName(currentUserId);
    final avatarUrl = conversation.getAvatarUrl(currentUserId);

    return AppBar(
      titleSpacing: 0,
      title: Row(
        children: [
          _Avatar(name: displayName, avatarUrl: avatarUrl),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(displayName, style: theme.textTheme.titleMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                if (conversation.type == ConversationType.group)
                  Text(
                    AppLocalizations.of(context)!.participants(conversation.participantIds.length),
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: () => context.push('/conversations/${conversation.id}/settings'),
          icon: const FaIcon(FontAwesomeIcons.circleInfo, size: 20),
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.avatarUrl});

  final String name;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (avatarUrl != null && avatarUrl!.isNotEmpty) {
      return CircleAvatar(radius: 20, backgroundImage: NetworkImage(avatarUrl!));
    }
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return CircleAvatar(
      radius: 20,
      backgroundColor: theme.colorScheme.primaryContainer,
      child: Text(initial, style: TextStyle(color: theme.colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600)),
    );
  }
}
