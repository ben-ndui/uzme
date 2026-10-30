import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/widgets/common/settings/uzme_feature_capsule.dart';

/// Régression (Ben, 30/10/2026) : les cards "Comparateur de rôles" /
/// "Tes nouveautés" avaient un dégradé pastel violet/or/vert hors charte
/// — « ça fait trop généré par IA ». La capsule reprend le langage déjà
/// établi par UzmeNavBar (une seule famille de couleur, inversion clair/
/// sombre), pas un gabarit générique de card "feature IA".
void main() {
  Widget wrap(Widget child, {required Brightness brightness}) {
    return MaterialApp(
      theme: ThemeData(brightness: brightness, useMaterial3: true),
      home: Scaffold(body: child),
    );
  }

  testWidgets('affiche titre, sous-titre et déclenche onTap', (tester) async {
    var tapped = false;
    await tester.pumpWidget(wrap(
      UzmeFeatureCapsule(
        icon: FontAwesomeIcons.arrowRightArrowLeft,
        title: 'Comparateur de rôles',
        subtitle: 'Découvre les autres modes UZME',
        onTap: () => tapped = true,
      ),
      brightness: Brightness.light,
    ));

    expect(find.text('Comparateur de rôles'), findsOneWidget);
    expect(find.text('Découvre les autres modes UZME'), findsOneWidget);

    await tester.tap(find.byType(GestureDetector));
    expect(tapped, isTrue);
  });

  testWidgets('clair : dégradé bleu signature, texte blanc — pas de violet/or/vert', (tester) async {
    await tester.pumpWidget(wrap(
      UzmeFeatureCapsule(
        icon: FontAwesomeIcons.wandMagicSparkles,
        title: 'Tes nouveautés',
        subtitle: 'Résumé IA',
        onTap: () {},
      ),
      brightness: Brightness.light,
    ));

    final container = tester.widget<Container>(find.descendant(
      of: find.byType(AnimatedScale),
      matching: find.byType(Container),
    ).first);
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.gradient, isA<LinearGradient>());
    final gradient = decoration.gradient as LinearGradient;
    expect(gradient.colors, [UseMeTheme.primaryColor, UseMeTheme.secondaryColor]);

    final title = tester.widget<Text>(find.text('Tes nouveautés'));
    expect(title.style?.color, Colors.white);
  });

  testWidgets('sombre : fond blanc plein, texte bleu signature (inversion UzmeNavBar)', (tester) async {
    await tester.pumpWidget(wrap(
      UzmeFeatureCapsule(
        icon: FontAwesomeIcons.wandMagicSparkles,
        title: 'Tes nouveautés',
        subtitle: 'Résumé IA',
        onTap: () {},
      ),
      brightness: Brightness.dark,
    ));

    final container = tester.widget<Container>(find.descendant(
      of: find.byType(AnimatedScale),
      matching: find.byType(Container),
    ).first);
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.gradient, isNull);
    expect(decoration.color, Colors.white);

    final title = tester.widget<Text>(find.text('Tes nouveautés'));
    expect(title.style?.color, UseMeTheme.primaryColor);
  });
}
