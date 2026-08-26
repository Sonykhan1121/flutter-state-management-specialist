# Flutter State Management Specialist

A branch-by-branch learning repository for building the same Flutter movie app
with three state-management approaches.

## Branches

- `main` — project brief and the original Flutter starter.
- [`provider`](https://github.com/Sonykhan1121/flutter-state-management-specialist/tree/provider)
  — complete app using `provider` and `ChangeNotifier`.
- [`riverpod`](https://github.com/Sonykhan1121/flutter-state-management-specialist/tree/riverpod)
  — the same app using modern Riverpod providers/notifiers.
- [`bloc`](https://github.com/Sonykhan1121/flutter-state-management-specialist/tree/bloc)
  — the same app using a full Bloc for the catalog and Cubit for favorites.

## Shared feature set

All three implementations have the same product behavior:

- OMDb movie search with debouncing
- Page-by-page loading with a bottom spinner, automatic infinite scroll, and
  retry
- Genre filtering and IMDb rating/year sorting across loaded pages
- Favorite/unfavorite actions persisted in a device SQLite database
- Movie details and a favorites screen
- Automatic YouTube trailer search and in-app playback when
  `YOUTUBE_API_KEY` is supplied
- In-app YouTube search fallback when no YouTube Data API key is configured
- Bundled demo movies when no `OMDB_API_KEY` is supplied

The SQLite implementation targets Android, iOS, and macOS. Each implementation
injects storage and API repositories so tests use deterministic in-memory
fakes rather than native plugins or live network calls.

## Screenshots

| Movie catalog | Movie details |
| --- | --- |
| <img src="docs/screenshots/provider-movie-list.png" alt="Movie catalog with search, genre filters, sorting, ratings, and favorites" width="100%"> | <img src="docs/screenshots/provider-movie-details.png" alt="Movie details with trailer action, rating, plot, director, and cast" width="100%"> |

Start with the `provider` branch and follow its learning guide. Then compare it
with `riverpod` and `bloc`; keeping the product requirements the same makes the
state-management tradeoffs easier to see.
