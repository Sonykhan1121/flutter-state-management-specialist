import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';
import 'sample_movies.dart';

abstract interface class MovieRepository {
  Future<MoviePage> searchMovies(String query, {int page = 1});
}

class MoviePage {
  const MoviePage({
    required this.movies,
    required this.page,
    required this.totalResults,
    required this.hasMore,
  });

  final List<Movie> movies;
  final int page;
  final int totalResults;
  final bool hasMore;
}

MovieRepository createMovieRepository() {
  const apiKey = String.fromEnvironment('OMDB_API_KEY');
  return apiKey.trim().isEmpty
      ? const SampleMovieRepository()
      : OmdbMovieRepository(client: http.Client(), apiKey: apiKey);
}

class SampleMovieRepository implements MovieRepository {
  const SampleMovieRepository();

  @override
  Future<MoviePage> searchMovies(String query, {int page = 1}) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final needle = query.trim().toLowerCase();
    final matches =
        needle.isEmpty
            ? sampleMovies
            : sampleMovies
                .where((movie) {
                  final searchable =
                      [
                        movie.title,
                        movie.plot,
                        movie.director,
                        ...movie.genres,
                      ].join(' ').toLowerCase();
                  return searchable.contains(needle);
                })
                .toList(growable: false);
    final movies = page == 1 ? matches : const <Movie>[];
    return MoviePage(
      movies: List.unmodifiable(movies),
      page: page,
      totalResults: matches.length,
      hasMore: false,
    );
  }
}

class OmdbMovieRepository implements MovieRepository {
  OmdbMovieRepository({required this.client, required this.apiKey});

  final http.Client client;
  final String apiKey;

  @override
  Future<MoviePage> searchMovies(String query, {int page = 1}) async {
    final searchTerm = query.trim().isEmpty ? 'star' : query.trim();
    final uri = _buildUri({'s': searchTerm, 'type': 'movie', 'page': '$page'});
    final payload = await _getJson(uri);

    if (payload['Response'] == 'False') {
      final message = '${payload['Error'] ?? 'Movie search failed.'}';
      if (message.toLowerCase().contains('not found')) {
        return MoviePage(
          movies: const [],
          page: page,
          totalResults: 0,
          hasMore: false,
        );
      }
      throw MovieRepositoryException(message);
    }

    final totalResults = int.tryParse('${payload['totalResults'] ?? ''}') ?? 0;
    final results = (payload['Search'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .take(10);
    final movies = await Future.wait(
      results.map((item) async {
        final id = '${item['imdbID'] ?? ''}';
        if (id.isEmpty) return null;
        try {
          return await _getDetails(id);
        } on MovieRepositoryException {
          return null;
        }
      }),
    );
    return MoviePage(
      movies: movies.whereType<Movie>().toList(growable: false),
      page: page,
      totalResults: totalResults,
      hasMore: page * 10 < totalResults,
    );
  }

  Future<Movie> _getDetails(String imdbId) async {
    final uri = _buildUri({'i': imdbId, 'plot': 'full'});
    final payload = await _getJson(uri);
    if (payload['Response'] == 'False') {
      throw MovieRepositoryException(
        '${payload['Error'] ?? 'Details failed.'}',
      );
    }
    return Movie.fromOmdb(payload);
  }

  Uri _buildUri(Map<String, String> parameters) {
    return Uri.https('www.omdbapi.com', '/', {'apikey': apiKey, ...parameters});
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await client.get(uri);
    if (response.statusCode != 200) {
      throw MovieRepositoryException(
        'OMDb returned HTTP ${response.statusCode}.',
      );
    }
    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const MovieRepositoryException('OMDb returned invalid data.');
    }
    return decoded;
  }
}

class MovieRepositoryException implements Exception {
  const MovieRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
