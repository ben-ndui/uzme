import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/core/models/app_user.dart';
import 'package:uzme/core/models/feature_flag.dart';
import 'package:uzme/core/services/feature_announcements_service.dart';

AppUser _user({String uid = 'u1'}) =>
    AppUser(uid: uid, email: '$uid@test.com');

FeatureFlag _flag({
  required String key,
  String announcementTitle = 'Title',
  String announcementBody = 'Body',
}) {
  return FeatureFlag(
    key: key,
    rollout: FeatureRollout.enabled,
    announcementTitle: announcementTitle,
    announcementBody: announcementBody,
  );
}

void main() {
  group('FeatureAnnouncementsService.nextAnnouncementFor', () {
    test('returns null when user is null', () {
      final result = FeatureAnnouncementsService.nextAnnouncementFor(
        user: null,
        flags: [_flag(key: 'a')],
        seenKeys: const {},
        isEnabled: (_, __) => true,
      );
      expect(result, isNull);
    });

    test('skips flags with empty announcementTitle', () {
      final result = FeatureAnnouncementsService.nextAnnouncementFor(
        user: _user(),
        flags: [
          _flag(key: 'silent', announcementTitle: ''),
          _flag(key: 'loud', announcementTitle: 'Hey'),
        ],
        seenKeys: const {},
        isEnabled: (_, __) => true,
      );
      expect(result?.key, 'loud');
    });

    test('skips flags already in seenKeys', () {
      final result = FeatureAnnouncementsService.nextAnnouncementFor(
        user: _user(),
        flags: [
          _flag(key: 'a', announcementTitle: 'A'),
          _flag(key: 'b', announcementTitle: 'B'),
        ],
        seenKeys: const {'a'},
        isEnabled: (_, __) => true,
      );
      expect(result?.key, 'b');
    });

    test('skips flags not currently enabled for the user', () {
      final result = FeatureAnnouncementsService.nextAnnouncementFor(
        user: _user(),
        flags: [
          _flag(key: 'a', announcementTitle: 'A'),
          _flag(key: 'b', announcementTitle: 'B'),
        ],
        seenKeys: const {},
        // Pretend only the second flag is enabled (matches an actual
        // pioneer/beta gate computed by FeatureFlagsService elsewhere).
        isEnabled: (flag, _) => flag.key == 'b',
      );
      expect(result?.key, 'b');
    });

    test('returns null when nothing is due', () {
      final result = FeatureAnnouncementsService.nextAnnouncementFor(
        user: _user(),
        flags: [
          _flag(key: 'a', announcementTitle: 'A'),
        ],
        seenKeys: const {'a'},
        isEnabled: (_, __) => true,
      );
      expect(result, isNull);
    });

    test('returns the first matching flag in iteration order', () {
      // Confirms the function does NOT shuffle / sort — caller-supplied
      // order wins. That guarantees a deterministic UX when multiple
      // announcements queue up.
      final result = FeatureAnnouncementsService.nextAnnouncementFor(
        user: _user(),
        flags: [
          _flag(key: 'first', announcementTitle: 'First'),
          _flag(key: 'second', announcementTitle: 'Second'),
        ],
        seenKeys: const {},
        isEnabled: (_, __) => true,
      );
      expect(result?.key, 'first');
    });
  });
}
