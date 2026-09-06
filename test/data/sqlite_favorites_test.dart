import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/core/database/app_database.dart';
import 'package:provider_project/data/local/favorite_movie_dao.dart';
import 'package:provider_project/data/repositories/sqlite_favorites_repository.dart';
import 'package:provider_project/domain/repositories/favorites_repository.dart';
import 'package:provider_project/domain/models/movie.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../fakes.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late String file;
  late AppDatabase database;
  late FavoritesRepository repository;

  AppDatabase openOwner() =>
      AppDatabase(factory: databaseFactoryFfi, databasePath: file);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('movie-sqlite-test-');
    file = '${directory.path}/movies.db';
    database = openOwner();
    repository = SqliteFavoritesRepository(
      FavoriteMovieDao(
        database,
        now: () => DateTime.fromMillisecondsSinceEpoch(1234),
      ),
    );
  });
  tearDown(() async {
    await database.close();
    await directory.delete(recursive: true);
  });

  test(
    'favorites survive closing and reopening the actual SQLite file',
    () async {
      await repository.saveFavorite(testMovies.first);
      await database.close();
      database = openOwner();
      repository = SqliteFavoritesRepository(FavoriteMovieDao(database));
      final restored = (await repository.loadFavorites()).single;
      expect(restored.id, testMovies.first.id);
      expect(restored.genres, testMovies.first.genres);
      expect(restored.rating, testMovies.first.rating);
      expect(restored.plot, testMovies.first.plot);
      await repository.removeFavorite(restored.id);
      expect(await repository.loadFavorites(), isEmpty);
    },
  );

  test(
    'upsert updates metadata without duplicate rows or resetting saved_at',
    () async {
      await repository.saveFavorite(testMovies.first);
      final updated = Movie(
        id: testMovies.first.id,
        title: 'Updated title',
        year: 2025,
        genres: const ['Action', 'Sci-Fi'],
        rating: 9.1,
        posterUrl: '',
        plot: 'Updated',
        director: 'Director',
        actors: 'Cast',
        runtime: '90 min',
        rated: 'PG',
      );
      await repository.saveFavorite(updated);
      final rows = await (await database.connection).query('favorite_movies');
      expect(rows, hasLength(1));
      expect(rows.single['saved_at'], 1234);
      expect((await repository.loadFavorites()).single.title, 'Updated title');
    },
  );

  test(
    'simultaneous first operations share a connection and commit every favorite',
    () async {
      await Future.wait(testMovies.map(repository.saveFavorite));
      expect(await repository.loadFavorites(), hasLength(2));
      final connections = await Future.wait([
        database.connection,
        database.connection,
      ]);
      expect(identical(connections.first, connections.last), isTrue);
    },
  );

  test(
    'version 1 upgrade preserves favorites and adds the query index',
    () async {
      await database.close();
      final legacy = await databaseFactoryFfi.openDatabase(
        file,
        options: OpenDatabaseOptions(
          version: 1,
          onCreate:
              (db, _) async => db.execute(
                await File('test/fixtures/favorites_v1.sql').readAsString(),
              ),
        ),
      );
      await legacy.insert('favorite_movies', {
        'imdb_id': 'legacy',
        'title': 'Legacy favorite',
        'release_year': 1999,
        'genres_json': '["Drama"]',
        'rating': 8.5,
        'poster_url': '',
        'plot': 'Kept',
        'director': 'Director',
        'actors': 'Cast',
        'runtime': '100 min',
        'rated': 'PG',
        'saved_at': 42,
      });
      await legacy.close();
      database = openOwner();
      repository = SqliteFavoritesRepository(FavoriteMovieDao(database));
      expect((await repository.loadFavorites()).single.id, 'legacy');
      final db = await database.connection;
      expect(await db.getVersion(), 2);
      expect(
        await db.rawQuery(
          "SELECT name FROM sqlite_master WHERE type='index' AND name='favorite_movies_title_idx'",
        ),
        hasLength(1),
      );
      expect((await db.query('favorite_movies')).single['saved_at'], 42);
    },
  );

  test(
    'SQL failures expose a retryable repository error and leave stored data intact',
    () async {
      await repository.saveFavorite(testMovies.first);
      final db = await database.connection;
      await db.execute(
        "CREATE TRIGGER reject_insert BEFORE INSERT ON favorite_movies BEGIN SELECT RAISE(ABORT, 'simulated disk failure'); END",
      );
      await expectLater(
        repository.saveFavorite(testMovies.last),
        throwsA(isA<FavoritesStorageException>()),
      );
      expect((await repository.loadFavorites()).map((m) => m.id), [
        testMovies.first.id,
      ]);
    },
  );

  test('quoted IDs are values, never executable SQL', () async {
    const quoted = Movie(
      id: "x' OR 1=1 --",
      title: 'Quoted',
      year: 2024,
      genres: [],
      rating: 0,
      posterUrl: '',
      plot: '',
      director: '',
      actors: '',
      runtime: '',
      rated: '',
    );
    await repository.saveFavorite(testMovies.first);
    await repository.saveFavorite(quoted);
    await repository.removeFavorite(quoted.id);
    expect((await repository.loadFavorites()).single.id, testMovies.first.id);
  });

  test('a failed open can be retried after repairing the file', () async {
    await File(file).writeAsString('not a SQLite database');
    await expectLater(database.connection, throwsA(isA<Exception>()));
    await File(file).delete();
    await repository.saveFavorite(testMovies.first);
    expect(await repository.loadFavorites(), hasLength(1));
  });

  test(
    'closing is idempotent and a closed owner cannot silently reopen',
    () async {
      await database.connection;
      await Future.wait([database.close(), database.close()]);
      await expectLater(database.connection, throwsStateError);
    },
  );
}
