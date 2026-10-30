import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/app_loader.dart';
import 'package:uzme/widgets/messaging/uzme_conversation_tile.dart';

/// Feuille de choix d'une conversation existante — utilisée pour envoyer un
/// fichier du dossier d'enregistrement directement à un artiste, sans
/// ouvrir le chat.
class ConversationPickerSheet extends StatelessWidget {
  const ConversationPickerSheet({super.key, required this.currentUserId});

  final String currentUserId;

  /// Retourne la conversation choisie, ou `null` si l'utilisateur annule.
  static Future<BaseConversation?> show(
    BuildContext context, {
    required String currentUserId,
  }) {
    return showModalBottomSheet<BaseConversation>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ConversationPickerSheet(currentUserId: currentUserId),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: FractionallySizedBox(
        heightFactor: 0.7,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.studioFolderSendTitle,
                style: theme.textTheme.titleLarge,
              ),
            ),
            Expanded(
              child: BlocBuilder<MessagingBloc, MessagingState>(
                builder: (context, state) {
                  if (state is MessagingLoadingState) {
                    return const AppLoader();
                  }
                  if (state is! ConversationsLoadedState ||
                      state.conversations.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text(
                          l10n.studioFolderNoConversations,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    );
                  }

                  final conversations = state.conversations
                      .where((c) => c.type == ConversationType.private)
                      .toList();

                  return ListView.builder(
                    itemCount: conversations.length,
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return UzmeConversationTile(
                        conversation: conversation,
                        currentUserId: currentUserId,
                        onTap: () => Navigator.of(context).pop(conversation),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
