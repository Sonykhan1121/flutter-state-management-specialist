# Flutter State Management Specialist — Riverpod

This branch implements the same complete movie app with modern Riverpod
`NotifierProvider`s and immutable state.

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

| Movie catalog | Movie details |
| --- | --- |
| <img src="docs/screenshots/provider-movie-list.png" alt="Riverpod movie catalog with search, genre filters, sorting, ratings, and favorites" width="100%"> | <img src="docs/screenshots/provider-movie-details.png" alt="Riverpod movie details with trailer action, rating, plot, and cast" width="100%"> |

## Run it

```sh
flutter pub get
flutter run
```

The bundled catalog is used when no API key is supplied. To make a local config, copy and edit the ignored config from the safe template:

```sh
cp omdb.example.json omdb.json
flutter run --dart-define-from-file=omdb.json
```

The API key is inserted centrally by `OmdbMovieRepository._buildUri`, so every
OMDb search and detail request includes the `apikey` query parameter.

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

## Compare the architecture

Read [RIVERPOD_COMPARISON_GUIDE.md](RIVERPOD_COMPARISON_GUIDE.md), then explore:

- `lib/app.dart` — `ProviderScope` and test overrides
- `lib/presentation/view_models/movie_providers.dart` — immutable state and notifiers
- `lib/presentation/views/home_screen.dart` — `ref.read`, `ref.watch`, and `.select`
- `lib/data/repositories/movie_repository.dart` — API boundary and testable abstraction
- `lib/domain/repositories/favorites_repository.dart` — storage interface (implementation and schema are described in the MVVM guide)
- `lib/data/repositories/trailer_repository.dart` — YouTube Data API search
- `lib/presentation/views/trailer_screen.dart` — inline YouTube player and fallback

Run the checks with:

```sh
flutter analyze
flutter test
```

## SQLite and MVVM

Read [MVVM_SQLITE_GUIDE.md](MVVM_SQLITE_GUIDE.md) for the architecture, database, tests, and exercises.
