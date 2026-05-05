import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/core/services/feature_announcements_service.dart';
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
      // New snapshot landed — re-evaluate. We pass through the same
      // entry point as the auth listener so logic stays in one place.
      _maybeShow();
    });
    // First evaluation in case the snapshot landed before this widget
    // was mounted.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShow());
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
      if (authState is! AuthAuthenticatedState) return;
      final user = authState.user as AppUser?;
      if (user == null) return;
      if (!featureFlagsService.isReady) return;

      final flags = featureFlagsService.current.values
          .where((f) => f.hasAnnouncement)
          .toList();
      if (flags.isEmpty) return;

      final flag = await _service.nextFor(user: user, flags: flags);
      if (flag == null) return;
      // Avoid re-showing the same key in a single mount window in case
      // the snapshot fires before markSeen has hit Firestore.
      if (_lastShownKey == flag.key) return;
      _lastShownKey = flag.key;
      if (!mounted) return;

      final acknowledged = await FeatureAnnouncementSheet.show(
        context: context,
        flag: flag,
      );
      if (!acknowledged) return;
      await _service.markSeen(user.uid, flag.key);
      // After ack, re-run in case there's another announcement queued.
      if (mounted) unawaited(_maybeShow());
    } catch (_) {
      // Silent — announcements are best-effort UX, not critical path.
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
