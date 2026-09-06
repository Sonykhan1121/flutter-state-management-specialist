import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

/// Owns one connection. SQL lives in DAOs; widgets never open databases.
class AppDatabase {
  AppDatabase({DatabaseFactory? factory, String? databasePath})
    : _factory = factory,
      _databasePath = databasePath;

  static const fileName = 'movie_explorer.db';
  static const schemaVersion = 2;
  final DatabaseFactory? _factory;
  final String? _databasePath;
  Future<Database>? _opening;
  Future<void>? _closing;
  bool _closed = false;

  Future<Database> get connection {
    if (_closed) return Future.error(StateError('Database owner is closed.'));
    // Cache the future, not just the result: simultaneous reads share an open.
    return _opening ??= _open();
  }

  Future<Database> _open() async {
    try {
      final factory = _factory ?? databaseFactory;
      final databasePath =
          _databasePath ??
          path.join(await factory.getDatabasesPath(), fileName);
      return await factory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(
          version: schemaVersion,
          singleInstance: false,
          onCreate: (db, _) async {
            await db.execute('''
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
            await _addTitleIndex(db);
          },
          onUpgrade: (db, oldVersion, _) async {
            // sqflite executes migrations in a transaction. Version 1 favorites
            // remain intact; never delete a user's database to "fix" upgrades.
            if (oldVersion < 2) await _addTitleIndex(db);
          },
        ),
      );
    } catch (_) {
      _opening = null; // Allow retry after a transient open failure.
      rethrow;
    }
  }

  static Future<void> _addTitleIndex(Database db) => db.execute('''
    CREATE INDEX favorite_movies_title_idx
    ON favorite_movies(title COLLATE NOCASE, imdb_id)
  ''');

  Future<void> close() {
    _closed = true;
    return _closing ??= _close();
  }

  Future<void> _close() async {
    final pending = _opening;
    if (pending == null) return;
    Database db;
    try {
      db = await pending;
    } catch (_) {
      return; // The caller of connection already receives an opening failure.
    }
    await db.close();
  }
}
