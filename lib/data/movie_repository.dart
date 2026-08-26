import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/movie.dart';
import 'sample_movies.dart';

abstract interface class MovieRepository {
  Future<List<Movie>> searchMovies(String query);
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
  Future<List<Movie>> searchMovies(String query) async {
    await Future<void>.delayed(const Duration(milliseconds: 250));
    final needle = query.trim().toLowerCase();
    if (needle.isEmpty) return sampleMovies;

    return sampleMovies
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
  }
}

class OmdbMovieRepository implements MovieRepository {
  OmdbMovieRepository({required this.client, required this.apiKey});

  final http.Client client;
  final String apiKey;

  @override
  Future<List<Movie>> searchMovies(String query) async {
    final searchTerm = query.trim().isEmpty ? 'star' : query.trim();
    final uri = Uri.https('www.omdbapi.com', '/', {
      'apikey': apiKey,
      's': searchTerm,
      'type': 'movie',
    });
    final payload = await _getJson(uri);

    if (payload['Response'] == 'False') {
      final message = '${payload['Error'] ?? 'Movie search failed.'}';
      if (message.toLowerCase().contains('not found')) return const [];
      throw MovieRepositoryException(message);
    }

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
    return movies.whereType<Movie>().toList(growable: false);
  }

  Future<Movie> _getDetails(String imdbId) async {
    final uri = Uri.https('www.omdbapi.com', '/', {
      'apikey': apiKey,
      'i': imdbId,
      'plot': 'full',
    });
    final payload = await _getJson(uri);
    if (payload['Response'] == 'False') {
      throw MovieRepositoryException(
        '${payload['Error'] ?? 'Details failed.'}',
      );
    }
    return Movie.fromOmdb(payload);
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
