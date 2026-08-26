# Flutter State Management Specialist — Bloc

This branch implements the complete movie app with `flutter_bloc`: a full
`Bloc` for the movie catalog and a focused `Cubit` for favorites.

## Features

- Paginated movie list, debounced search, and automatic bottom loading
- Genre filter
- Sort by IMDb rating or release year
- SQLite-persisted favorites from the list or details screen
- Movie details with in-app YouTube trailer playback
- Favorites screen
- Loading, refresh, empty, and error states
- Stale-request protection for rapid searches
- Bundled offline demo catalog

## Screenshots

The UI is deliberately identical across state-management branches so the
architecture—not the pixels—is what you compare.

| Movie catalog | Movie details |
| --- | --- |
| <img src="docs/screenshots/provider-movie-list.png" alt="Bloc movie catalog with search, genre filters, sorting, ratings, and favorites" width="100%"> | <img src="docs/screenshots/provider-movie-details.png" alt="Bloc movie details with trailer action, rating, plot, and cast" width="100%"> |

## Run it

```sh
flutter pub get
flutter run
```

The bundled catalog is used when no API key is supplied. This checkout already
has an ignored local `omdb.json`. To make your own local config, copy and edit
the safe template:

```sh
cp omdb.example.json omdb.json
flutter run --dart-define-from-file=omdb.json
```

You can also use a command-line definition:

```sh
flutter run --dart-define=OMDB_API_KEY=YOUR_KEY
```

The API key is inserted centrally by `OmdbMovieRepository._buildUri`, so every
OMDb search and detail request includes the `apikey` query parameter. Never
commit a real key; both `omdb.json` and common environment files are ignored.

`YOUTUBE_API_KEY` is optional. When supplied, the app searches the YouTube Data
API for an embeddable official trailer and plays it inside the app. Without it,
the trailer screen offers an in-app browser search instead. YouTube search API
quota and terms apply.

OMDb is an independent service and is not affiliated with IMDb. Its search
response does not contain genres or ratings, so this learning app hydrates each
10-result page with detail calls. Scrolling near the bottom requests the next
OMDb page. Genre filtering and sorting apply to the pages loaded so far.

Favorites are stored in the device's `movie_explorer.db` SQLite database and
survive app restarts. For production, also add request caching, throttling, and
a backend that protects API keys.

## Learn the architecture

Read [BLOC_SPECIALIST_GUIDE.md](BLOC_SPECIALIST_GUIDE.md), then explore:

- `lib/app.dart` — `RepositoryProvider` and `MultiBlocProvider`
- `lib/bloc/movie_catalog_bloc.dart` — events, immutable state, async work,
  derived views, and stale-request protection
- `lib/bloc/favorites_cubit.dart` — a small Cubit with immutable state
- `lib/screens/home_screen.dart` — `BlocBuilder`, `BlocSelector`, and `read`
- `lib/data/movie_repository.dart` — API boundary and testable abstraction
- `lib/data/favorites_repository.dart` — SQLite schema and persistence
- `lib/data/trailer_repository.dart` — YouTube Data API search
- `lib/screens/trailer_screen.dart` — inline YouTube player and fallback
- `test/movie_catalog_bloc_test.dart` — transition-focused `bloc_test` examples

Run the checks with:

```sh
flutter analyze
flutter test
```
