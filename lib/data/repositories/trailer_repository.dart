import 'dart:convert';
import '../../domain/repositories/trailer_repository.dart';

import 'package:http/http.dart' as http;

import 'package:provider_project/domain/models/movie.dart';

class YoutubeTrailerRepository implements TrailerRepository {
  YoutubeTrailerRepository({required this.client, required this.apiKey});

  final http.Client client;
  final String apiKey;

  @override
  bool get canSearchAutomatically => apiKey.trim().isNotEmpty;

  @override
  Uri youtubeSearchUri(Movie movie) => Uri.https(
    'www.youtube.com',
    '/results',
    {'search_query': '${movie.title} ${movie.year} official trailer'},
  );

  @override
  Future<Trailer?> findTrailer(Movie movie) async {
    if (!canSearchAutomatically) return null;
    final uri = Uri.https('www.googleapis.com', '/youtube/v3/search', {
      'part': 'snippet',
      'q': '${movie.title} ${movie.year} official trailer',
      'type': 'video',
      'videoEmbeddable': 'true',
      'videoSyndicated': 'true',
      'safeSearch': 'moderate',
      'maxResults': '1',
      'key': apiKey,
    });
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw TrailerRepositoryException(
        'YouTube returned HTTP ${response.statusCode}.',
      );
    }
    final payload = jsonDecode(response.body);
    if (payload is! Map<String, dynamic>) {
      throw const TrailerRepositoryException('YouTube returned invalid data.');
    }
    final items = payload['items'];
    if (items is! List<dynamic> || items.isEmpty) return null;
    final item = items.first;
    if (item is! Map<String, dynamic>) return null;
    final id = item['id'];
    final snippet = item['snippet'];
    if (id is! Map<String, dynamic> || snippet is! Map<String, dynamic>) {
      return null;
    }
    final videoId = '${id['videoId'] ?? ''}';
    if (videoId.isEmpty) return null;
    return Trailer(
      videoId: videoId,
      title: _decodeHtml('${snippet['title'] ?? 'Official trailer'}'),
    );
  }

  String _decodeHtml(String value) => value
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"');
}
