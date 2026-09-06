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
          );
