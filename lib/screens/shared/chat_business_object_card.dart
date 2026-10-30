import 'package:flutter/material.dart';
import 'package:smoothandesign_package/smoothandesign.dart';

import '../../widgets/messaging/messaging_widgets_exports.dart';

/// Carte affichée pour un message de type objet métier (session, booking)
/// — extrait de [ChatScreen] le 30/10/2026 (fichier passé au-delà des 250
/// lignes).
Widget businessObjectCard(BuildContext context, BusinessObjectAttachment bo, bool isMe) {
  switch (bo.objectType) {
    case 'session':
      return SessionMessageCard(businessObject: bo, isMe: isMe);
    case 'booking':
      return BookingMessageCard(businessObject: bo, isMe: isMe);
    default:
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(bo.title),
      );
  }
}
