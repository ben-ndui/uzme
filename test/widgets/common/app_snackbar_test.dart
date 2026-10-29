import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/widgets/common/snackbar/snackbar_exports.dart';

/// UZME a sa propre forme de snackbar (capsule glass, comme GlassChip et
/// UzmeNavBar) au lieu de la carte générique du package partagé. Relevé par
/// Ben le 29/10/2026 : « ca suit pas du tout la DA de l'app... doit être
/// plus à l'image de l'app pas juste la couleur ».
void main() {
  Future<void> pumpSnackbar(
    WidgetTester tester, {
    required ThemeData theme,
    required void Function(BuildContext) trigger,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(onPressed: () => trigger(context), child: const Text('go')),
          ),
        ),
      ),
    );
    await tester.tap(find.text('go'));
    await tester.pump();
  }

  testWidgets('capsule arrondie (pilule), pas la carte à coins 16 du package partagé', (tester) async {
    await pumpSnackbar(
      tester,
      theme: UseMeTheme.darkTheme,
      trigger: (context) => AppSnackBar.success(context, 'Fait'),
    );

    final clipRRect = tester.widget<ClipRRect>(find.byType(ClipRRect).first);
    final radius = (clipRRect.borderRadius as BorderRadius).topLeft.x;
    expect(radius, 28);
  });

  testWidgets('sombre : fond blanc translucide (comme GlassChip), jamais un gris fixe', (tester) async {
    await pumpSnackbar(
      tester,
      theme: UseMeTheme.darkTheme,
      trigger: (context) => AppSnackBar.success(context, 'Fait'),
    );

    final container = tester.widget<Container>(
      find.descendant(of: find.byType(ClipRRect), matching: find.byType(Container)).first,
    );
    final decoration = container.decoration as BoxDecoration;
    expect(decoration.color, Colors.white.withValues(alpha: 0.1));
  });

  testWidgets('info reprend colorScheme.primary comme liseré d\'accent', (tester) async {
    await pumpSnackbar(
      tester,
      theme: UseMeTheme.darkTheme,
      trigger: (context) => AppSnackBar.info(context, 'Info'),
    );

    expect(find.byIcon(FontAwesomeIcons.circleInfo.data), findsOneWidget);
  });

  testWidgets('success/error/warning gardent leur couleur sémantique universelle', (tester) async {
    expect(
      AppSnackBar.getTypeConfig(SnackBarType.success, UseMeTheme.darkTheme).accentColor,
      const Color(0xFF22C55E),
    );
    expect(
      AppSnackBar.getTypeConfig(SnackBarType.error, UseMeTheme.darkTheme).accentColor,
      const Color(0xFFEF4444),
    );
    expect(
      AppSnackBar.getTypeConfig(SnackBarType.warning, UseMeTheme.darkTheme).accentColor,
      const Color(0xFFF59E0B),
    );
  });
}
