import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:smoothandesign_package/smoothandesign.dart';
import 'package:uzme/core/blocs/blocs_exports.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/models/payment_method.dart';
import 'package:uzme/core/models/studio_profile.dart';
import 'package:uzme/widgets/artist/studio_detail_bottom_sheet.dart';

import '../../helpers/mock_services.dart';
import '../../helpers/widget_test_helpers.dart';

void main() {
  late MockAuthBloc mockAuthBloc;
  late MockFavoriteBloc mockFavoriteBloc;
  late MockStudioDiscoveryService mockDiscoveryService;
  late MockPaymentConfigService mockPaymentConfigService;

  setUpAll(() {
    registerFallbackValue(const DiscoveredStudio(
      id: 'fallback',
      name: 'fallback',
      position: LatLng(0, 0),
    ));
  });

  setUp(() {
    mockAuthBloc = MockAuthBloc();
    mockFavoriteBloc = MockFavoriteBloc();
    mockDiscoveryService = MockStudioDiscoveryService();
    mockPaymentConfigService = MockPaymentConfigService();
    when(() => mockAuthBloc.state).thenReturn(
      AuthAuthenticatedState(user: testAppUser()),
    );
    when(() => mockFavoriteBloc.state).thenReturn(
      const FavoriteState(favorites: []),
    );
    when(() => mockPaymentConfigService.getPaymentConfig(any()))
        .thenAnswer((_) async => const StudioPaymentConfig());
  });

  DiscoveredStudio makeStudio({
    String name = 'Studio Test',
    String? address,
    double? rating,
    int? reviewCount,
    List<String> photoUrls = const [],
    bool isPartner = false,
    bool isVerified = false,
    bool isPioneer = false,
    int? pioneerNumber,
    List<String> services = const [],
    StudioType studioType = StudioType.independent,
  }) {
    return DiscoveredStudio(
      id: 's1',
      name: name,
      address: address,
      position: const LatLng(48.8566, 2.3522),
      rating: rating,
      reviewCount: reviewCount,
      photoUrls: photoUrls,
      photoUrl: photoUrls.isNotEmpty ? photoUrls.first : null,
      isPartner: isPartner,
      isVerified: isVerified,
      isPioneer: isPioneer,
      pioneerNumber: pioneerNumber,
      services: services,
      studioType: studioType,
    );
  }

  Widget buildSheet(DiscoveredStudio studio) {
    return buildTestApp(
      authBloc: mockAuthBloc,
      favoriteBloc: mockFavoriteBloc,
      child: Scaffold(
        body: StudioDetailBottomSheet(
          studio: studio,
          discoveryService: mockDiscoveryService,
          paymentConfigService: mockPaymentConfigService,
        ),
      ),
    );
  }

  group('StudioDetailBottomSheet', () {
    testWidgets('renders name', (tester) async {
      await tester.pumpWidget(buildSheet(makeStudio(isPartner: true)));
      await tester.pumpAndSettle();

      expect(find.text('Studio Test'), findsOneWidget);
    });

    testWidgets('shows address when available', (tester) async {
      await tester.pumpWidget(
        buildSheet(makeStudio(isPartner: true, address: '12 rue de Paris')),
      );
      await tester.pumpAndSettle();

      expect(find.text('12 rue de Paris'), findsOneWidget);
    });

    testWidgets('shows rating stat', (tester) async {
      await tester.pumpWidget(
        buildSheet(makeStudio(isPartner: true, rating: 4.8, reviewCount: 12)),
      );
      await tester.pumpAndSettle();

      expect(find.text('4.8'), findsOneWidget);
      expect(find.text('(12)'), findsOneWidget);
    });

    testWidgets('shows verified badge', (tester) async {
      await tester.pumpWidget(
        buildSheet(makeStudio(isPartner: true, isVerified: true)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Verified'), findsOneWidget);
    });

    testWidgets('shows services', (tester) async {
      await tester.pumpWidget(buildSheet(
        makeStudio(isPartner: true, services: ['Mixing', 'Mastering']),
      ));
      await tester.pumpAndSettle();

      expect(find.text('Mixing'), findsOneWidget);
      expect(find.text('Mastering'), findsOneWidget);
    });

    testWidgets('shows "Book" for a partner studio', (tester) async {
      await tester.pumpWidget(buildSheet(makeStudio(isPartner: true)));
      await tester.pumpAndSettle();

      expect(find.text('Book'), findsOneWidget);
      expect(find.text('Not available'), findsNothing);
    });

    testWidgets('shows "Not available" for a non-partner Google result', (tester) async {
      when(() => mockDiscoveryService.getStudioPhotoUrls(any()))
          .thenAnswer((_) async => const []);

      await tester.pumpWidget(buildSheet(makeStudio(isPartner: false)));
      await tester.pumpAndSettle();

      expect(find.text('Not available'), findsOneWidget);
      expect(find.text('Book'), findsNothing);
    });

    testWidgets('partner studio header shows its gallery without calling the discovery service', (tester) async {
      await tester.pumpWidget(buildSheet(makeStudio(
        isPartner: true,
        photoUrls: const ['https://example.com/a.jpg', 'https://example.com/b.jpg'],
      )));
      await tester.pumpAndSettle();

      expect(find.byType(PageView), findsOneWidget);
      verifyNever(() => mockDiscoveryService.getStudioPhotoUrls(any()));
    });

    testWidgets('non-partner studio fetches the full gallery lazily on open', (tester) async {
      when(() => mockDiscoveryService.getStudioPhotoUrls(any())).thenAnswer(
        (_) async => const [
          'https://example.com/a.jpg',
          'https://example.com/b.jpg',
          'https://example.com/c.jpg',
        ],
      );

      await tester.pumpWidget(buildSheet(makeStudio(isPartner: false)));
      // Avant résolution du Future : pas encore la galerie complète.
      await tester.pump();
      verify(() => mockDiscoveryService.getStudioPhotoUrls(any())).called(1);

      await tester.pumpAndSettle();
      expect(find.byType(PageView), findsOneWidget);
    });
  });
}
