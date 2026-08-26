# Bloc Specialist Guide

Bloc makes state transitions explicit. Widgets send events, a Bloc transforms
those events into immutable states, and widgets rebuild from the emitted state.
Cubit is the lighter member of the same family: callers invoke methods directly
instead of creating events.

## 1. Build the correct mental model

This project separates three jobs:

1. `MovieRepository` performs I/O and converts remote data into domain models.
2. `MovieCatalogBloc` and `FavoritesCubit` own application state and business
   transitions.
3. Widgets render state and forward user intent.

The catalog flow is one-directional:

```text
user action -> event -> Bloc event handler -> repository (when needed)
            -> immutable state emitted -> listening widgets rebuild
```

Favorites are simple enough to skip event classes:

```text
heart tap -> Cubit.toggle(movie) -> immutable FavoritesState emitted
          -> selected widgets rebuild
```

Neither state object stores `BuildContext`, and both receive dependencies from
outside. Their transitions can therefore be tested without rendering widgets.

## 2. Bloc versus Cubit

Use a full `Bloc<Event, State>` when named events make behavior easier to audit,
multiple inputs share transition rules, or you need event transformers such as
restartable, droppable, sequential, or concurrent processing.

Use a `Cubit<State>` when the public commands are already clear as methods and
event objects would add little information. Favorites only needs `toggle`, so a
Cubit stays expressive without ceremony.

Do not decide by screen size. Decide by transition complexity, concurrency
needs, debugging requirements, and team conventions. It is normal to use both
in one application.

## 3. Understand the main flutter_bloc tools

### `RepositoryProvider<T>`

Provides a repository or service without making it reactive UI state. This app
exposes movie, SQLite favorites, and YouTube trailer repositories. The catalog
Bloc and favorites Cubit receive their dependencies through constructors.

### `BlocProvider<T>` and `MultiBlocProvider`

`BlocProvider` creates, scopes, exposes, and closes a Bloc or Cubit. Use
`create:` for an instance owned by the widget tree. Use `.value` only to expose
an existing instance without transferring ownership.

`MultiBlocProvider` flattens nested providers for readability; it does not
change scope or lifecycle.

### `context.read<T>()`

Gets a Bloc or Cubit without subscribing the widget. Use it to send intent:

```dart
context.read<MovieCatalogBloc>().add(
  const CatalogSortChanged(MovieSort.yearNewest),
);
```

For a Cubit, call its command directly:

```dart
context.read<FavoritesCubit>().toggle(movie);
```

### `BlocBuilder<B, S>`

Rebuilds from new states. Put it around the smallest meaningful UI section.
Use `buildWhen` only when it clarifies a measured or important rebuild rule;
do not hide an overly broad state model behind many complicated predicates.

### `BlocSelector<B, S, T>`

Selects one derived value and rebuilds only when that selected value changes.
Each heart icon selects one Boolean, while the app-bar badge selects the count.
Selected values should be immutable and have reliable equality.

### `BlocListener<B, S>`

Handles one-off reactions that do not build UI: navigation, snack bars,
dialogs, analytics, or focus changes. Keep these effects at the UI boundary.
Use `BlocConsumer` only when the same subtree genuinely needs both listening
and rebuilding.

## 4. Events and immutable states

Events should describe intent in past-tense or request language, such as
`CatalogSearchRequested` and `CatalogGenreChanged`. Avoid UI-shaped names such
as `SearchButtonTapped` when the same action could come from keyboard submit,
deep linking, or retry.

State is a snapshot, not a bag of setters. `MovieCatalogState` contains source
movies, status, query, genre, sort, and any error. Filtering and sorting are
derived from that snapshot so there is one source of truth.

Every emission creates a new state. `FavoritesCubit` also copies its map before
emitting it as unmodifiable data. Mutating a collection already held by an old
state breaks history, equality, tests, and rebuild reasoning.

## 5. Async work and event concurrency

The catalog emits loading before awaiting the repository, then success or
error. Existing movies remain available during refresh so the UI can show a
thin progress bar instead of replacing useful content.

Rapid searches may complete out of order. `_requestId` prevents an old response
from overwriting a newer query. In a larger application you can use event
transformers from `bloc_concurrency`:

- `restartable` for search-as-you-type;
- `droppable` for a submit action that must not overlap;
- `sequential` when order must be preserved;
- `concurrent` for independent work.

Choosing a transformer is a domain decision. Be able to explain what should
happen when the same event arrives twice before the first finishes.

The debounce timer stays in `_HomeScreenState` because it is a short-lived input
detail. Moving it into the Bloc could also be valid when multiple views produce
search events or the timing rule is part of product behavior.

`CatalogLoadMoreRequested` uses separate `isLoadingMore` and `loadMoreError`
fields. This preserves earlier pages if the next request fails and makes the
bottom spinner/retry state explicit. Results are appended by IMDb ID to prevent
duplicates while the active genre and sort remain derived from all loaded
pages.

`FavoritesCubit` loads complete movie records from `FavoritesRepository` and
performs optimistic SQLite writes. A failed write rolls the state back. The
storage interface is replaced with an in-memory fake in tests, so neither Cubit
nor widgets depend directly on the database plugin.

Trailer lookup is also repository-backed, but its loading/player lifecycle is
local to the trailer route. Use a Bloc only when the state is shared or the
transition complexity benefits from one; not every `Future` needs an event.

## 6. Bloc strengths

- Explicit inputs and outputs make state changes traceable.
- Immutable snapshots reduce accidental shared mutation.
- Business logic stays independent of widgets and `BuildContext`.
- Bloc and Cubit cover both structured and lightweight workflows.
- Event transformers provide a deliberate concurrency model.
- DevTools logging and a custom `BlocObserver` can expose every transition.
- `bloc_test` makes ordered state-transition tests concise.
- Predictable conventions scale well across larger teams.

## 7. Bloc tradeoffs

- Events, states, handlers, and wiring add code for simple state.
- A team can create ceremony without gaining clarity if every tiny interaction
  becomes a Bloc.
- Immutable copying and equality require discipline or generation tools.
- Event concurrency is powerful but easy to misunderstand if defaults and
  transformers are not discussed.
- One giant Bloc becomes as difficult to maintain as one giant notifier.
- UI-only state can become awkward when forced into an application Bloc.
- Indirect event-to-state flow may feel slower to trace for beginners than a
  direct method call.

These are tradeoffs, not defects. Bloc is especially valuable when explicit
transitions and shared team conventions outweigh its additional structure.

## 8. Common mistakes and fixes

### Mutating the current state

Create a new state and copy collections. Old states must remain historical
snapshots.

### Doing work in a widget build

Dispatch initial work when creating the Bloc or from an appropriate lifecycle
callback. A build method can run repeatedly and must remain free of side
effects.

### Calling `emit` outside an event handler

In a Bloc, emit only within registered handlers. Put reusable async behavior in
a private method that receives the handler's `Emitter`.

### Using Bloc for every text field and animation

Keep ephemeral state local unless another feature needs it, it must survive
navigation, or it represents business behavior.

### Rebuilding the entire page

Place `BlocBuilder` near the changing UI and use `BlocSelector` for small
projections such as counts and Boolean flags.

### Putting navigation inside a Bloc

Emit a meaningful state or effect signal and react with `BlocListener` in the
UI. Business logic should not depend on widget-tree navigation objects.

### Ignoring overlapping events

Specify whether overlapping work should cancel, queue, be ignored, or run
concurrently. Then test the chosen rule.

### Omitting equality strategy

For performance-sensitive apps, implement value equality with records,
`Equatable`, generated immutable classes, or explicit `==`/`hashCode`. This
small project uses selectors returning primitives and matcher-based tests, but
a production state model should have an intentional equality policy.

## 9. Testing strategy

- Use `bloc_test` to verify ordered emissions for an event or Cubit command.
- Assert meaningful fields, not every implementation detail of a state.
- Inject a fake repository rather than adding test flags to production logic.
- Widget-test the composition root and user-visible behavior.
- Cover success, empty, error, retry, filtering, sorting, next-page append,
  favorite persistence/removal, trailer lookup, and stale-response protection.
- Test observers and side effects separately from state reducers.

## 10. Compare Provider, Riverpod, and Bloc

| Concern | Provider | Riverpod | Bloc |
| --- | --- | --- | --- |
| Main input | Controller method | Notifier/provider API | Event or Cubit method |
| Main output | `notifyListeners()` | Immutable provider state | Emitted immutable state |
| Lookup | Widget-tree runtime lookup | Ref-based provider graph | Widget-tree Bloc lookup |
| Async model | Team-designed | `AsyncValue` and provider patterns | Explicit states and event concurrency |
| UI precision | `Selector` / `select` | `select` and provider granularity | `BlocSelector` / `buildWhen` |
| Testing | Plain object + widget overrides | Provider container overrides | `bloc_test` transition sequences |
| Typical strength | Simplicity | Compile-safe graph and composability | Explicit, auditable transitions |
| Typical cost | Mutable notification discipline | Concepts and generated APIs | Boilerplate and conventions |

Do not compare line counts alone. Compare failure behavior, lifecycle,
dependency overrides, race handling, test readability, rebuilds, and how easily
a new teammate can predict where a state change belongs.

## 11. Deliberate practice roadmap

Complete these in order:

1. Add `MovieSort.titleAZ` with a Bloc test.
2. Show a snack bar on repository failure using `BlocListener`.
3. Add a SQLite schema version 2 migration and test it through the repository.
4. Add cached search pages with an expiry timestamp and force-refresh event.
5. Replace request IDs with a `restartable` search transformer and test races.
6. Add `Equatable` or generated immutable states; explain equality behavior.
7. Add a global `BlocObserver` that records events, transitions, and errors.
8. Profile rebuilds and prove that each movie heart uses a narrow selector.
9. Add repository caching and a force-refresh event.
10. Compare the same feature change on `provider` and `riverpod` branches.

## 12. Specialist checklist

You can reasonably call yourself a Bloc specialist when you can:

- choose Bloc, Cubit, local widget state, or no state object—and defend why;
- design events as intent and states as immutable snapshots;
- explain `BlocProvider`, `RepositoryProvider`, builders, selectors, listeners,
  and consumers;
- place scopes according to ownership and lifecycle;
- model initial load, refresh, empty, error, retry, and preserved data;
- choose and test event concurrency behavior;
- prevent broad rebuilds and verify improvements with profiling;
- inject repositories and replace them in unit and widget tests;
- use `bloc_test` to express transition contracts;
- split Blocs by cohesive behavior rather than by screen or field count;
- keep navigation and visual effects at the UI boundary;
- explain when Bloc's structure reduces risk and when it only adds ceremony.

Specialism is not memorizing syntax. It is making state ownership, transition,
concurrency, lifecycle, rebuild, and testing decisions explicit and defensible.
