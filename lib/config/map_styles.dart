import 'dart:ui' show Brightness;

/// Custom Google Maps styles matching UZME brand colors.
/// Light: subtle blue tint on water/roads, muted landmarks.
/// Dark: deep dark surfaces with UZME blue accents.
class MapStyles {
  MapStyles._();

  /// Light map style — clean, subtle blue accents
  static const String light = '''
[
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#c5d4f5"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#0B38BF"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#dce3f4"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#b8c6e8"}]
  },
  {
    "featureType": "road.arterial",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#e8ecf6"}]
  },
  {
    "featureType": "road.local",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#f0f2f8"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.icon",
    "stylers": [{"saturation": -40}, {"lightness": 10}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#d4ecd8"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#f5f6fa"}]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#eef0f5"}]
  },
  {
    "featureType": "transit",
    "elementType": "labels.icon",
    "stylers": [{"saturation": -50}]
  }
]
''';

  /// Dark map style — deep UZME dark surfaces with blue accents.
  ///
  /// Élargi le 28/10/2026 (relevé par Ben : "ça se lit comme un bloc noir") —
  /// la version précédente tenait toutes ses teintes (route/quartier/parc)
  /// entre 0x0D et 0x25, moins de 10 points de luminance d'écart. Celle-ci
  /// étale les mêmes rôles de 0x12 à 0x3A pour qu'on distingue une route d'un
  /// quartier au premier coup d'œil, et aligne le bleu des highways sur
  /// `UseMeTheme._darkPrimary` (0x5B7FE8, celui des boutons/FAB en dark) —
  /// avant, le trait de route lisait le bleu de marque brut (0x0B38BF),
  /// un second bleu différent sur le même écran.
  static const String dark = '''
[
  {
    "elementType": "geometry",
    "stylers": [{"color": "#121214"}]
  },
  {
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8B8B95"}]
  },
  {
    "elementType": "labels.text.stroke",
    "stylers": [{"color": "#121214"}]
  },
  {
    "featureType": "administrative",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#3A3D47"}]
  },
  {
    "featureType": "administrative.land_parcel",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#5B5B66"}]
  },
  {
    "featureType": "landscape.man_made",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#1A1C21"}]
  },
  {
    "featureType": "landscape.natural",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#16181C"}]
  },
  {
    "featureType": "poi",
    "elementType": "geometry",
    "stylers": [{"color": "#20222A"}]
  },
  {
    "featureType": "poi",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8B8B95"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#132A1B"}]
  },
  {
    "featureType": "poi.park",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#4D9460"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#242731"}]
  },
  {
    "featureType": "road",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#33363F"}]
  },
  {
    "featureType": "road",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#8B8B95"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#28407A"}]
  },
  {
    "featureType": "road.highway",
    "elementType": "geometry.stroke",
    "stylers": [{"color": "#5B7FE8", "weight": 0.5}]
  },
  {
    "featureType": "transit",
    "elementType": "geometry",
    "stylers": [{"color": "#1A1C21"}]
  },
  {
    "featureType": "transit.station",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#5B7FE8"}]
  },
  {
    "featureType": "water",
    "elementType": "geometry.fill",
    "stylers": [{"color": "#0A1530"}]
  },
  {
    "featureType": "water",
    "elementType": "labels.text.fill",
    "stylers": [{"color": "#5B7FE8"}]
  }
]
''';

  /// Returns the appropriate style based on brightness.
  static String forBrightness(Brightness brightness) {
    return brightness == Brightness.dark ? dark : light;
  }
}
