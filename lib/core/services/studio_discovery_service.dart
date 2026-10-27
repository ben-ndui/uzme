import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/services/google_places_client.dart';
import 'package:uzme/core/services/location_service.dart';
import 'package:uzme/core/services/studio_partner_source.dart';
import 'package:uzme/core/utils/app_logger.dart';

/// Service for discovering studios nearby using Google Places API + Firestore partners
class StudioDiscoveryService {
  static final StudioDiscoveryService _instance =
      StudioDiscoveryService._internal();
  factory StudioDiscoveryService({
    FirebaseFirestore? firestore,
    LocationService? locationService,
    http.Client? httpClient,
    GooglePlacesClient? placesClient,
  }) {
    if (firestore != null ||
        locationService != null ||
        httpClient != null ||
        placesClient != null) {
      final resolvedFirestore = firestore ?? FirebaseFirestore.instance;
      final resolvedLocationService = locationService ?? LocationService();
      return StudioDiscoveryService._di(
        locationService: resolvedLocationService,
        places: placesClient ?? GooglePlacesClient(httpClient: httpClient),
        partners: StudioPartnerSource(
          firestore: resolvedFirestore,
          locationService: resolvedLocationService,
        ),
      );
    }
    return _instance;
  }
  StudioDiscoveryService._internal()
      : _locationService = LocationService(),
        _places = GooglePlacesClient(),
        _partners = StudioPartnerSource(
          firestore: FirebaseFirestore.instance,
          locationService: LocationService(),
        );
  StudioDiscoveryService._di({
    required LocationService locationService,
    required GooglePlacesClient places,
    required StudioPartnerSource partners,
  })  : _locationService = locationService,
        _places = places,
        _partners = partners;

  final LocationService _locationService;
  final GooglePlacesClient _places;
  final StudioPartnerSource _partners;

  // Cache studios for 25 minutes per position
  List<DiscoveredStudio>? _cachedStudios;
  DateTime? _cacheTime;
  LatLng? _cachedPosition;
  static const Duration _cacheDuration = Duration(minutes: 25);
  static const double _cacheDistanceThreshold = 2000; // 2km

  // Cache des galeries photo par placeId — l'appel Details ne doit se faire
  // qu'une fois par studio Google, jamais depuis la liste/carte (coût API).
  final Map<String, Future<List<String>>> _photoCache = {};

  /// Search for recording studios nearby (Google Places + Firestore partners)
  Future<List<DiscoveredStudio>> findNearbyStudios(
    LatLng position, {
    int radius = 5000,
    bool forceRefresh = false,
  }) async {
    // Check cache - invalidate if position changed significantly
    final isCacheValid = !forceRefresh &&
        _cachedStudios != null &&
        _cacheTime != null &&
        _cachedPosition != null &&
        DateTime.now().difference(_cacheTime!) < _cacheDuration &&
        _locationService.distanceBetween(_cachedPosition!, position) <
            _cacheDistanceThreshold;

    if (isCacheValid) {
      return _updateDistances(_cachedStudios!, position);
    }

    try {
      // Fetch Google Places
      final googleStudios = await _places.searchNearby(position, radius);

      // Merge with partner studios (filters out claimed Google Places)
      List<DiscoveredStudio> mergedStudios;
      try {
        mergedStudios = await _partners.mergeWithClaims(
          googleStudios,
          position,
          radius,
        );
      } catch (e) {
        appLog('⚠️ StudioDiscoveryService: merge failed, using Google Places only: $e');
        mergedStudios = googleStudios;
      }

      _cachedStudios = mergedStudios;
      _cacheTime = DateTime.now();
      _cachedPosition = position;
      return _updateDistances(mergedStudios, position);
    } catch (e, stackTrace) {
      appLog('⚠️ StudioDiscoveryService: findNearbyStudios error: $e');
      appLog('⚠️ StackTrace: $stackTrace');
      // Return cached if available, otherwise empty list
      if (_cachedStudios != null) {
        return _updateDistances(_cachedStudios!, position);
      }
      return [];
    }
  }

  /// Find a place (typically a studio) by free-text query.
  Future<DiscoveredStudio?> searchByText(String query) =>
      _places.searchByText(query);

  List<DiscoveredStudio> _updateDistances(
    List<DiscoveredStudio> studios,
    LatLng userPosition,
  ) {
    return studios.map((studio) {
      final distance = _locationService.distanceBetween(
        userPosition,
        studio.position,
      );
      return studio.copyWithDistance(distance);
    }).toList()
      ..sort((a, b) {
        // Pioneers en premier
        if (a.isPioneer && !b.isPioneer) return -1;
        if (!a.isPioneer && b.isPioneer) return 1;
        // Puis partenaires
        if (a.isPartner && !b.isPartner) return -1;
        if (!a.isPartner && b.isPartner) return 1;
        // Puis tri par distance croissante
        return (a.distanceMeters ?? double.infinity)
            .compareTo(b.distanceMeters ?? double.infinity);
      });
  }

  /// Get studio details by place ID
  Future<DiscoveredStudio?> getStudioDetails(String placeId) =>
      _places.getDetails(placeId);

  /// Galerie photo complète d'un studio, pour le header du bottom sheet.
  ///
  /// Partenaire ou pro : la liste vient déjà de Firestore, rien à appeler.
  /// Studio Google : Nearby/Text Search ne rendent jamais plus d'UNE photo,
  /// donc `studio.photoUrls` non vide ne veut pas dire "galerie complète" —
  /// on appelle toujours Details une fois, sauf court-circuit partenaire/pro
  /// ci-dessus. Le `Future` lui-même est caché (pas juste son résultat) pour
  /// dédupliquer un double appel si le bottom sheet est fermé puis rouvert
  /// avant la première réponse, et retiré du cache en cas d'échec réseau
  /// pour ne pas figer la galerie à une photo pour le reste de la session.
  Future<List<String>> getStudioPhotoUrls(DiscoveredStudio studio) {
    if (studio.isPartner || studio.isPro) return Future.value(studio.photoUrls);

    return _photoCache.putIfAbsent(
      studio.id,
      () => _fetchGooglePhotoUrls(studio),
    );
  }

  Future<List<String>> _fetchGooglePhotoUrls(DiscoveredStudio studio) async {
    final urls = await _places.getPhotoUrls(studio.id);
    if (urls == null) {
      _photoCache.remove(studio.id);
      return studio.photoUrl != null ? [studio.photoUrl!] : const [];
    }
    return urls.isNotEmpty
        ? urls
        : (studio.photoUrl != null ? [studio.photoUrl!] : const []);
  }

  /// Clear cache
  void clearCache() {
    _cachedStudios = null;
    _cacheTime = null;
    _cachedPosition = null;
    _photoCache.clear();
  }

  /// Geocode an address to coordinates
  Future<LatLng?> geocodeAddress(String address) =>
      _places.geocodeAddress(address);
}
