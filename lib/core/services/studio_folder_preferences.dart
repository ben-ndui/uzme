import 'dart:convert';
import 'dart:typed_data';

import 'package:shared_preferences/shared_preferences.dart';

/// Dossier d'enregistrement persisté pour un ingénieur son.
class SavedStudioFolder {
  const SavedStudioFolder({required this.path, required this.bookmark});

  final String path;

  /// Security-scoped bookmark macOS — seul lui permet de relire le dossier
  /// après un relancement de l'app (voir smoothandesign_folder_watcher).
  final Uint8List bookmark;
}

/// Persiste localement le dossier d'enregistrement surveillé par un
/// ingénieur son (DirectorySurveillance / Xplor, repris le 30/10/2026).
///
/// Le chemin est un emplacement du DISQUE de cet ordinateur : il n'a aucun
/// sens sur un autre appareil, donc pas de Firestore ici — juste
/// SharedPreferences, scopé par uid pour ne pas mélanger deux ingénieurs
/// qui partageraient le même Mac. Le bookmark est stocké encodé en base64
/// (SharedPreferences n'a pas de type binaire).
class StudioFolderPreferences {
  static String _pathKeyFor(String uid) => 'studio_folder_path_$uid';
  static String _bookmarkKeyFor(String uid) => 'studio_folder_bookmark_$uid';

  static Future<SavedStudioFolder?> load(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    final path = prefs.getString(_pathKeyFor(uid));
    final bookmarkBase64 = prefs.getString(_bookmarkKeyFor(uid));
    if (path == null || bookmarkBase64 == null) return null;
    return SavedStudioFolder(path: path, bookmark: base64Decode(bookmarkBase64));
  }

  static Future<void> save(String uid, String path, Uint8List bookmark) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_pathKeyFor(uid), path);
    await prefs.setString(_bookmarkKeyFor(uid), base64Encode(bookmark));
  }

  static Future<void> clear(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pathKeyFor(uid));
    await prefs.remove(_bookmarkKeyFor(uid));
  }
}
