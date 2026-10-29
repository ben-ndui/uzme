import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/core/services/session_payment_service.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/common/cancel_session_sheet.dart';
import 'package:uzme/widgets/common/snackbar/app_snackbar.dart';

/// Bouton "Annuler la session" de l'écran de détail de session, avec la
/// feuille de remboursement si un paiement a déjà eu lieu.
class SessionDetailCancelButton extends StatelessWidget {
  final Session session;
  final AppLocalizations l10n;

  const SessionDetailCancelButton({super.key, required this.session, required this.l10n});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _showCancelConfirmation(context),
        icon: const FaIcon(FontAwesomeIcons.xmark, size: 16),
        label: Text(l10n.cancelSession),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.red,
          side: BorderSide(color: Colors.red.withValues(alpha: 0.5)),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  void _showCancelConfirmation(BuildContext context) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticatedState) return;

    // If payment was made, show full cancel sheet with refund preview
    if (session.hasPaymentTracking &&
        session.paymentStatus != PaymentStatus.none) {
      final result = await CancelSessionSheet.show(
        context,
        session: session,
        isCancelledByStudio: false,
      );
      if (result == null || !context.mounted) return;

      // Call backend for refund + cancel
      try {
        await SessionPaymentService().requestRefund(
          sessionId: session.id,
          userId: authState.user.uid,
          reason: result.reason,
          customReason: result.customReason,
          isCancelledByStudio: false,
        );
        if (context.mounted) {
          AppSnackBar.success(context, l10n.sessionCancelledNoRefund);
        }
      } catch (e) {
        if (context.mounted) {
          AppSnackBar.error(context, l10n.paymentFailed);
        }
      }
      return;
    }

    // No payment — simple cancel dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.cancelSession),
        content: Text(l10n.confirmCancelSession),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancel)),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.read<SessionBloc>().add(UpdateSessionStatusEvent(sessionId: session.id, status: SessionStatus.cancelled));
            },
            child: Text(l10n.confirm, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
