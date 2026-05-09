import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/widgets/common/map_position_picker.dart';

/// Mounting the picker must not throw any **lifecycle** assertion
/// (initState async work, controllers, missing deps, etc.).
///
/// We tolerate platform-channel exceptions because GoogleMap requires
/// the Maps platform plugin which isn't wired up in widget tests, and
/// EnvService throws when .env hasn't been loaded — neither is what
/// we're guarding against here. What we catch is the family of bugs
/// that show up at mount BEFORE any external call resolves.
void main() {
  testWidgets('MapPositionPicker mounts without lifecycle errors',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapPositionPicker(
            onChanged: (_) {},
          ),
        ),
      ),
    );
    await tester.pump();

    Object? exception;
    while ((exception = tester.takeException()) != null) {
      final str = exception.toString();
      if (str.contains('MissingPluginException') ||
          str.contains('PlatformException') ||
          str.contains('EnvService') ||
          str.contains('NotInitializedError')) {
        continue;
      }
      fail('Unexpected exception at mount: $exception');
    }
  });
}
