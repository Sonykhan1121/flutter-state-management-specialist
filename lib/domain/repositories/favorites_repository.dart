import '../models/movie.dart';

/// Persistence contract. No Flutter, state-management, or SQLite imports.
abstract interface class FavoritesRepository {
  Future<List<Movie>> loadFavorites();
  Future<void> saveFavorite(Movie movie);
  Future<void> removeFavorite(String movieId);
}

class FavoritesStorageException implements Exception {
  const FavoritesStorageException(this.message, {this.cause});
  final String message;
  final Object? cause;
  @override
  String toString() => message;
}
