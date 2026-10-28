import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uzme/core/models/google_review.dart';
import 'package:uzme/l10n/app_localizations.dart';
import 'package:uzme/widgets/artist/studio_detail_reviews.dart';

void main() {
  Widget build(List<GoogleReview> reviews) {
    return MaterialApp(
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      home: Scaffold(body: StudioDetailReviews(reviews: reviews)),
    );
  }

  group('StudioDetailReviews', () {
    testWidgets('renders nothing for a partner/pro (no Google reviews)', (
      tester,
    ) async {
      await tester.pumpWidget(build(const []));
      await tester.pumpAndSettle();

      expect(find.byType(StudioDetailReviews), findsOneWidget);
      expect(find.text('Google reviews'), findsNothing);
    });

    testWidgets('shows the section title and each review', (tester) async {
      await tester.pumpWidget(
        build(const [
          GoogleReview(
            authorName: 'Jean Dupont',
            rating: 5,
            relativeTimeDescription: 'a week ago',
            text: 'Super studio, très pro.',
          ),
          GoogleReview(
            authorName: 'Marie Martin',
            rating: 3,
            relativeTimeDescription: 'a month ago',
            text: '',
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Google reviews'), findsOneWidget);
      expect(find.text('Jean Dupont'), findsOneWidget);
      expect(find.text('Marie Martin'), findsOneWidget);
      expect(find.text('Super studio, très pro.'), findsOneWidget);
    });

    testWidgets('shows an initial avatar when there is no profile photo', (
      tester,
    ) async {
      await tester.pumpWidget(
        build(const [
          GoogleReview(
            authorName: 'Zoé',
            rating: 4,
            relativeTimeDescription: 'yesterday',
            text: '',
          ),
        ]),
      );
      await tester.pumpAndSettle();

      expect(find.text('Z'), findsOneWidget);
    });
  });
}
