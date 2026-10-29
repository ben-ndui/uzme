import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/config/responsive_config.dart';
import 'package:uzme/core/localization/intl_locale.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/artist/session_detail/session_detail_exports.dart';
import 'package:uzme/widgets/common/app_loader.dart';
import 'package:uzme/widgets/common/error_retry_compact.dart';
import 'package:uzme/widgets/common/payment_tracking_card.dart';
import 'package:uzme/widgets/common/session/session_exports.dart';
import 'package:uzme/widgets/common/session_pay_button.dart';

/// Session detail screen for artists to view their booked sessions
class ArtistSessionDetailScreen extends StatefulWidget {
  final String sessionId;

  const ArtistSessionDetailScreen({super.key, required this.sessionId});

  @override
  State<ArtistSessionDetailScreen> createState() => _ArtistSessionDetailScreenState();
}

class _ArtistSessionDetailScreenState extends State<ArtistSessionDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sessionDetails),
        backgroundColor: theme.colorScheme.surface,
      ),
      // Stream from Firestore for real-time payment status updates
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('useme_sessions')
            .doc(widget.sessionId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoader();
          }

          // Distinguer erreur du stream et session inexistante : afficher
          // « Aucune session » sur une erreur est trompeur (la session
          // est visible dans la liste juste derrière).
          if (snapshot.hasError) {
            return ErrorRetryCompact(onRetry: () => setState(() {}));
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Center(
              child: Text(l10n.noSession, style: theme.textTheme.bodyLarge),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          data['id'] = snapshot.data!.id;
          final session = Session.fromMap(data);

          return _ArtistSessionDetailContent(session: session, l10n: l10n);
        },
      ),
    );
  }
}

class _ArtistSessionDetailContent extends StatelessWidget {
  final Session session;
  final AppLocalizations l10n;

  const _ArtistSessionDetailContent({required this.session, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = intlLocale(context);
    final dateFormat = DateFormat('EEEE d MMMM yyyy', locale);
    final timeFormat = DateFormat('HH:mm', locale);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: ResponsiveContainer(
        maxWidth: Responsive.maxFormWidth,
        padding: EdgeInsets.zero,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SessionDetailStatusBadge(status: session.displayStatus, l10n: l10n),
          const SizedBox(height: 24),
          SessionStudioInfoCard(session: session, l10n: l10n),
          const SizedBox(height: 12),
          SessionDetailInfoCard(
            icon: FontAwesomeIcons.calendar,
            title: l10n.dateAndTime,
            value: '${dateFormat.format(session.scheduledStart)}\n'
                '${timeFormat.format(session.scheduledStart)} - ${timeFormat.format(session.scheduledEnd)}',
            theme: theme,
          ),
          const SizedBox(height: 12),
          SessionDetailInfoCard(
            icon: FontAwesomeIcons.clock,
            title: l10n.duration,
            value: '${session.durationMinutes ~/ 60}h${session.durationMinutes % 60 > 0 ? ' ${session.durationMinutes % 60}min' : ''}',
            theme: theme,
          ),
          const SizedBox(height: 12),
          SessionDetailInfoCard(
            icon: FontAwesomeIcons.music,
            title: l10n.sessionType,
            value: session.typeLabel,
            theme: theme,
          ),
          const SizedBox(height: 12),
          if (session.hasRoom)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SessionDetailInfoCard(
                icon: FontAwesomeIcons.doorOpen,
                title: l10n.rooms,
                value: session.roomName ?? '-',
                theme: theme,
              ),
            ),
          if (session.hasEngineer)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SessionDetailEngineerCard(session: session, l10n: l10n, theme: theme),
            ),
          if (!session.hasEngineer && session.status == SessionStatus.pending)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: SessionDetailPendingEngineerCard(l10n: l10n, theme: theme),
            ),
          if (session.notes != null && session.notes!.isNotEmpty)
            SessionDetailInfoCard(
              icon: FontAwesomeIcons.noteSticky,
              title: l10n.notesOptional,
              value: session.notes!,
              theme: theme,
            ),
          // Payment tracking + pay button
          if (session.hasPaymentTracking) ...[
            const SizedBox(height: 16),
            PaymentTrackingCard(session: session),
            const SizedBox(height: 12),
            Builder(builder: (ctx) {
              final authState = ctx.read<AuthBloc>().state;
              if (authState is! AuthAuthenticatedState) {
                return const SizedBox.shrink();
              }
              return SessionPayButton(
                session: session,
                userId: authState.user.uid,
              );
            }),
          ],
          if (!session.isPast &&
              session.displayStatus != SessionStatus.cancelled &&
              session.displayStatus != SessionStatus.noShow) ...[
            const SizedBox(height: 24),
            SessionDetailAddToCalendarButton(session: session, l10n: l10n),
          ],
          const SizedBox(height: 12),
          if (session.canBeCancelled)
            SessionDetailCancelButton(session: session, l10n: l10n),
        ],
      ),
      ),
    );
  }
}
