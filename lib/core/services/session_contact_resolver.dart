import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uzme/core/models/models_exports.dart';
import 'package:uzme/core/services/pro_profile_service.dart';

/// De quoi contacter l'autre partie d'une session : écrire, l'appeler si un
/// numéro est renseigné, et s'y rendre si une position est connue (jamais le
/// cas pour un pro freelance, qui n'a pas d'adresse fixe).
class SessionContact {
  final String userId;
  final String name;
  final String? avatarUrl;
  final String role;
  final bool isPioneer;
  final String? phone;
  final String? address;
  final LatLng? location;

  const SessionContact({
    required this.userId,
    required this.name,
    this.avatarUrl,
    required this.role,
    this.isPioneer = false,
    this.phone,
    this.address,
    this.location,
  });
}

/// Résout le contact d'une session : le pro freelance si c'est une session
/// pro, le studio sinon. Contrairement à `resolveSessionLocation`, on
/// interroge toujours le profil (le téléphone et l'avatar ne sont jamais
/// dénormalisés sur la session, seul le nom l'est).
Future<SessionContact?> resolveSessionContact(
  Session session, {
  ProProfileService? profileService,
}) async {
  final targetId = session.isProSession ? session.proId : session.studioId;
  if (targetId == null || targetId.isEmpty) return null;

  final user = await (profileService ?? ProProfileService()).getUser(targetId);
  if (user == null) return null;

  final name = session.isProSession
      ? (session.proName ?? user.displayName ?? user.name ?? 'Pro')
      : user.studioDisplayName;
  final phone = session.isProSession ? user.phoneNumber : user.studioProfile?.phone;
  final geoPoint = session.isProSession ? null : user.studioProfile?.location;

  return SessionContact(
    userId: user.uid,
    name: name,
    avatarUrl: user.photoURL,
    role: user.role.useMeLabel,
    isPioneer: user.isPioneer,
    phone: (phone != null && phone.isNotEmpty) ? phone : null,
    address: session.isProSession ? null : user.studioProfile?.address,
    location: geoPoint != null ? LatLng(geoPoint.latitude, geoPoint.longitude) : null,
  );
}
