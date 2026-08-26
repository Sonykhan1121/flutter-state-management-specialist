# Flutter State Management Specialist

A branch-by-branch learning repository for building the same Flutter movie app
with two state-management approaches.

## Branches

- `main` — project brief and the original Flutter starter.
- `provider` — complete app using `provider` and `ChangeNotifier`.
- `riverpod` — the same app using modern Riverpod providers/notifiers.

Both implementations cover movie search, genre filtering, rating/year sorting,
favorite/unfavorite actions, movie details, and a favorites screen. They use
OMDb when an API key is supplied and bundled demo data otherwise.

## Screenshots

| Movie catalog | Movie details |
| --- | --- |
| <img src="docs/screenshots/provider-movie-list.png" alt="Provider movie catalog with search, genre filters, sorting, ratings, and favorites" width="100%"> | <img src="docs/screenshots/provider-movie-details.png" alt="Provider movie details screen with rating, genres, plot, director, cast, and IMDb ID" width="100%"> |

Start with the `provider` branch and follow its learning guide. Then compare it
with `riverpod`; keeping the product requirements the same makes the state-
management tradeoffs easier to see.
