import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import '../../config/responsive_config.dart';
import '../../widgets/common/app_loader.dart';
import '../../widgets/common/gradient_scaffold.dart';
import '../../widgets/common/snackbar/app_snackbar.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/messaging/chat_payment_banner.dart';
import '../../widgets/messaging/messaging_widgets_exports.dart';
import '../../core/blocs/session/session_bloc.dart';
import '../../core/blocs/booking/booking_exports.dart';
import 'chat_app_bar.dart';
import 'chat_business_object_card.dart';
import 'chat_input_controller.dart';

/// Écran de chat pour une conversation.
class ChatScreen extends StatefulWidget {
  final String conversationId;

  /// Fichier local à envoyer dès que la conversation s'ouvre, sans passer
  /// par le sélecteur de fichier — utilisé par le dossier d'enregistrement
  /// (StudioFolderScreen) pour un envoi direct à l'artiste.
  final String? initialAttachmentPath;

  const ChatScreen({
    super.key,
    required this.conversationId,
    this.initialAttachmentPath,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  late final MessagingBloc _messagingBloc;
  late final ChatInputController _input;
  bool _initialAttachmentSent = false;

  @override
  void initState() {
    super.initState();
    _messagingBloc = context.read<MessagingBloc>();
    _input = ChatInputController(conversationId: widget.conversationId)
      ..addListener(_onInputChanged);
    _messagingBloc.add(OpenConversationEvent(conversationId: widget.conversationId));
  }

  void _onInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _messagingBloc.add(const CloseConversationEvent());
    _input.removeListener(_onInputChanged);
    _input.dispose();
    super.dispose();
  }

  String get _currentUserId {
    final authState = context.read<AuthBloc>().state;
    return authState is AuthAuthenticatedState ? authState.user.id : '';
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MessagingBloc, MessagingState>(
      // sendError est transitoire (émis puis aussitôt cleared par le bloc) :
      // sans ce feedback, un envoi qui échoue (offline, rules) perd le
      // message en silence. Même listener déclenche l'envoi automatique du
      // fichier du dossier d'enregistrement, une fois la conversation
      // effectivement ouverte (StudioFolderScreen → initialAttachmentPath).
      listenWhen: (prev, curr) =>
          (curr is ChatOpenState && curr.sendError != null) ||
          (widget.initialAttachmentPath != null &&
              !_initialAttachmentSent &&
              curr is ChatOpenState),
      listener: (context, state) {
        if (state is! ChatOpenState) return;
        if (state.sendError != null) {
          AppSnackBar.error(
            context,
            AppLocalizations.of(context)!.messageSendFailed(state.sendError ?? ''),
          );
        }
        if (widget.initialAttachmentPath != null && !_initialAttachmentSent) {
          _initialAttachmentSent = true;
          _input.sendAttachment(context, File(widget.initialAttachmentPath!));
        }
      },
      builder: (context, state) {
        if (state is MessagingLoadingState) {
          return _buildLoadingScaffold();
        }
        if (state is MessagingErrorState) {
          return _buildErrorScaffold(state.message);
        }
        if (state is ChatOpenState) {
          return _buildChatScaffold(state);
        }
        return GradientScaffold(appBar: AppBar(), body: const SizedBox.shrink());
      },
    );
  }

  Widget _buildLoadingScaffold() {
    return GradientScaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.loading)),
      body: const AppLoader(),
    );
  }

  Widget _buildErrorScaffold(String message) {
    final theme = Theme.of(context);
    return GradientScaffold(
      appBar: AppBar(title: Text(AppLocalizations.of(context)!.error)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FaIcon(FontAwesomeIcons.circleExclamation, size: 48, color: theme.colorScheme.error),
            const SizedBox(height: 16),
            Text(message),
          ],
        ),
      ),
    );
  }

  Widget _buildChatScaffold(ChatOpenState state) {
    return GradientScaffold(
      appBar: ChatAppBar(conversation: state.conversation, currentUserId: _currentUserId),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: Responsive.maxContentWidth),
          child: Column(
            children: [
              ChatPaymentBanner(
                currentUserId: _currentUserId,
                participantIds: state.conversation.participantIds,
              ),
              Expanded(child: ChatView(
        conversation: state.conversation,
        messages: state.messages,
        currentUserId: _currentUserId,
        isLoadingMore: state.isLoadingMore,
        hasMoreMessages: state.hasMoreMessages,
        isSending: state.isSending,
        isRecording: _input.isRecording,
        showAudioPreview: _input.showAudioPreview,
        audioPreviewWidget: _input.showAudioPreview && _input.recordedAudioPath != null
            ? AudioPreviewWidget(
                audioPath: _input.recordedAudioPath!,
                duration: _input.recordingDuration,
                onSend: () => _input.sendAudioMessage(context),
                onDelete: _input.cancelAudioPreview,
              )
            : null,
        recordingOverlay: AudioRecordingOverlay(duration: _input.recordingDuration),
        onSendText: (text) => context.read<MessagingBloc>().add(SendTextMessageEvent(text: text)),
        onLoadMore: () => context.read<MessagingBloc>().add(const LoadMoreMessagesEvent()),
        onMessageLongPress: (message) => _showMessageOptions(message, state),
        onAttachmentTap: _handleAttachmentTap,
        onMicLongPressStart: () => _input.startRecording(context),
        onMicLongPressEnd: () => _input.stopRecording(context),
        businessObjectBuilder: (bo, isMe) => businessObjectCard(context, bo, isMe),
        reactionBuilder: (reactions, userId) => ReactionDisplay(
          reactions: reactions,
          currentUserId: userId,
          onReactionTap: (emoji) {
            final message = state.messages
                .where((m) => m.reactions == reactions)
                .firstOrNull;
            if (message == null) return;
            context.read<MessagingBloc>().add(ToggleReactionEvent(messageId: message.id, emoji: emoji));
          },
        ),
        onReactionTap: (message, emoji) {
          context.read<MessagingBloc>().add(ToggleReactionEvent(messageId: message.id, emoji: emoji));
        },
        floatingInput: true,
      )),
            ],
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(BaseMessage message, ChatOpenState state) {
    MessageOptionsSheet.show(
      context: context,
      message: message,
      isMe: message.senderId == _currentUserId,
      currentUserId: _currentUserId,
      onReactionTap: (emoji) {
        context.read<MessagingBloc>().add(ToggleReactionEvent(messageId: message.id, emoji: emoji));
      },
      onCopy: message.text != null && message.text!.isNotEmpty ? () {} : null,
      onDelete: message.senderId == _currentUserId && !message.isDeleted
          ? () => context.read<MessagingBloc>().add(DeleteMessageEvent(messageId: message.id))
          : null,
    );
  }

  void _handleAttachmentTap() {
    AttachmentOptionsSheet.show(
      context: context,
      onFilePickerTap: _showFilePicker,
      onBusinessObjectTap: _showBusinessObjectSelector,
    );
  }

  void _showFilePicker() {
    FilePickerBottomSheet.show(
      context,
      onFilePicked: (result) => _input.sendAttachment(context, result.file),
    );
  }

  void _showBusinessObjectSelector() {
    final sessions = context.read<SessionBloc>().state.sessions;
    final bookings = context.read<BookingBloc>().state.bookings;

    BusinessObjectSelectorBottomSheet.show(
      context,
      sessions: sessions,
      bookings: bookings,
      onSelected: (attachment) {
        context.read<MessagingBloc>().add(SendBusinessObjectMessageEvent(businessObject: attachment));
      },
    );
  }

}
