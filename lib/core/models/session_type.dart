/// Session type enum (types de sessions studio)
enum SessionType {
  mix,
  mastering,
  recording,
  mixing,
  editing,
  other,
}

extension SessionTypeExtension on SessionType {
  String get label {
    switch (this) {
      case SessionType.mix:
        return 'Mix';
      case SessionType.mastering:
        return 'Mastering';
      case SessionType.recording:
        return 'Enregistrement';
      case SessionType.mixing:
        return 'Mixage';
      case SessionType.editing:
        return 'Montage';
      case SessionType.other:
        return 'Autre';
    }
  }

  /// Ordre logique pour l'affichage (enregistrement → mix → mastering)
  int get sortOrder {
    switch (this) {
      case SessionType.recording:
        return 0;
      case SessionType.mix:
      case SessionType.mixing:
        return 1;
      case SessionType.mastering:
        return 2;
      case SessionType.editing:
        return 3;
      case SessionType.other:
        return 4;
    }
  }

  static SessionType fromString(String? value) {
    switch (value) {
      case 'mix':
        return SessionType.mix;
      case 'mastering':
        return SessionType.mastering;
      case 'recording':
        return SessionType.recording;
      case 'mixing':
        return SessionType.mixing;
      case 'editing':
        return SessionType.editing;
      default:
        return SessionType.other;
    }
  }

  /// Parse une liste de types depuis Firestore
  static List<SessionType> listFromStrings(List<dynamic>? values) {
    if (values == null || values.isEmpty) return [];
    return values.map((v) => fromString(v?.toString())).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  /// Génère le label combiné pour plusieurs types
  /// Ex: "Enregistrement + Mix + Mastering"
  static String combinedLabel(List<SessionType> types) {
    if (types.isEmpty) return 'Autre';
    final sorted = types.toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return sorted.map((t) => t.label).join(' + ');
  }
}
