import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import '../utils/app_logger.dart';
import 'env_service.dart';

/// One autocomplete suggestion as returned by Google Places.
class PlacesSuggestion {
  final String placeId;
  final String description;
  final String? mainText;
  final String? secondaryText;

  const PlacesSuggestion({
    required this.placeId,
    required this.description,
    this.mainText,
    this.secondaryText,
  });
}

/// Result of a Place Details lookup — both lat/lng and the formatted
/// address Google has on file for that place.
class PlaceDetails {
  final LatLng position;
  final String formattedAddress;

  const PlaceDetails({required this.position, required this.formattedAddress});
}

/// Centralised geocoding helpers backed by Google Places + Geocoding APIs.
///
/// Used by [MapPositionPicker] but also reusable elsewhere whenever we
/// need to resolve an address ↔ lat/lng without rolling our own HTTP.
///
/// Session tokens (Places autocomplete) are managed internally: the
/// service holds a token across `autocomplete` calls and resets it
/// after `getPlaceDetails`, which is how Google bills the session.
class GeocodingService {
  GeocodingService({http.Client? httpClient})
      : _httpClient = httpClient ?? http.Client();

  final http.Client _httpClient;
  static const _uuid = Uuid();

  String _sessionToken = _uuid.v4();
  String get _apiKey => EnvService.googleMapsApiKey;

  /// Place Autocomplete — predictive completions while the user types.
  ///
  /// Returns up to 5 suggestions, biased to addresses. Pass [bias] to
  /// rank nearby results higher (typically the user's current location
  /// for studio-onboarding flows).
  Future<List<PlacesSuggestion>> autocomplete(
    String input, {
    String language = 'fr',
    LatLng? bias,
  }) async {
    if (input.trim().isEmpty) return [];

    final params = <String, String>{
      'input': input,
      'key': _apiKey,
      'language': language,
      'sessiontoken': _sessionToken,
    };
    if (bias != null) {
      // 50 km bias circle — wide enough to catch the user's whole city
      // without hiding addresses across the country.
      params['locationbias'] = 'circle:50000@${bias.latitude},${bias.longitude}';
    }
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
    ).replace(queryParameters: params);

    try {
      final res = await _httpClient.get(url).timeout(
            const Duration(seconds: 6),
          );
      if (res.statusCode != 200) {
        appLog('⚠️ Places Autocomplete HTTP ${res.statusCode}');
        return [];
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      _logIfError(data, requestType: 'Autocomplete');
      final preds = (data['predictions'] as List?) ?? [];
      return preds.map((p) {
        final m = p as Map<String, dynamic>;
        final structured = m['structured_formatting'] as Map<String, dynamic>?;
        return PlacesSuggestion(
          placeId: m['place_id'] as String,
          description: m['description'] as String? ?? '',
          mainText: structured?['main_text'] as String?,
          secondaryText: structured?['secondary_text'] as String?,
        );
      }).toList();
    } catch (e) {
      appLog('⚠️ Places Autocomplete error: $e');
      return [];
    }
  }

  /// Resolve a [placeId] (from autocomplete) to a position + the
  /// canonical formatted address. Closes the current session and
  /// rotates the token afterwards — the next autocomplete call starts
  /// a new billable session.
  Future<PlaceDetails?> getPlaceDetails(String placeId) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/place/details/json'
      '?place_id=$placeId'
      '&fields=geometry,formatted_address'
      '&key=$_apiKey'
      '&sessiontoken=$_sessionToken',
    );

    try {
      final res = await _httpClient.get(url).timeout(
            const Duration(seconds: 6),
          );
      if (res.statusCode != 200) {
        appLog('⚠️ Places Details HTTP ${res.statusCode}');
        return null;
      }
      final data = json.decode(res.body) as Map<String, dynamic>;
      _logIfError(data, requestType: 'Details');
      final result = data['result'] as Map<String, dynamic>?;
      if (result == null) return null;

      final loc = result['geometry']?['location'];
      final address = result['formatted_address'] as String?;
      if (loc == null || address == null) return null;

      return PlaceDetails(
        position: LatLng(
          (loc['lat'] as num).toDouble(),
          (loc['lng'] as num).toDouble(),
        ),
        formattedAddress: address,
      );
    } catch (e) {
      appLog('⚠️ Places Details error: $e');
      return null;
    } finally {
      _sessionToken = _uuid.v4();
    }
  }

  /// Reverse geocoding: lat/lng → human-readable address.
  /// Used after the user drops a marker on the map.
  Future<String?> reverseGeocode(LatLng position) async {
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?latlng=${position.latitude},${position.longitude}'
      '&key=$_apiKey'
      '&language=fr',
    );

    try {
      final res = await _httpClient.get(url).timeout(
            const Duration(seconds: 6),
          );
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      _logIfError(data, requestType: 'ReverseGeocode');
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;
      return (results.first as Map<String, dynamic>)['formatted_address']
          as String?;
    } catch (e) {
      appLog('⚠️ Reverse geocode error: $e');
      return null;
    }
  }

  /// Forward geocoding: free-text address → lat/lng.
  /// Used as a fallback when the user types an address but doesn't
  /// pick an autocomplete suggestion.
  Future<LatLng?> geocode(String address) async {
    if (address.trim().isEmpty) return null;
    final url = Uri.parse(
      'https://maps.googleapis.com/maps/api/geocode/json'
      '?address=${Uri.encodeComponent(address)}'
      '&key=$_apiKey'
      '&language=fr',
    );

    try {
      final res = await _httpClient.get(url).timeout(
            const Duration(seconds: 6),
          );
      if (res.statusCode != 200) return null;
      final data = json.decode(res.body) as Map<String, dynamic>;
      _logIfError(data, requestType: 'Geocode');
      final results = data['results'] as List?;
      if (results == null || results.isEmpty) return null;
      final loc = (results.first as Map<String, dynamic>)['geometry']
          ?['location'] as Map<String, dynamic>?;
      if (loc == null) return null;
      return LatLng(
        (loc['lat'] as num).toDouble(),
        (loc['lng'] as num).toDouble(),
      );
    } catch (e) {
      appLog('⚠️ Geocode error: $e');
      return null;
    }
  }

  void _logIfError(dynamic data, {required String requestType}) {
    final status = data['status']?.toString();
    if (status == null || status == 'OK' || status == 'ZERO_RESULTS') return;
    final errorMessage = data['error_message']?.toString() ?? '';
    appLog(
      '⚠️ Google $requestType non-OK: $status'
      '${errorMessage.isNotEmpty ? ' — $errorMessage' : ''}',
    );
  }
}
