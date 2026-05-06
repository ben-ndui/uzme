import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/core/services/feature_announcements_service.dart';
import 'package:uzme/core/utils/app_logger.dart';
import 'package:uzme/main.dart' show featureFlagsService;
import 'package:uzme/widgets/feature_flags/feature_announcement_sheet.dart';

/// Wraps the entire authenticated app and pops a [FeatureAnnouncementSheet]
/// the first time a user gains access to a flag whose admin-set
/// announcement is non-empty.
///
/// Mount once near the root (typically via `MaterialApp.router(builder:)`).
/// Idle while:
///   - no auth state yet
///   - user is not authenticated
///   - flag service hasn't received its first snapshot
///
/// On every auth or snapshot change we recompute the next pending
/// announcement and show the sheet — only one popup at a time, the
/// stream re-fires after `markSeen` so any further announcements are
/// drained on subsequent rebuilds.
class FeatureAnnouncementWatcher extends StatefulWidget {
  final Widget child;
  const FeatureAnnouncementWatcher({super.key, required this.child});

  @override
  State<FeatureAnnouncementWatcher> createState() =>
      _FeatureAnnouncementWatcherState();
}

class _FeatureAnnouncementWatcherState
    extends State<FeatureAnnouncementWatcher> {
  late final FeatureAnnouncementsService _service;
  StreamSubscription<Map<String, FeatureFlag>>? _flagsSub;
  bool _checking = false;
  String? _lastShownKey;

  @override
  void initState() {
    super.initState();
    _service = FeatureAnnouncementsService(flagsService: featureFlagsService);
    _flagsSub = featureFlagsService.watchAll().listen((_) {
      // New snapshot landed — re-evaluate. With BehaviorSubject this
      // ALSO fires on subscribe with the cached snapshot, so cold-start
      // mounts after the first Firestore event still trigger.
      _maybeShow();
    });
    // Belt-and-suspenders: also wait for the service's first snapshot
    // explicitly, so a watcher mounted before Firestore returns gets
    // unblocked once the snapshot lands.
    unawaited(featureFlagsService.whenReady().then((_) => _maybeShow()));
  }

  @override
  void dispose() {
    _flagsSub?.cancel();
    super.dispose();
  }

  Future<void> _maybeShow() async {
    if (_checking || !mounted) return;
    _checking = true;
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState is! AuthAuthenticatedState) {
        if (kDebugMode) {
          appLog('🔔 Announcement: skip — not authenticated yet');
        }
        return;
      }
      final user = authState.user as AppUser?;
      if (user == null) return;
      if (!featureFlagsService.isReady) {
        if (kDebugMode) {
          appLog(
            '🔔 Announcement: skip — flags not ready, waiting for snapshot',
          );
        }
        return;
      }

      final flags = featureFlagsService.current.values
          .where((f) => f.hasAnnouncement)
          .toList();
      if (flags.isEmpty) {
        if (kDebugMode) {
          appLog('🔔 Announcement: no flag carries an announcement');
        }
        return;
      }

      final flag = await _service.nextFor(user: user, flags: flags);
      if (flag == null) {
        if (kDebugMode) {
          appLog(
            '🔔 Announcement: no pending — all eligible flags already seen / not enabled for ${user.uid}',
          );
        }
        return;
      }
      // Avoid re-showing the same key in a single mount window in case
      // the snapshot fires before markSeen has hit Firestore.
      if (_lastShownKey == flag.key) return;
      _lastShownKey = flag.key;
      if (!mounted) return;

      if (kDebugMode) {
        appLog('🔔 Announcement: showing sheet for "${flag.key}"');
      }
      final acknowledged = await FeatureAnnouncementSheet.show(
        context: context,
        flag: flag,
      );
      if (!acknowledged) return;
      await _service.markSeen(user.uid, flag.key);
      // After ack, re-run in case there's another announcement queued.
      if (mounted) unawaited(_maybeShow());
    } catch (e, st) {
      // Best-effort UX — log so failures aren't truly silent in dev.
      if (kDebugMode) {
        appLog('🔔 Announcement watcher error: $e\n$st');
      }
    } finally {
      _checking = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listenWhen: (prev, curr) =>
          prev.runtimeType != curr.runtimeType &&
          curr is AuthAuthenticatedState,
      listener: (_, __) => _maybeShow(),
      child: widget.child,
    );
  }
}
