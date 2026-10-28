/// Filtre post-réponse des résultats Google Places qui ne sont visiblement
/// pas des studios d'enregistrement (magasins, écoles, lieux de culte…).
/// La Legacy Places API n'a pas de type `recording_studio` natif — Places
/// API (New) l'a et permettrait de supprimer ce fichier.
library;

/// Google Place types that strongly indicate the result is NOT a
/// recording studio (music shops, schools, churches, etc.). The legacy
/// Places API doesn't have a `recording_studio` type, so we filter
/// post-response — Places API (New) exposes `recording_studio` natively
/// and would let us skip this list entirely.
const _excludedPlaceTypes = {
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
const _excludedNamePatterns = [
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

bool isLikelyRecordingStudio(Map<String, dynamic> place) {
  final types =
      (place['types'] as List?)?.map((e) => e.toString()).toList() ?? const [];
  for (final blacklisted in _excludedPlaceTypes) {
    if (types.contains(blacklisted)) return false;
  }
  final name = (place['name']?.toString() ?? '').toLowerCase();
  for (final pattern in _excludedNamePatterns) {
    if (name.contains(pattern)) return false;
  }
  return true;
}
