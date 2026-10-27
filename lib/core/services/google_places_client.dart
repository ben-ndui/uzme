import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/services/env_service.dart';
import 'package:uzme/core/utils/app_logger.dart';

/// Appels bruts à l'API Google Places (Nearby/Text Search, Details,
/// Geocoding) — aucune logique métier ici (ça vit dans
/// [StudioDiscoveryService]), juste parler à Google et parser sa réponse.
class GooglePlacesClient {
  GooglePlacesClient({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  String get _apiKey => EnvService.googleMapsApiKey;

  static const String _nearbyUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

  /// Google Place types that strongly indicate the result is NOT a
  /// recording studio (music shops, schools, churches, etc.). The legacy
  /// Places API doesn't have a `recording_studio` type, so we filter
  /// post-response — Places API (New) exposes `recording_studio` natively
  /// and would let us skip this list entirely.
  static const _excludedPlaceTypes = {
    'music_store',
    'electronics_store',
    'department_store',
    'shopping_mall',
    'school',
    'university',
    'library',
    'church',
    'place_of_worship',
    'restaurant',
    'cafe',
    'bar',
    'museum',
    'tourist_attraction',
  };

  /// Substrings (case-insensitive) in the place name that strongly suggest
  /// a non-studio business — backstop for cases where Google didn't tag
  /// the proper type (e.g. a music shop tagged only `establishment`).
  static const _excludedNamePatterns = [
    'magasin',
    'boutique',
    ' shop',
    'store',
    'école',
    'ecole',
    'school',
    'conservatoire',
    'cours de',
    'cours-de',
    'musée',
    'museum',
    'instruments de musique',
  ];

  bool _isLikelyRecordingStudio(Map<String, dynamic> place) {
    final types = (place['types'] as List?)?.map((e) => e.toString()).toList() ??
        const [];
    for (final blacklisted in _excludedPlaceTypes) {
      if (types.contains(blacklisted)) return false;
    }
    final name = (place['name']?.toString() ?? '').toLowerCase();
    for (final pattern in _excludedNamePatterns) {
      if (name.contains(pattern)) return false;
    }
    return true;
  }

  Future<List<DiscoveredStudio>> searchNearby(
    LatLng position,
    int radius,
  ) async {
    final url = Uri.parse(
      '$_nearbyUrl?location=${position.latitude},${position.longitude}'
      '&radius=$radius'
      '&keyword=recording+studio+enregistrement'
      '&type=establishment'
      '&key=$_apiKey',
    );

    final response =
        await _httpClient.get(url).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Google returns HTTP 200 with status:REQUEST_DENIED / OVER_QUERY_LIMIT
      // when the API key is rejected / quota exceeded — surface those so we
      // don't keep debugging a silent empty list.
      _logStatusIfError(data, requestType: 'NearbySearch');
      final results = data['results'] as List? ?? [];

      return results
          .whereType<Map<String, dynamic>>()
          .where(_isLikelyRecordingStudio)
          .map((place) => DiscoveredStudio.fromGooglePlace(place))
          .where((s) => s.position.latitude != 0)
          .toList();
    }

    throw Exception('Failed to fetch studios: ${response.statusCode}');
  }

  /// Find a place (typically a studio) by free-text query using the Google
  /// Places Text Search API. Used when the user types a studio name that
  /// isn't in the currently loaded nearby list — Text Search ranks by
  /// relevance worldwide and tolerates approximate / unaccented spellings.
  Future<DiscoveredStudio?> searchByText(String query) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/textsearch/json'
      '?query=${Uri.encodeComponent(query)}'
      '&key=$_apiKey',
    );

    try {
      final response =
          await _httpClient.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        appLog('⚠️ Places TextSearch HTTP ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      _logStatusIfError(data, requestType: 'TextSearch');

      final results = data['results'] as List? ?? [];
      if (results.isEmpty) return null;

      // Top result — Text Search ranks by relevance.
      return DiscoveredStudio.fromGooglePlace(results.first);
    } catch (e) {
      appLog('⚠️ Places TextSearch error: $e');
      return null;
    }
  }

  /// Get place details by place ID, photos included (up to the 5 kept by
  /// [DiscoveredStudio.fromGooglePlace]) — appelé uniquement à l'ouverture
  /// d'un bottom sheet, jamais depuis une liste.
  Future<DiscoveredStudio?> getDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=name,formatted_address,geometry,rating,user_ratings_total,'
      'formatted_phone_number,website,photos'
      '&key=$_apiKey',
    );

    try {
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['result'];
        if (result != null) {
          return DiscoveredStudio.fromGooglePlace(result);
        }
      }
    } catch (e) {
      appLog('⚠️ Places Details error: $e');
    }
    return null;
  }

  /// Galerie photo complète d'un lieu — ne demande QUE le champ `photos`
  /// (contrairement à [getDetails]) pour ne pas payer les champs Contact
  /// (téléphone, site) et Atmosphere (note, avis) alors qu'on veut juste
  /// des images. Retourne `null` sur échec réseau (à distinguer de « zéro
  /// photo », qui est une liste vide).
  Future<List<String>?> getPhotoUrls(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=photos'
      '&key=$_apiKey',
    );

    try {
      final response = await _httpClient.get(url);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logStatusIfError(data, requestType: 'Details(photos)');
        final result = data['result'];
        if (result != null) {
          return DiscoveredStudio.fromGooglePlace(result).photoUrls;
        }
      }
    } catch (e) {
      appLog('⚠️ Places Details(photos) error: $e');
    }
    return null;
  }

  Future<LatLng?> geocodeAddress(String address) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=${Uri.encodeComponent(address)}'
      '&key=$_apiKey',
    );

    try {
      final response =
          await _httpClient.get(url).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logStatusIfError(data, requestType: 'Geocoding');
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          return LatLng(
            location['lat'] as double,
            location['lng'] as double,
          );
        }
      }
    } catch (e) {
      appLog('⚠️ Geocoding error: $e');
    }

    return null;
  }

  /// Log Google API non-OK statuses so we can debug REQUEST_DENIED /
  /// OVER_QUERY_LIMIT / INVALID_REQUEST without rebuilds. ZERO_RESULTS is
  /// a normal "not found" outcome and is intentionally silent.
  void _logStatusIfError(dynamic data, {required String requestType}) {
    final status = data['status']?.toString();
    if (status == null || status == 'OK' || status == 'ZERO_RESULTS') return;
    final errorMessage = data['error_message']?.toString() ?? '';
    appLog(
      '⚠️ Google Places $requestType non-OK: $status'
      '${errorMessage.isNotEmpty ? ' — $errorMessage' : ''}',
    );
  }
}
