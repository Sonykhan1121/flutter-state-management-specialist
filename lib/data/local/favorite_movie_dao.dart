import 'dart:convert';

import '../../core/database/app_database.dart';
import '../../domain/models/movie.dart';

/// The only class that reads or writes favorite_movies rows.
class FavoriteMovieDao {
  FavoriteMovieDao(this._database, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AppDatabase _database;
  final DateTime Function() _now;

  Future<List<Movie>> readAll() async {
    final rows = await (await _database.connection).query(
      'favorite_movies',
      orderBy: 'title COLLATE NOCASE ASC, imdb_id ASC',
    );
    return List.unmodifiable(rows.map(_fromRow));
  }

  Future<void> upsert(Movie movie) async {
    if (movie.id.trim().isEmpty) throw ArgumentError('Movie ID is required.');
    final db = await _database.connection;
    await db.transaction((txn) async {
      final values = _toRow(movie);
      final updated = await txn.update(
        'favorite_movies',
        values,
        where: 'imdb_id = ?',
        whereArgs: [movie.id],
      );
      if (updated == 0) {
        await txn.insert('favorite_movies', {
          ...values,
          'saved_at': _now().millisecondsSinceEpoch,
        });
      }
      // Updating metadata preserves the original saved_at timestamp.
    });
  }

  Future<void> delete(String movieId) async {
    await (await _database.connection).delete(
      'favorite_movies',
      where: 'imdb_id = ?',
      whereArgs: [movieId],
    );
  }

  static Map<String, Object?> _toRow(Movie movie) => {
    'imdb_id': movie.id,
    'title': movie.title,
    'release_year': movie.year,
    'genres_json': jsonEncode(movie.genres),
    'rating': movie.rating,
    'poster_url': movie.posterUrl,
    'plot': movie.plot,
    'director': movie.director,
    'actors': movie.actors,
    'runtime': movie.runtime,
    'rated': movie.rated,
  };

  static Movie _fromRow(Map<String, Object?> row) {
    final genres = jsonDecode(row['genres_json']! as String);
    if (genres is! List || genres.any((value) => value is! String)) {
      throw const FormatException('Invalid stored genres.');
    }
    return Movie(
      id: row['imdb_id']! as String,
      title: row['title']! as String,
      year: row['release_year']! as int,
      genres: List<String>.unmodifiable(genres.cast<String>()),
      rating: (row['rating']! as num).toDouble(),
      posterUrl: row['poster_url']! as String,
      plot: row['plot']! as String,
      director: row['director']! as String,
      actors: row['actors']! as String,
      runtime: row['runtime']! as String,
      rated: row['rated']! as String,
    );
  }
}
