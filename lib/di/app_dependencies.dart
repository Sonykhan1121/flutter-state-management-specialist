import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../core/database/app_database.dart';
import '../data/local/favorite_movie_dao.dart';
import '../data/repositories/movie_repository.dart';
import '../data/repositories/sqlite_favorites_repository.dart';
import '../data/repositories/trailer_repository.dart';
import '../domain/repositories/favorites_repository.dart';
import '../domain/repositories/movie_repository.dart';
import '../domain/repositories/trailer_repository.dart';

/// Composition root: application-owned resources and injectable contracts.
class AppDependencies {
  AppDependencies({
    MovieRepository? movies,
    FavoritesRepository? favorites,
    TrailerRepository? trailers,
    AppDatabase? database,
    http.Client? client,
  }) : _database = database ?? AppDatabase(),
       _client = client ?? http.Client() {
    const omdbKey = String.fromEnvironment('OMDB_API_KEY');
    const youtubeKey = String.fromEnvironment('YOUTUBE_API_KEY');
    this.movies =
        movies ??
        (omdbKey.trim().isEmpty
            ? const SampleMovieRepository()
            : OmdbMovieRepository(client: _client, apiKey: omdbKey));
    this.favorites =
        favorites ?? SqliteFavoritesRepository(FavoriteMovieDao(_database));
    this.trailers =
        trailers ??
        YoutubeTrailerRepository(client: _client, apiKey: youtubeKey);
  }

  final AppDatabase _database;
  final http.Client _client;
  late final MovieRepository movies;
  late final FavoritesRepository favorites;
  late final TrailerRepository trailers;

  void dispose() {
    _client.close();
    unawaited(
      _database.close().catchError((Object error, StackTrace stack) {
        FlutterError.reportError(
          FlutterErrorDetails(
            exception: error,
            stack: stack,
            library: 'movie database cleanup',
          ),
        );
      }),
    );
  }
}
