import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/core/services/pro_profile_service.dart';

/// Où a lieu une session : un nom et, si connue, une adresse.
class SessionLocation {
  final String name;
  final String? address;

  const SessionLocation(this.name, [this.address]);
}

/// Résout le lieu d'une session : le pro freelance si c'est une session pro
/// (toujours dénormalisé, zéro lecture), sinon le studio dénormalisé, sinon
/// un lookup Firestore pour les sessions créées avant le 29/10/2026 (date à
/// laquelle `studioName`/`studioAddress` ont été ajoutés à la création).
///
/// Retourne `null` si vraiment rien n'est identifiable. Laisse remonter
/// l'exception d'un lookup raté : à l'appelant de décider quoi en faire
/// (ne jamais l'avaler en silence, cf. pieges-flutter-recurrents.md).
Future<SessionLocation?> resolveSessionLocation(
  Session session, {
  ProProfileService? profileService,
}) async {
  if (session.isProSession) {
    final name = session.proName;
    return name != null && name.isNotEmpty ? SessionLocation(name) : null;
  }

  if (session.studioName != null && session.studioName!.isNotEmpty) {
    return SessionLocation(session.studioName!, session.studioAddress);
  }

  if (session.studioId.isEmpty) return null;

  final user = await (profileService ?? ProProfileService()).getUser(session.studioId);
  if (user == null) return null;
  return SessionLocation(user.studioDisplayName, user.studioProfile?.address);
}
