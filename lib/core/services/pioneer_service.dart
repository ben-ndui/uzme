import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uzme/core/models/pioneer_program.dart';
import 'package:uzme/core/utils/app_logger.dart';

/// Bridge between the uzme app and the smoothbackend `pioneer/` module.
/// Wraps the callables (createProgram, preview, distribute, archive,
/// recordActive) and the Firestore reads on the pioneer_programs
/// collection.
class PioneerService {
  PioneerService({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _functions = functions ??
            FirebaseFunctions.instanceFor(region: 'europe-west1');

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions;

  static const _collection = 'pioneer_programs';

  /// Live stream of all programs, ordered most-recent first. Used by the
  /// admin list screen.
  Stream<List<PioneerProgram>> watchPrograms() {
    return _firestore
        .collection(_collection)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => PioneerProgram.fromMap(d.data(), d.id)).toList());
  }

  /// One-shot fetch of a single program (used by detail screens).
  Future<PioneerProgram?> fetchProgram(String programId) async {
    final doc = await _firestore.collection(_collection).doc(programId).get();
    if (!doc.exists || doc.data() == null) return null;
    return PioneerProgram.fromMap(doc.data()!, doc.id);
  }

  /// Create a new program in draft status. Server enforces superAdmin.
  Future<String> createProgram({
    required String name,
    String description = '',
    required int targetCount,
    required DateTime deadline,
    PioneerWeights weights = const PioneerWeights(),
    PioneerBenefits benefits = const PioneerBenefits(),
  }) async {
    final result = await _functions.httpsCallable('createPioneerProgram').call({
      'name': name,
      'description': description,
      'targetCount': targetCount,
      'deadline': deadline.millisecondsSinceEpoch,
      'weights': weights.toMap(),
      'benefits': benefits.toMap(),
    });
    return (result.data as Map)['programId'] as String;
  }

  /// Patch an editable (draft / active) program. Pass only the fields
  /// you want to change.
  Future<void> updateProgram(
    String programId, {
    String? name,
    String? description,
    int? targetCount,
    DateTime? deadline,
    PioneerWeights? weights,
    PioneerBenefits? benefits,
    PioneerProgramStatus? status,
  }) async {
    final patch = <String, dynamic>{};
    if (name != null) patch['name'] = name;
    if (description != null) patch['description'] = description;
    if (targetCount != null) patch['targetCount'] = targetCount;
    if (deadline != null) patch['deadline'] = deadline.millisecondsSinceEpoch;
    if (weights != null) patch['weights'] = weights.toMap();
    if (benefits != null) patch['benefits'] = benefits.toMap();
    if (status != null) patch['status'] = status.key;

    await _functions
        .httpsCallable('updatePioneerProgram')
        .call({'programId': programId, 'patch': patch});
  }

  /// Compute and return the live top-N leaderboard for a program without
  /// distributing anything yet — used by the admin preview screen.
  Future<List<PioneerLeaderboardEntry>> previewLeaderboard(
    String programId, {
    int limit = 100,
  }) async {
    final result = await _functions
        .httpsCallable('previewPioneerLeaderboard')
        .call({'programId': programId, 'limit': limit});
    final data = result.data as Map;
    final list = (data['leaderboard'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => PioneerLeaderboardEntry.fromMap(
              Map<String, dynamic>.from(e),
            ))
        .toList();
    return list;
  }

  /// Snapshot the current leaderboard, persist it as the recipients of
  /// the program, and flip every winner's `pioneer.isPioneer` flag.
  Future<int> distributeProgram(String programId) async {
    final result = await _functions
        .httpsCallable('distributePioneerProgram')
        .call({'programId': programId});
    return ((result.data as Map)['distributedCount'] as num).toInt();
  }

  /// Archive a program. Pass `revoke: true` to also remove the program
  /// from each recipient's `pioneerProgramIds`.
  Future<void> archiveProgram(String programId, {bool revoke = false}) async {
    await _functions
        .httpsCallable('archivePioneerProgram')
        .call({'programId': programId, 'revoke': revoke});
  }

  /// Bumps `activeDaysCount` on the calling user (if not already counted
  /// today). Safe to call multiple times — server-side idempotency.
  Future<void> recordUserActive() async {
    try {
      await _functions.httpsCallable('recordUserActive').call();
    } catch (e) {
      // Not critical — silently log so we don't block app launch on a
      // network blip.
      appLog('⚠️ recordUserActive failed: $e');
    }
  }
}
