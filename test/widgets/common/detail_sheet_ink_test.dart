import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/widgets/common/detail_sheet_ink.dart';

void main() {
  group('DetailSheetInk', () {
    testWidgets(
        'dark: muted ink is a light, visible white — not the near-black '
        'outline token calibrated for a neutral surface', (tester) async {
      late DetailSheetInk ink;
      await tester.pumpWidget(MaterialApp(
        theme: UseMeTheme.darkTheme,
        home: Builder(
          builder: (context) {
            ink = DetailSheetInk(context);
            return const SizedBox();
          },
        ),
      ));

      expect(ink.isDark, isTrue);
      // L'ancien bug : le badge lisait colorScheme.outline (0xFF45454D),
      // gris quasi-noir, illisible sur le dégradé bleu du sheet.
      expect(ink.mutedInk.computeLuminance(), greaterThan(0.3));
      expect(ink.accentInk, Colors.white);
    });

    testWidgets('light: keeps the normal theme tokens (neutral surface)', (
      tester,
    ) async {
      late DetailSheetInk ink;
      await tester.pumpWidget(MaterialApp(
        theme: UseMeTheme.lightTheme,
        home: Builder(
          builder: (context) {
            ink = DetailSheetInk(context);
            return const SizedBox();
          },
        ),
      ));

      expect(ink.isDark, isFalse);
      expect(ink.accentInk, Theme.of(tester.element(find.byType(SizedBox))).colorScheme.primary);
    });
  });
}
