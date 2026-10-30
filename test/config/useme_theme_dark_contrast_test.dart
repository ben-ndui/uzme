import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/config/useme_theme.dart';

/// Régression (Ben, 30/10/2026) : les boutons "Enregistrer" en TextButton
/// (AppBar) étaient peu visibles en thème sombre — foregroundColor à
/// #5B7FE8 sur un fond #031473, ratio de contraste WCAG ~4.2:1 (sous le
/// seuil AA 4.5:1 pour du texte normal). Verrouille un contraste suffisant.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('TextButton sombre : contraste WCAG AA (>= 4.5) contre le fond AppBar', () {
    final theme = UseMeTheme.darkTheme;
    final foreground = theme.textButtonTheme.style!.foregroundColor!.resolve({})!;
    final background = theme.appBarTheme.backgroundColor!;

    final ratio = _contrastRatio(foreground, background);

    expect(
      ratio,
      greaterThanOrEqualTo(4.5),
      reason: 'foreground=$foreground background=$background ratio=$ratio',
    );
  });
}

double _relativeLuminance(Color c) {
  double channel(double v) {
    final linear = v <= 0.03928 ? v / 12.92 : math.pow((v + 0.055) / 1.055, 2.4).toDouble();
    return linear;
  }

  final r = channel(c.r);
  final g = channel(c.g);
  final b = channel(c.b);
  return 0.2126 * r + 0.7152 * g + 0.0722 * b;
}

double _contrastRatio(Color a, Color b) {
  final la = _relativeLuminance(a) + 0.05;
  final lb = _relativeLuminance(b) + 0.05;
  return la > lb ? la / lb : lb / la;
}
