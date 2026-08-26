# Flutter State Management Specialist — Riverpod

This branch implements the same complete movie app with modern Riverpod
`NotifierProvider`s and immutable state.

## Features

- Movie list and debounced search
- Genre filter
- Sort by IMDb rating or release year
- Favorite/unfavorite from the list or details screen
- Movie details
- Favorites screen
- Loading, refresh, empty, and error states
- Stale-request protection for rapid searches
- Bundled offline demo catalog

## Run it

```sh
flutter pub get
flutter run
```

The bundled catalog is used when no API key is supplied. To query OMDb:

```sh
flutter run --dart-define=OMDB_API_KEY=your_key_here
```

OMDb is an independent service and is not affiliated with IMDb. Its search
response does not contain genres or ratings, so this learning app hydrates the
first ten results with detail calls, then filters and sorts that page locally.
For a production app, add caching, pagination, request throttling, and a backend
that protects the key.

## Compare the architecture

Read [RIVERPOD_COMPARISON_GUIDE.md](RIVERPOD_COMPARISON_GUIDE.md), then explore:

- `lib/app.dart` — `ProviderScope` and test overrides
- `lib/state/movie_providers.dart` — immutable state and notifiers
- `lib/screens/home_screen.dart` — `ref.read`, `ref.watch`, and `.select`
- `lib/data/movie_repository.dart` — API boundary and testable abstraction

Run the checks with:

```sh
flutter analyze
flutter test
```
