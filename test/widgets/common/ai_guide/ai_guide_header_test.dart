import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/widgets/common/ai_guide/ai_guide_header.dart';
import 'package:uzme/widgets/common/ai_guide/ai_guide_security_notice.dart';

/// Régression (Ben, 30/10/2026) : le header du guide IA et le rappel
/// "sous contrôle" mélangeaient accent/vert pastel hors charte — "ça fait
/// trop généré par IA". Un seul bleu signature désormais, comme
/// TipsScreen et UzmeFeatureCapsule.
void main() {
  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  testWidgets('AiGuideHeader : dégradé mono-bleu, pas d\'accentColor séparé',
      (tester) async {
    await tester.pumpWidget(wrap(const AiGuideHeader(
      title: 'Votre assistant personnel',
      subtitle: 'Découvre tout ce que l\'IA peut faire',
    )));

    expect(find.text('Votre assistant personnel'), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;
    final gradient = decoration.gradient as LinearGradient;

    expect(gradient.colors.length, 2);
    expect(gradient.colors[0], gradient.colors[1].withValues(alpha: 1.0));
  });

  testWidgets('AiGuideSecurityNotice : bleu signature, pas de vert',
      (tester) async {
    await tester.pumpWidget(wrap(const AiGuideSecurityNotice(
      title: 'Toujours sous votre contrôle',
      description: 'L\'assistant demande toujours confirmation.',
    )));

    expect(find.text('Toujours sous votre contrôle'), findsOneWidget);

    final container = tester.widget<Container>(find.byType(Container).first);
    final decoration = container.decoration as BoxDecoration;

    expect(decoration.color, isNot(Colors.green.withValues(alpha: 0.1)));
    expect(decoration.border, isNot(null));
  });
}
