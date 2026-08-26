import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider_project/data/trailer_repository.dart';

import 'fakes.dart';

void main() {
  test('searches YouTube for an embeddable official trailer', () async {
    late Uri requestedUri;
    final repository = YoutubeTrailerRepository(
      apiKey: 'test-key',
      client: MockClient((request) async {
        requestedUri = request.url;
        return http.Response(
          jsonEncode({
            'items': [
              {
                'id': {'videoId': 'video-123'},
                'snippet': {'title': 'Movie &amp; Trailer'},
              },
            ],
          }),
          200,
        );
      }),
    );

    final trailer = await repository.findTrailer(testMovies.first);

    expect(requestedUri.queryParameters['type'], 'video');
    expect(requestedUri.queryParameters['videoEmbeddable'], 'true');
    expect(requestedUri.queryParameters['q'], contains('official trailer'));
    expect(trailer?.videoId, 'video-123');
    expect(trailer?.title, 'Movie & Trailer');
  });
}
