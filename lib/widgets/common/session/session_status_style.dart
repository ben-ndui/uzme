import 'package:flutter/material.dart';
import 'package:uzme/core/models/session.dart';

/// Couleur canonique d'un statut de session — à utiliser PARTOUT où un
/// statut est affiché (chip, badge, point, en-tête de section).
///
/// Avant ce fichier, la même valeur de [SessionStatus] avait une couleur
/// différente selon l'écran — confirmée en bleu sur certains, en vert sur
/// d'autres. Relevé par Ben le 28/10/2026, vérifié dans
/// `artist_session_detail_screen.dart`, `artist_session_tile.dart` et
/// `pro_bookings_received_screen.dart` (qui inversaient confirmed/inProgress
/// par rapport à la majorité des écrans).
extension SessionStatusColor on SessionStatus {
  Color get color {
    switch (this) {
      case SessionStatus.pending:
        return Colors.orange;
      case SessionStatus.confirmed:
        return Colors.blue;
      case SessionStatus.inProgress:
        return Colors.green;
      case SessionStatus.completed:
        return Colors.grey;
      case SessionStatus.cancelled:
      case SessionStatus.noShow:
        return Colors.red;
    }
  }
}
