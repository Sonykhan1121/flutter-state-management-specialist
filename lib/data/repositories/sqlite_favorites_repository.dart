import '../../domain/models/movie.dart';
import '../../domain/repositories/favorites_repository.dart';
import '../local/favorite_movie_dao.dart';

class SqliteFavoritesRepository implements FavoritesRepository {
  const SqliteFavoritesRepository(this._dao);
  final FavoriteMovieDao _dao;

  @override
  Future<List<Movie>> loadFavorites() =>
      _guard(_dao.readAll, 'Could not load saved favorites. Please retry.');

  @override
  Future<void> saveFavorite(Movie movie) => _guard(
    () => _dao.upsert(movie),
    'Could not save this favorite. Please retry.',
  );

  @override
  Future<void> removeFavorite(String movieId) => _guard(
    () => _dao.delete(movieId),
    'Could not remove this favorite. Please retry.',
  );

  Future<T> _guard<T>(Future<T> Function() action, String message) async {
    try {
      return await action();
    } on Exception catch (error) {
      throw FavoritesStorageException(message, cause: error);
    }
  }
}
