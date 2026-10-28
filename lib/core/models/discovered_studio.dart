import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/google_review.dart';
import 'package:uzme/core/models/studio_profile.dart';
import 'package:uzme/core/services/env_service.dart';

/// Studio discovered via location-based search (Google Places or internal DB)
class DiscoveredStudio {
  final String id;
  final String name;
  final String? address;
  final LatLng position;
  final double? rating;
  final int? reviewCount;
  final String? photoUrl;
  final List<String> photoUrls;

  /// Crédit Google par photo — même longueur/ordre que [photoUrls], `null`
  /// quand Google n'a fourni aucune attribution (toujours le cas hors Google,
  /// ex. partenaire/pro). Les CGU Places imposent de créditer le·a photographe.
  final List<String?> photoAttributions;

  /// Jusqu'à 5 avis Google (triés "plus récents" côté requête) — toujours
  /// vide pour un partenaire/pro, dont les données ne viennent pas de Google.
  final List<GoogleReview> reviews;
  final String? phoneNumber;
  final String? website;
  final bool isPartner; // Studio registered on Use Me
  final bool isVerified; // Studio verified by Use Me team
  final bool isPro; // Professional profile (not a studio)
  final bool isPioneer;
  final int? pioneerNumber;
  final List<String> services;
  final double? distanceMeters;
  final StudioType studioType;

  const DiscoveredStudio({
    required this.id,
    required this.name,
    this.address,
    required this.position,
    this.rating,
    this.reviewCount,
    this.photoUrl,
    this.photoUrls = const [],
    this.photoAttributions = const [],
    this.reviews = const [],
    this.phoneNumber,
    this.website,
    this.isPartner = false,
    this.isVerified = false,
    this.isPro = false,
    this.isPioneer = false,
    this.pioneerNumber,
    this.services = const [],
    this.distanceMeters,
    this.studioType = StudioType.independent,
  });

  /// Nombre max de photos Google ramenées pour la galerie du bottom sheet —
  /// au-delà, ça n'ajoute rien à l'écran et ça gonfle la requête Details.
  static const _maxGooglePhotos = 5;

  /// Create from Google Places API response
  factory DiscoveredStudio.fromGooglePlace(Map<String, dynamic> json) {
    final location = json['geometry']?['location'];
    final photos = (json['photos'] as List?)?.take(_maxGooglePhotos).toList();
    final photoUrls = photos == null
        ? const <String>[]
        : photos.map((p) => _buildPhotoUrl(p['photo_reference'])).toList();
    final photoAttributions = photos == null
        ? const <String?>[]
        : photos.map(_firstAttribution).toList();
    final reviewsJson = json['reviews'] as List?;
    final reviews = reviewsJson == null
        ? const <GoogleReview>[]
        : reviewsJson
              .whereType<Map<String, dynamic>>()
              .map(GoogleReview.fromJson)
              .toList();

    return DiscoveredStudio(
      id: json['place_id'] ?? '',
      name: json['name'] ?? 'Studio inconnu',
      address: json['vicinity'] ?? json['formatted_address'],
      position: LatLng(
        location?['lat']?.toDouble() ?? 0,
        location?['lng']?.toDouble() ?? 0,
      ),
      rating: json['rating']?.toDouble(),
      reviewCount: json['user_ratings_total'],
      reviews: reviews,
      photoUrl: photoUrls.isNotEmpty ? photoUrls.first : null,
      photoUrls: photoUrls,
      photoAttributions: photoAttributions,
      isPartner: false,
      isVerified: false,
    );
  }

  /// Google rend `html_attributions` sous forme de lien HTML (ex.
  /// `<a href="...">Jean Dupont</a>`) — on ne garde que le texte affichable.
  static String? _firstAttribution(dynamic photo) {
    final attributions = photo['html_attributions'] as List?;
    if (attributions == null || attributions.isEmpty) return null;
    final text = attributions.first
        .toString()
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .trim();
    return text.isEmpty ? null : text;
  }

  /// Create from internal Firestore document
  factory DiscoveredStudio.fromFirestore(Map<String, dynamic> json, String id) {
    final studioPhotos = _studioProfilePhotos(json['studioProfile']);
    final singlePhoto =
        json['photoURL'] ??
        json['photoUrl'] ??
        (studioPhotos.isNotEmpty ? studioPhotos.first : null);

    return DiscoveredStudio(
      id: id,
      name: json['name'] ?? json['displayName'] ?? 'Studio',
      address: json['address'],
      position: LatLng(
        (json['latitude'] ?? json['lat'] ?? 0).toDouble(),
        (json['longitude'] ?? json['lng'] ?? 0).toDouble(),
      ),
      rating: json['rating']?.toDouble(),
      reviewCount: json['reviewCount'],
      photoUrl: singlePhoto,
      photoUrls: studioPhotos.isNotEmpty
          ? studioPhotos
          : (singlePhoto != null ? [singlePhoto] : const []),
      phoneNumber: json['phoneNumber'],
      website: json['website'],
      isPartner: true,
      isVerified: json['isVerified'] ?? false,
      isPioneer:
          json['pioneer'] != null &&
          (json['pioneer'] as Map)['isPioneer'] == true,
      pioneerNumber: json['pioneer'] != null
          ? (json['pioneer'] as Map)['pioneerNumber'] as int?
          : null,
      services: List<String>.from(json['services'] ?? []),
      studioType: StudioType.fromString(json['studioType'] as String?),
    );
  }

  /// Create from AppUser with ProProfile (for map display)
  factory DiscoveredStudio.fromProUser(AppUser user) {
    final profile = user.proProfile!;
    final loc = profile.location!;
    return DiscoveredStudio(
      id: 'pro_${user.uid}',
      name: profile.displayName,
      address: profile.city,
      position: LatLng(loc.latitude, loc.longitude),
      rating: profile.rating,
      reviewCount: profile.reviewCount,
      photoUrl: user.displayPhotoUrl,
      photoUrls: user.displayPhotoUrl != null
          ? [user.displayPhotoUrl!]
          : const [],
      phoneNumber: profile.phone,
      website: profile.website,
      isPartner: false,
      isVerified: profile.isVerified,
      isPro: true,
      isPioneer: user.isPioneer,
      pioneerNumber: user.pioneerNumber,
      services: profile.proTypes.map((t) => t.label).toList(),
    );
  }

  /// The userId behind a pro marker (strips 'pro_' prefix)
  String? get proUserId => isPro ? id.replaceFirst('pro_', '') : null;

  /// Copy with distance
  DiscoveredStudio copyWithDistance(double distance) {
    return copyWith(distanceMeters: distance);
  }

  DiscoveredStudio copyWith({
    List<String>? photoUrls,
    String? photoUrl,
    double? distanceMeters,
  }) {
    return DiscoveredStudio(
      id: id,
      name: name,
      address: address,
      position: position,
      rating: rating,
      reviewCount: reviewCount,
      photoUrl: photoUrl ?? this.photoUrl,
      photoUrls: photoUrls ?? this.photoUrls,
      photoAttributions: photoAttributions,
      reviews: reviews,
      phoneNumber: phoneNumber,
      website: website,
      isPartner: isPartner,
      isVerified: isVerified,
      isPro: isPro,
      isPioneer: isPioneer,
      pioneerNumber: pioneerNumber,
      services: services,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      studioType: studioType,
    );
  }

  /// Format distance for display
  String get formattedDistance {
    if (distanceMeters == null) return '';
    if (distanceMeters! < 1000) {
      return '${distanceMeters!.round()} m';
    }
    return '${(distanceMeters! / 1000).toStringAsFixed(1)} km';
  }

  static List<String> _studioProfilePhotos(dynamic studioProfile) {
    if (studioProfile is Map) {
      final photos = studioProfile['photos'];
      if (photos is List) {
        return photos.map((p) => p.toString()).toList();
      }
    }
    return const [];
  }

  static String _buildPhotoUrl(String photoReference) {
    final apiKey = EnvService.googleMapsApiKey;
    return 'https://maps.googleapis.com/maps/api/place/photo'
        '?maxwidth=400&photo_reference=$photoReference&key=$apiKey';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoveredStudio &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
