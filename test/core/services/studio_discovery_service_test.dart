import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:mocktail/mocktail.dart';
import 'package:uzme/core/models/discovered_studio.dart';
import 'package:uzme/core/services/google_places_client.dart';
import 'package:uzme/core/services/studio_discovery_service.dart';

import '../../helpers/mock_services.dart';

class _MockFirestore extends Mock implements FirebaseFirestore {}

void main() {
  late MockGooglePlacesClient mockPlaces;
  late StudioDiscoveryService service;

  setUp(() {
    mockPlaces = MockGooglePlacesClient();
    // StudioPartnerSource (Firestore) n'est jamais exercé par ces tests —
    // getStudioPhotoUrls ne le touche pas — mais la DI de
    // StudioDiscoveryService le construit quand même, d'où ce mock inerte.
    service = StudioDiscoveryService(
      placesClient: mockPlaces,
      firestore: _MockFirestore(),
    );
  });

  DiscoveredStudio googleStudio({
    String id = 'place_1',
    String? photoUrl,
    bool isPartner = false,
    bool isPro = false,
  }) {
    return DiscoveredStudio(
      id: id,
      name: 'Studio',
      position: const LatLng(0, 0),
      photoUrl: photoUrl,
      photoUrls: photoUrl != null ? [photoUrl] : const [],
      isPartner: isPartner,
      isPro: isPro,
    );
  }

  group('getStudioPhotoUrls', () {
    test(
      'still calls Details for a Google studio that already has a single '
      'preview photo — Nearby/Text Search never return more than one',
      () async {
        when(() => mockPlaces.getPhotoUrls(any())).thenAnswer(
          (_) async => const GooglePhotoGallery(
            ['url1', 'url2', 'url3'],
            [null, 'Jean Dupont', null],
          ),
        );

        final gallery = await service.getStudioPhotoUrls(
          googleStudio(photoUrl: 'url1'),
        );

        verify(() => mockPlaces.getPhotoUrls('place_1')).called(1);
        expect(gallery.urls, ['url1', 'url2', 'url3']);
        expect(gallery.attributions, [null, 'Jean Dupont', null]);
        expect(gallery.hasError, isFalse);
      },
    );

    test('never calls Google for a partner studio', () async {
      final studio = googleStudio(
        isPartner: true,
        photoUrl: null,
      ).copyWith(photoUrls: ['firestore_url']);

      final gallery = await service.getStudioPhotoUrls(studio);

      verifyNever(() => mockPlaces.getPhotoUrls(any()));
      expect(gallery.urls, ['firestore_url']);
      expect(gallery.hasError, isFalse);
    });

    test('never calls Google for a pro marker', () async {
      final studio = googleStudio(isPro: true, photoUrl: 'avatar');

      final gallery = await service.getStudioPhotoUrls(studio);

      verifyNever(() => mockPlaces.getPhotoUrls(any()));
      expect(gallery.urls, ['avatar']);
    });

    test('flags hasError on network failure, falls back to the known '
        'preview photo, and does not cache the failure', () async {
      when(() => mockPlaces.getPhotoUrls(any())).thenAnswer((_) async => null);

      final gallery = await service.getStudioPhotoUrls(
        googleStudio(photoUrl: 'url1'),
      );
      expect(gallery.urls, ['url1']);
      expect(gallery.hasError, isTrue);

      // Un second appel doit retenter l'API, pas rester bloqué sur l'échec.
      when(() => mockPlaces.getPhotoUrls(any())).thenAnswer(
        (_) async => const GooglePhotoGallery(['url1', 'url2'], [null, null]),
      );
      final retried = await service.getStudioPhotoUrls(
        googleStudio(photoUrl: 'url1'),
      );
      verify(() => mockPlaces.getPhotoUrls('place_1')).called(2);
      expect(retried.urls, ['url1', 'url2']);
      expect(retried.hasError, isFalse);
    });

    test('returns an empty gallery, no error, when Google has nothing and '
        'there was no preview photo either', () async {
      when(
        () => mockPlaces.getPhotoUrls(any()),
      ).thenAnswer((_) async => const GooglePhotoGallery([], []));

      final gallery = await service.getStudioPhotoUrls(googleStudio());

      expect(gallery.urls, isEmpty);
      expect(gallery.hasError, isFalse);
    });

    test(
      'dedupes concurrent calls for the same studio into one Details call',
      () async {
        when(() => mockPlaces.getPhotoUrls(any())).thenAnswer(
          (_) async => const GooglePhotoGallery(['url1', 'url2'], [null, null]),
        );

        final studio = googleStudio(photoUrl: 'url1');
        final results = await Future.wait([
          service.getStudioPhotoUrls(studio),
          service.getStudioPhotoUrls(studio),
        ]);

        verify(() => mockPlaces.getPhotoUrls('place_1')).called(1);
        expect(results[0].urls, ['url1', 'url2']);
        expect(results[1].urls, ['url1', 'url2']);
      },
    );
  });
}
