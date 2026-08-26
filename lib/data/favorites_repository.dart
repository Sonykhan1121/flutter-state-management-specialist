import 'dart:convert';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import '../models/movie.dart';

abstract interface class FavoritesRepository {
  Future<List<Movie>> loadFavorites();

  Future<void> saveFavorite(Movie movie);

  Future<void> removeFavorite(String movieId);
}

FavoritesRepository createFavoritesRepository() => SqliteFavoritesRepository();

class SqliteFavoritesRepository implements FavoritesRepository {
  Database? _database;

  Future<Database> get _db async {
    final existing = _database;
    if (existing != null) return existing;

    final databasePath = path.join(
      await getDatabasesPath(),
      'movie_explorer.db',
    );
    return _database = await openDatabase(
      databasePath,
      version: 1,
      onCreate: (database, _) async {
        await database.execute('''
          CREATE TABLE favorite_movies (
            imdb_id TEXT PRIMARY KEY,
            title TEXT NOT NULL,
            release_year INTEGER NOT NULL,
            genres_json TEXT NOT NULL,
            rating REAL NOT NULL,
            poster_url TEXT NOT NULL,
            plot TEXT NOT NULL,
            director TEXT NOT NULL,
            actors TEXT NOT NULL,
            runtime TEXT NOT NULL,
            rated TEXT NOT NULL,
            saved_at INTEGER NOT NULL
          )
        ''');
      },
    );
  }

  @override
  Future<List<Movie>> loadFavorites() async {
    final rows = await (await _db).query(
      'favorite_movies',
      orderBy: 'title COLLATE NOCASE ASC',
    );
    return rows.map(_movieFromRow).toList(growable: false);
  }

  @override
  Future<void> saveFavorite(Movie movie) async {
    await (await _db).insert(
      'favorite_movies',
      _movieToRow(movie),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<void> removeFavorite(String movieId) async {
    await (await _db).delete(
      'favorite_movies',
      where: 'imdb_id = ?',
      whereArgs: [movieId],
    );
  }

  Map<String, Object?> _movieToRow(Movie movie) => {
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
    'saved_at': DateTime.now().millisecondsSinceEpoch,
  };

  Movie _movieFromRow(Map<String, Object?> row) {
    final decodedGenres = jsonDecode(row['genres_json']! as String);
    return Movie(
      id: row['imdb_id']! as String,
      title: row['title']! as String,
      year: row['release_year']! as int,
      genres: (decodedGenres as List<dynamic>)
          .map((genre) => '$genre')
          .toList(growable: false),
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
