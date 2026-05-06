import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/core/models/pioneer_status.dart';
import 'package:uzme/core/services/feature_flags_service.dart';

AppUser _userWith({String uid = 'u1', PioneerStatus? pioneer}) {
  return AppUser(
    uid: uid,
    email: '$uid@test.com',
    pioneer: pioneer,
  );
}

const _pioneerStatus = PioneerStatus(isPioneer: true, pioneerNumber: 1);

FeatureFlag _flag(FeatureRollout rollout, {List<String> beta = const []}) {
  return FeatureFlag(key: 'k', rollout: rollout, betaUserIds: beta);
}

void main() {
  group('FeatureFlagsService.resolve', () {
    test('null flag → false (deny by default)', () {
      expect(FeatureFlagsService.resolve(null, _userWith()), isFalse);
      expect(FeatureFlagsService.resolve(null, null), isFalse);
    });

    test('disabled rollout → false for everyone', () {
      final flag = _flag(FeatureRollout.disabled);
      expect(FeatureFlagsService.resolve(flag, null), isFalse);
      expect(FeatureFlagsService.resolve(flag, _userWith()), isFalse);
      expect(
        FeatureFlagsService.resolve(flag, _userWith(pioneer: _pioneerStatus)),
        isFalse,
        reason: 'Even Pioneers must be denied when flag is fully disabled',
      );
    });

    test('enabled rollout → true even for null user', () {
      final flag = _flag(FeatureRollout.enabled);
      expect(FeatureFlagsService.resolve(flag, null), isTrue);
      expect(FeatureFlagsService.resolve(flag, _userWith()), isTrue);
    });

    test('pioneer rollout → only Pioneers', () {
      final flag = _flag(FeatureRollout.pioneer);
      expect(FeatureFlagsService.resolve(flag, null), isFalse);
      expect(FeatureFlagsService.resolve(flag, _userWith()), isFalse,
          reason: 'User without pioneer field gets denied');
      expect(
        FeatureFlagsService.resolve(flag, _userWith(pioneer: _pioneerStatus)),
        isTrue,
      );
      expect(
        FeatureFlagsService.resolve(
          flag,
          _userWith(
            pioneer: const PioneerStatus(isPioneer: false, pioneerNumber: 0),
          ),
        ),
        isFalse,
        reason: 'Pioneer record exists but isPioneer=false → denied',
      );
    });

    test('beta rollout → only listed UIDs', () {
      final flag = _flag(FeatureRollout.beta, beta: ['allowed_uid']);
      expect(FeatureFlagsService.resolve(flag, null), isFalse,
          reason: 'Anonymous never gets beta access');
      expect(
        FeatureFlagsService.resolve(flag, _userWith(uid: 'allowed_uid')),
        isTrue,
      );
      expect(
        FeatureFlagsService.resolve(flag, _userWith(uid: 'random_uid')),
        isFalse,
      );
    });
  });

  group('FeatureFlagsService.watchAll', () {
    // Regression guard for the cold-start bug fixed by switching the
    // controller from `StreamController.broadcast()` to a rxdart
    // BehaviorSubject. Pre-fix, a subscriber attaching after the
    // first snapshot landed never received it — the announcement
    // bottomsheet would silently fail to pop on app re-open.
    test('late subscriber receives the cached snapshot', () async {
      final service = FeatureFlagsService();
      final flag = _flag(FeatureRollout.enabled);
      // Snapshot lands BEFORE anyone subscribes.
      service.setFlagsForTesting({'k': flag});

      // Now subscribe — the cached snapshot should be replayed.
      final received = await service.watchAll().first.timeout(
            const Duration(seconds: 1),
            onTimeout: () => throw StateError(
              'Late subscriber did not receive cached snapshot — '
              'BehaviorSubject regression?',
            ),
          );

      expect(received.keys, ['k']);
      expect(received['k']!.rollout, FeatureRollout.enabled);
    });
  });
}
