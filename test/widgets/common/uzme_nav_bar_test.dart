import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:uzme/config/useme_theme.dart';
import 'package:uzme/widgets/common/uzme_nav_bar.dart';

void main() {
  final items = const [
    UzmeNavItem(
      icon: FontAwesomeIcons.house,
      selectedIcon: FontAwesomeIcons.houseChimney,
      label: 'Home',
    ),
    UzmeNavItem(
      icon: FontAwesomeIcons.calendar,
      selectedIcon: FontAwesomeIcons.solidCalendar,
      label: 'Sessions',
      badgeCount: 3,
    ),
    UzmeNavItem(
      icon: FontAwesomeIcons.heart,
      selectedIcon: FontAwesomeIcons.solidHeart,
      label: 'Favorites',
    ),
  ];

  Widget build(Widget navBar, {Brightness brightness = Brightness.light}) {
    return MaterialApp(
      theme: brightness == Brightness.dark
          ? UseMeTheme.darkTheme
          : UseMeTheme.lightTheme,
      home: Scaffold(bottomNavigationBar: navBar, body: const SizedBox()),
    );
  }

  DecoratedBox findPill(WidgetTester tester) =>
      tester.widget<DecoratedBox>(find.byKey(const Key('uzmeNavBarPill')));

  Container findBarContainer(WidgetTester tester) =>
      tester.widget<Container>(find.byKey(const Key('uzmeNavBarContainer')));

  group('UzmeNavBar.full', () {
    testWidgets('shows every label', (tester) async {
      await tester.pumpWidget(
        build(UzmeNavBar.full(items: items, activeIndex: 0, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Favorites'), findsOneWidget);
    });

    testWidgets('tapping a tab reports its index', (tester) async {
      int? tapped;
      await tester.pumpWidget(
        build(
          UzmeNavBar.full(
            items: items,
            activeIndex: 0,
            onChanged: (i) => tapped = i,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Favorites'));
      expect(tapped, 2);
    });

    testWidgets('shows the pending count as a badge', (tester) async {
      await tester.pumpWidget(
        build(UzmeNavBar.full(items: items, activeIndex: 0, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('the active tab renders its filled (selected) icon variant', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(UzmeNavBar.full(items: items, activeIndex: 0, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();

      expect(
        find.byWidgetPredicate(
          (w) => w is FaIcon && w.icon == FontAwesomeIcons.houseChimney.data,
        ),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (w) => w is FaIcon && w.icon == FontAwesomeIcons.house.data,
        ),
        findsNothing,
      );
    });
  });

  group('UzmeNavBar.compact', () {
    testWidgets('only the active tab writes its label', (tester) async {
      await tester.pumpWidget(
        build(
          UzmeNavBar.compact(items: items, activeIndex: 1, onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sessions'), findsOneWidget);
      expect(find.text('Home'), findsNothing);
      expect(find.text('Favorites'), findsNothing);
    });

    testWidgets('inactive tabs stay reachable by their accessibility label', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(
          UzmeNavBar.compact(items: items, activeIndex: 1, onChanged: (_) {}),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('Home'), findsOneWidget);
      expect(find.bySemanticsLabel('Favorites'), findsOneWidget);
    });
  });

  group('theme inversion (décidé par Ben le 28/10)', () {
    testWidgets('dark theme: white pill on the brand blue', (tester) async {
      await tester.pumpWidget(
        build(
          UzmeNavBar.full(items: items, activeIndex: 0, onChanged: (_) {}),
          brightness: Brightness.dark,
        ),
      );
      await tester.pumpAndSettle();

      final pillDecoration = findPill(tester).decoration as BoxDecoration;
      expect(pillDecoration.color, UseMeTheme.primaryColor);
    });

    testWidgets('light theme: brand-blue gradient bar, white pill', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(
          UzmeNavBar.full(items: items, activeIndex: 0, onChanged: (_) {}),
          brightness: Brightness.light,
        ),
      );
      await tester.pumpAndSettle();

      final pillDecoration = findPill(tester).decoration as BoxDecoration;
      expect(pillDecoration.color, Colors.white);

      final barDecoration =
          findBarContainer(tester).decoration as BoxDecoration;
      expect(barDecoration.gradient, isNotNull);
    });
  });
}
