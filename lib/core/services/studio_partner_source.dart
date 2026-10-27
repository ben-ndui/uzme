import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/services/location_service.dart';
import 'package:uzme/core/utils/app_logger.dart';

/// Studios et pros internes à UZME (partenaires Firestore) — en séparé de
/// [StudioDiscoveryService] car ce sont deux sources de données distinctes
/// (notre base vs Google Places), mergées ensemble par le service.
class StudioPartnerSource {
  StudioPartnerSource({
    required FirebaseFirestore firestore,
    required LocationService locationService,
  })  : _firestore = firestore,
        _locationService = locationService;

  final FirebaseFirestore _firestore;
  final LocationService _locationService;

  /// Fusionne les studios Google avec les partenaires/pros internes, et
  /// retire les Google Places déjà revendiqués par un partenaire.
  Future<List<DiscoveredStudio>> mergeWithClaims(
    List<DiscoveredStudio> googleStudios,
    LatLng position,
    int radius,
  ) async {
    if (FirebaseAuth.instance.currentUser == null) return googleStudios;

    // Fetch partner studios (admin or superAdmin with isPartner)
    // Note: Firestore doesn't support OR in where, so we query isPartner only
    // and filter by role in Dart
    final query = await _firestore
        .collection('users')
        .where('isPartner', isEqualTo: true)
        .get()
        .timeout(
          const Duration(seconds: 10),
          onTimeout: () {
            appLog('⚠️ StudioPartnerSource: Timeout fetching partners');
            throw Exception('Timeout');
          },
        );

    final partnerStudios = <DiscoveredStudio>[];
    final claimedGooglePlaceIds = <String>{};

    for (final doc in query.docs) {
      try {
        final user = AppUser.fromMap(doc.data(), doc.id);
        // Only include admin or superAdmin roles
        if (!user.isStudio && !user.isSuperAdmin) continue;

        if (user.studioProfile != null) {
          // Track claimed Google Place ID
          if (user.studioProfile!.googlePlaceId != null) {
            claimedGooglePlaceIds.add(user.studioProfile!.googlePlaceId!);
          }
          // Add partner if has location and is within radius
          if (user.studioProfile!.location != null) {
            final studio = _partnerToDiscoveredStudio(user);
            final distance =
                _locationService.distanceBetween(position, studio.position);
            if (distance <= radius) {
              partnerStudios.add(studio);
            }
          }
        }
      } catch (e) {
        appLog('⚠️ StudioPartnerSource: Error parsing partner ${doc.id}: $e');
      }
    }

    // Fetch pro profiles with location
    final proStudios = await _fetchNearbyPros(position, radius);

    // Filter out Google studios that are claimed
    final filteredGoogle = googleStudios
        .where((s) => !claimedGooglePlaceIds.contains(s.id))
        .toList();

    // Partner studios first, then pros, then remaining Google studios
    return [...partnerStudios, ...proStudios, ...filteredGoogle];
  }

  /// Convert AppUser (partner) to DiscoveredStudio
  DiscoveredStudio _partnerToDiscoveredStudio(AppUser user) {
    final profile = user.studioProfile!;
    return DiscoveredStudio(
      id: user.uid, // Use user ID as studio ID for booking
      name: profile.name,
      address:
          profile.fullAddress.isNotEmpty ? profile.fullAddress : profile.address,
      position: LatLng(
        profile.location!.latitude,
        profile.location!.longitude,
      ),
      rating: profile.rating,
      reviewCount: profile.reviewCount,
      photoUrl: profile.photos.isNotEmpty ? profile.photos.first : user.photoURL,
      photoUrls: profile.photos.isNotEmpty
          ? profile.photos
          : (user.photoURL != null ? [user.photoURL!] : const []),
      phoneNumber: profile.phone ?? user.phoneNumber,
      website: profile.website,
      isPartner: true,
      isPioneer: user.pioneer?.isPioneer ?? false,
      services: profile.services,
    );
  }

  /// Fetch available pro profiles with a location within radius.
  Future<List<DiscoveredStudio>> _fetchNearbyPros(
    LatLng position,
    int radius,
  ) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('proProfile.isAvailable', isEqualTo: true)
          .get()
          .timeout(const Duration(seconds: 10));

      final pros = <DiscoveredStudio>[];
      for (final doc in query.docs) {
        try {
          final user = AppUser.fromMap(doc.data(), doc.id);
          if (!user.hasProProfile || !user.proProfile!.hasLocation) continue;

          final studio = DiscoveredStudio.fromProUser(user);
          final distance =
              _locationService.distanceBetween(position, studio.position);
          if (distance <= radius) {
            pros.add(studio);
          }
        } catch (e) {
          appLog('⚠️ StudioPartnerSource: Error parsing pro ${doc.id}: $e');
        }
      }
      return pros;
    } catch (e) {
      appLog('⚠️ StudioPartnerSource: Error fetching pros: $e');
      return [];
    }
  }
}
