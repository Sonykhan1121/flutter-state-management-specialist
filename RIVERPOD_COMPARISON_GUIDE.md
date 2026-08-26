# Riverpod Comparison Guide

This branch keeps the data layer, product requirements, and visual design the
same as the `provider` branch. That makes the state-management differences easy
to inspect without confusing them with unrelated app changes.

## Direct mapping

| Provider branch | Riverpod branch |
| --- | --- |
| `MultiProvider` | `ProviderScope` plus top-level provider declarations |
| `Provider<MovieRepository>` | `Provider<MovieRepository>` |
| `ChangeNotifierProvider` | `NotifierProvider` |
| mutable private fields | immutable `MovieCatalogState` |
| `notifyListeners()` | assign a new `state` value |
| `context.read<T>()` | `ref.read(someProvider)` |
| `Consumer<T>` / `context.watch<T>()` | `ConsumerWidget` / `ref.watch(...)` |
| `Selector<T, R>` | `ref.watch(provider.select(...))` |
| constructor injection | providers compose with `ref.read`/`ref.watch` |
| widget wrapper in tests | `ProviderContainer` overrides or `ProviderScope` overrides |

## What Riverpod improves

- Provider declarations are ordinary global references and are not located by
  runtime type alone.
- Dependencies can be read outside the widget tree through a `ProviderContainer`.
- Multiple providers may expose the same value type without ambiguity.
- Overrides make repository fakes concise in both unit and widget tests.
- Immutable notifier state removes manual `notifyListeners()` calls.
- Provider composition is explicit through `ref`, without `ProxyProvider`
  variants.
- `FutureProvider`, `AsyncNotifierProvider`, and `AsyncValue` offer standardized
  loading/data/error handling when that model fits the feature.

## Riverpod costs and tradeoffs

- It introduces its own provider graph, terminology, and lifecycle rules beyond
  Flutter's widget tree.
- `ConsumerWidget`, `ConsumerStatefulWidget`, and `WidgetRef` are Riverpod-
  specific UI types.
- Immutable state requires disciplined copying or a code-generation/value-class
  tool as models grow.
- Families, auto-dispose, invalidation, refresh, keep-alive, and generated versus
  manual providers create more concepts to master.
- Overusing tiny providers can fragment feature logic and make the dependency
  graph difficult to follow.
- Code generation reduces boilerplate but adds build tooling and generated files;
  this project intentionally uses the manual API so every dependency is visible.

## Important design choices in this branch

`MovieCatalogNotifier` exposes one immutable `MovieCatalogState`. Assigning to
`state` notifies listeners automatically. It retains request IDs so an older
search result cannot overwrite a newer one.

`FavoriteMoviesNotifier` stores an immutable map. `isFavoriteProvider` is a
family that selects only membership for one movie ID, while the app-bar count
selects only map length. This is the Riverpod equivalent of Provider's
`Selector` optimization.

The repository provider is overridden in tests. No test-only switch is added to
production code, and notifiers do not know whether the dependency is real or a
fake.

The app uses an explicit status object for a close comparison with the Provider
branch. As an exercise, migrate the catalog to `AsyncNotifierProvider` and use
`AsyncValue` for loading/data/error while keeping query, genre, and sort state
clear.

## Comparison exercises

1. Put both branch versions of `lib/app.dart` side by side and trace ownership.
2. Compare a favorite heart in `movie_card.dart`: `Selector` versus a provider
   family and `.select`.
3. Compare controller tests with `ProviderContainer` tests.
4. Add title sorting to both branches and note where state mutation differs.
5. Add persisted favorites to both using the same repository interface.
6. Profile rebuilds in Flutter DevTools rather than assuming either is faster.
7. Decide which approach your team can debug most confidently six months later.

Choose based on project complexity, team knowledge, test needs, and lifecycle
requirements. Both approaches can produce a maintainable app when state
boundaries and dependencies are designed well.
