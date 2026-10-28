import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:uzme/core/services/google_places_client.dart';

void main() {
  group('GooglePlacesClient.getPhotoUrls', () {
    test('returns null on HTTP failure — distinct from "no photos"', () async {
      final client = GooglePlacesClient(
        httpClient: MockClient((_) async => http.Response('', 500)),
      );

      final gallery = await client.getPhotoUrls('place_1');

      expect(gallery, isNull);
    });

    test(
      'returns an empty (non-null) gallery when the place has no photo',
      () async {
        final client = GooglePlacesClient(
          httpClient: MockClient(
            (_) async =>
                http.Response(json.encode({'status': 'OK', 'result': {}}), 200),
          ),
        );

        final gallery = await client.getPhotoUrls('place_1');

        expect(gallery, isNotNull);
        expect(gallery!.urls, isEmpty);
      },
    );

    test('requests photos and reviews sorted by newest, in one call', () async {
      Uri? capturedUrl;
      final client = GooglePlacesClient(
        httpClient: MockClient((request) async {
          capturedUrl = request.url;
          return http.Response(
            json.encode({'status': 'OK', 'result': {}}),
            200,
          );
        }),
      );

      await client.getPhotoUrls('place_1');

      expect(capturedUrl!.queryParameters['fields'], 'photos,reviews');
      expect(capturedUrl!.queryParameters['reviews_sort'], 'newest');
    });

    test('parses up to 5 reviews alongside the photos', () async {
      final client = GooglePlacesClient(
        httpClient: MockClient(
          (_) async => http.Response(
            json.encode({
              'status': 'OK',
              'result': {
                'reviews': [
                  {
                    'author_name': 'Jean Dupont',
                    'rating': 5,
                    'relative_time_description': 'il y a une semaine',
                    'text': 'Super studio.',
                    'profile_photo_url': 'https://example.com/avatar.jpg',
                  },
                ],
              },
            }),
            200,
          ),
        ),
      );

      final gallery = await client.getPhotoUrls('place_1');

      expect(gallery!.reviews, hasLength(1));
      expect(gallery.reviews.first.authorName, 'Jean Dupont');
      expect(gallery.reviews.first.rating, 5);
      expect(
        gallery.reviews.first.authorPhotoUrl,
        'https://example.com/avatar.jpg',
      );
    });

    test('parses the photo attribution, stripped of its HTML link', () async {
      final client = GooglePlacesClient(
        httpClient: MockClient(
          (_) async => http.Response(
            json.encode({
              'status': 'OK',
              'result': {
                'photos': [
                  {
                    'photo_reference': 'ref1',
                    'html_attributions': [
                      '<a href="https://maps.google.com/x">Jean Dupont</a>',
                    ],
                  },
                ],
              },
            }),
            200,
          ),
        ),
      );

      final gallery = await client.getPhotoUrls('place_1');

      expect(gallery!.urls, hasLength(1));
      expect(gallery.attributions, ['Jean Dupont']);
    });
  });
}
