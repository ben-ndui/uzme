import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';

/// uzme-specific conversation tile that augments the shared list row
/// with a role chip + avatar role-colored overlay. Pulls the role from
/// `BaseConversation.participantDetails[otherId].role` — no extra
/// Firestore reads, just rendering signals already on the doc.
///
/// Skipped enrichment for v1 :
/// - Pioneer badge (would require denormalising `pioneer.isPioneer`
///   onto `ParticipantInfo`, separate backend sprint).
/// - Booking-related indicator (would join with `useme_sessions`).
class UzmeConversationTile extends StatelessWidget {
  final BaseConversation conversation;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const UzmeConversationTile({
    super.key,
    required this.conversation,
    required this.currentUserId,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final unreadCount = conversation.getUnreadCount(currentUserId);
    final hasUnread = unreadCount > 0;
    final displayName = conversation.getDisplayName(currentUserId);
    final avatarUrl = conversation.getAvatarUrl(currentUserId);
    final otherRole = _resolveOtherRole();

    return ListTile(
      onTap: onTap,
      onLongPress: onLongPress,
      leading: _Avatar(
        name: displayName,
        avatarUrl: avatarUrl,
        roleAccent: _roleAccent(otherRole),
        roleIcon: _roleIcon(otherRole),
      ),
      title: Row(
        children: [
          Flexible(
            child: Text(
              displayName,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (otherRole != null) ...[
            const SizedBox(width: 6),
            _RoleChip(role: otherRole),
          ],
        ],
      ),
      subtitle: _buildSubtitle(theme, hasUnread),
      trailing: _buildTrailing(theme, unreadCount),
    );
  }

  /// Resolves the role of the OTHER participant in a private
  /// conversation. Returns null for group chats / missing data.
  BaseUserRole? _resolveOtherRole() {
    if (conversation.type != ConversationType.private) return null;
    final otherId = conversation.participantIds.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    if (otherId.isEmpty) return null;
    final info = conversation.participantDetails[otherId];
    final raw = info?.role;
    if (raw == null) return null;
    for (final r in BaseUserRole.values) {
      if (r.name == raw) return r;
    }
    return null;
  }

  Color? _roleAccent(BaseUserRole? role) {
    switch (role) {
      case BaseUserRole.client:
        return const Color(0xFF8B5CF6); // purple — Artiste
      case BaseUserRole.admin:
        return const Color(0xFFFFB800); // gold — Studio
      case BaseUserRole.worker:
        return const Color(0xFF10B981); // emerald — Ingé son
      default:
        return null;
    }
  }

  IconData? _roleIcon(BaseUserRole? role) {
    switch (role) {
      case BaseUserRole.client:
        return FontAwesomeIcons.music;
      case BaseUserRole.admin:
        return FontAwesomeIcons.buildingUser;
      case BaseUserRole.worker:
        return FontAwesomeIcons.headphones;
      default:
        return null;
    }
  }

  Widget? _buildSubtitle(ThemeData theme, bool hasUnread) {
    final lastMessage = conversation.lastMessage;
    if (lastMessage == null) return null;
    final isMyMessage = lastMessage.senderId == currentUserId;

    return Row(
      children: [
        if (isMyMessage) ...[
          _LastMessageStatus(
            conversation: conversation,
            currentUserId: currentUserId,
          ),
          const SizedBox(width: 4),
        ],
        Expanded(
          child: Text(
            lastMessage.text,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: hasUnread
                  ? theme.colorScheme.onSurface
                  : theme.colorScheme.onSurfaceVariant,
              fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildTrailing(ThemeData theme, int unreadCount) {
    final lastMessage = conversation.lastMessage;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (lastMessage != null)
          Text(
            _formatTime(lastMessage.sentAt),
            style: theme.textTheme.bodySmall?.copyWith(
              color: unreadCount > 0
                  ? theme.colorScheme.primary
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        if (unreadCount > 0) ...[
          const SizedBox(height: 4),
          Container(
            constraints: const BoxConstraints(minWidth: 20),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              unreadCount > 99 ? '99+' : unreadCount.toString(),
              style: theme.textTheme.labelSmall?.copyWith(
                color: theme.colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:'
          '${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Hier';
    } else if (diff.inDays < 7) {
      const days = ['Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam', 'Dim'];
      return days[date.weekday - 1];
    } else {
      return '${date.day}/${date.month}';
    }
  }
}

/// Avatar with an optional role-colored overlay badge in the
/// bottom-right corner. Mirrors the shared CircleAvatar layout but
/// adds a small disc + role icon when [roleIcon] is provided.
class _Avatar extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final Color? roleAccent;
  final IconData? roleIcon;

  const _Avatar({
    required this.name,
    required this.avatarUrl,
    required this.roleAccent,
    required this.roleIcon,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return SizedBox(
      width: 48,
      height: 48,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (avatarUrl != null && avatarUrl!.isNotEmpty)
            CircleAvatar(
              radius: 24,
              backgroundImage: NetworkImage(avatarUrl!),
            )
          else
            CircleAvatar(
              radius: 24,
              backgroundColor: theme.colorScheme.primaryContainer,
              child: Text(
                initial,
                style: TextStyle(
                  color: theme.colorScheme.onPrimaryContainer,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (roleIcon != null && roleAccent != null)
            Positioned(
              bottom: -2,
              right: -2,
              child: Container(
                width: 20,
                height: 20,
                decoration: BoxDecoration(
                  color: roleAccent,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: theme.colorScheme.surface,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: FaIcon(
                    roleIcon,
                    size: 8,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final BaseUserRole role;
  const _RoleChip({required this.role});

  @override
  Widget build(BuildContext context) {
    final (label, color) = _label(role);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w700,
          fontSize: 10,
        ),
      ),
    );
  }

  (String, Color) _label(BaseUserRole role) {
    switch (role) {
      case BaseUserRole.client:
        return ('Artiste', const Color(0xFF8B5CF6));
      case BaseUserRole.admin:
        return ('Studio', const Color(0xFFFFB800));
      case BaseUserRole.worker:
        return ('Ingé', const Color(0xFF10B981));
      default:
        return (role.name, Colors.grey);
    }
  }
}

/// Single/double check status indicator for messages I sent. Same
/// logic as the shared widget — kept inline because we needed a
/// custom title row above.
class _LastMessageStatus extends StatelessWidget {
  final BaseConversation conversation;
  final String currentUserId;
  const _LastMessageStatus({
    required this.conversation,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final otherIds = conversation.participantIds
        .where((id) => id != currentUserId)
        .toList();
    final isRead = conversation.getUnreadCount(currentUserId) == 0 &&
        otherIds.isNotEmpty;
    return Icon(
      isRead ? Icons.done_all : Icons.check,
      size: 16,
      color: isRead
          ? theme.colorScheme.primary
          : theme.colorScheme.onSurfaceVariant,
    );
  }
}
