import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/models/google_review.dart';
import 'package:uzme/core/services/env_service.dart';
import 'package:uzme/core/services/google_place_type_filter.dart';
import 'package:uzme/core/utils/app_logger.dart';

/// Appels bruts à l'API Google Places (Nearby/Text Search, Details,
/// Geocoding) — aucune logique métier ici (ça vit dans
/// [StudioDiscoveryService]), juste parler à Google et parser sa réponse.
/// Résultat du SEUL appel Details(Atmosphere) qu'on fait par studio Google :
/// galerie photo (+ attribution par photo, voir [DiscoveredStudio.photoAttributions])
/// et avis — tout part dans la même requête, jamais depuis la liste/carte.
class GooglePhotoGallery {
  const GooglePhotoGallery(
    this.urls,
    this.attributions, {
    this.reviews = const [],
  });
  final List<String> urls;
  final List<String?> attributions;
  final List<GoogleReview> reviews;
}

class GooglePlacesClient {
  GooglePlacesClient({http.Client? httpClient})
    : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  String get _apiKey => EnvService.googleMapsApiKey;

  static const String _nearbyUrl =
      'https://maps.googleapis.com/maps/api/place/nearbysearch/json';

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

    final response = await _httpClient
        .get(url)
        .timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Google returns HTTP 200 with status:REQUEST_DENIED / OVER_QUERY_LIMIT
      // when the API key is rejected / quota exceeded — surface those so we
      // don't keep debugging a silent empty list.
      _logStatusIfError(data, requestType: 'NearbySearch');
      final results = data['results'] as List? ?? [];

      return results
          .whereType<Map<String, dynamic>>()
          .where(isLikelyRecordingStudio)
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
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 10));

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
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 15));
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

  /// Galerie photo + avis d'un lieu — ne demande QUE `photos,reviews`
  /// (contrairement à [getDetails]) pour ne pas payer en plus les champs
  /// Contact (téléphone, site). `reviews` reste dans le tier Atmosphere
  /// (comme `rating`), donc CET appel-là est facturé plus cher que les
  /// Nearby/TextSearch qui le précèdent — mais c'est le même unique appel
  /// Details par studio, pas un appel de plus. Retourne `null` sur échec
  /// réseau ou timeout (à distinguer de « zéro photo », une galerie vide).
  Future<GooglePhotoGallery?> getPhotoUrls(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=photos,reviews'
      '&reviews_sort=newest'
      '&key=$_apiKey',
    );

    try {
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 15));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logStatusIfError(data, requestType: 'Details(photos+reviews)');
        final result = data['result'];
        if (result != null) {
          final studio = DiscoveredStudio.fromGooglePlace(result);
          return GooglePhotoGallery(
            studio.photoUrls,
            studio.photoAttributions,
            reviews: studio.reviews,
          );
        }
      }
    } catch (e) {
      appLog('⚠️ Places Details(photos+reviews) error: $e');
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
      final response = await _httpClient
          .get(url)
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _logStatusIfError(data, requestType: 'Geocoding');
        final results = data['results'] as List?;

        if (results != null && results.isNotEmpty) {
          final location = results[0]['geometry']['location'];
          return LatLng(location['lat'] as double, location['lng'] as double);
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
