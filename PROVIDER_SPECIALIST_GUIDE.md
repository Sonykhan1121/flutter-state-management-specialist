# Provider Specialist Guide

Provider is a thin, Flutter-friendly way to expose values down the widget tree.
It does not dictate your architecture. `ChangeNotifier` is one possible mutable
state object; Provider supplies it, finds it, listens to it, and disposes it.

## 1. Build the correct mental model

There are three separate jobs in this project:

1. `MovieRepository` performs I/O and converts remote data into domain models.
2. `MovieCatalogController` and `FavoritesController` own mutable app state and
   business actions.
3. Widgets render state and forward user intent to controllers.

The flow is one-directional:

```text
user action -> controller method -> repository (when needed)
            -> controller updates fields -> notifyListeners()
            -> listening widgets rebuild
```

Provider is the delivery/listening mechanism. The controllers remain ordinary
Dart objects, which is why their behavior can be unit tested without rendering
widgets.

## 2. Know the Provider tools

### `Provider<T>`

Use it for a dependency that consumers need but do not listen to. This app
provides `MovieRepository` that way. Repositories and services should usually
not extend `ChangeNotifier` just to make them injectable.

### `ChangeNotifierProvider<T>`

Use it when Provider creates and owns a `ChangeNotifier`. The `create` callback
runs lazily by default, and Provider calls `dispose` when its scope disappears.
Never create a new notifier inside `build` with `.value`.

Use the `.value` constructor only when providing an instance that already
exists and whose lifecycle is managed elsewhere, such as an item in a reusable
list.

### `MultiProvider`

It removes deeply nested provider widgets. It improves readability, not state
behavior. Provider lookup still follows widget-tree ancestry.

### `context.read<T>()`

Gets `T` without subscribing the widget. Use it in event callbacks:

```dart
onPressed: () => context.read<FavoritesController>().toggle(movie)
```

Do not use `read` to render a value that must update on screen.

### `context.watch<T>()` and `Consumer<T>`

Both subscribe to changes. `watch` is compact; `Consumer` lets you place the
rebuilding boundary lower in the tree and optionally reuse an invariant
`child`. In this app, catalog sections use `Consumer` so changes do not rebuild
the entire route.

### `context.select<T, R>()` and `Selector<T, R>`

Subscribe only to a projection of an object. Each movie heart selects one
Boolean, while the app-bar badge selects only the favorite count. This prevents
every favorite-dependent widget from rebuilding for unrelated values.

The selected value should have stable equality. Prefer immutable records,
primitive values, or immutable value objects. Returning a freshly allocated
list that uses identity equality defeats the optimization.

### `ProxyProvider`

Use it when one provided value must be recomputed from other provided values.
For example, an authenticated API client may depend on the current session.
Do not reach sideways between unrelated notifiers when an explicit dependency
or coordinator would make the relationship clearer.

### `FutureProvider` and `StreamProvider`

They are useful for exposing one asynchronous value or stream. For a screen
with commands, filters, retries, stale-request handling, and preserved results,
a controller is often easier to understand than stacking multiple async
providers.

## 3. Why this state is split

`MovieCatalogController` changes during search, filter, and sort operations.
`FavoritesController` changes when a heart is tapped. Combining them would make
their lifecycles and rebuild causes harder to reason about.

Split state by cohesion and lifecycle, not by making one notifier for every
field. A good notifier has:

- one clear responsibility;
- private mutable fields and read-only public views;
- methods named after user/business actions;
- no `BuildContext` dependency;
- dependencies passed through its constructor;
- deterministic behavior that can be unit tested.

The text controller and debounce timer stay in `_HomeScreenState`. They are
short-lived presentation details that no other screen needs. Moving all local
UI state into Provider adds ceremony without adding value.

## 4. Async state done carefully

The catalog exposes an explicit status plus data and error fields. That lets the
UI distinguish first load, background refresh, empty results, and failure.

Rapid searches can finish out of order. `_requestId` ensures that an older HTTP
response cannot replace a newer query. The controller also avoids notifying
after disposal. These details separate demo-grade async code from reliable
state management.

For production, also consider cancellation, caching, offline behavior, request
timeouts, pagination, and structured error types.

## 5. Provider strengths

- Small API and close alignment with Flutter's `InheritedWidget` model.
- Easy to introduce gradually in an existing Flutter app.
- Explicit widget-tree scoping gives dependencies a visible lifetime.
- `ChangeNotifier` is simple and integrates with Flutter DevTools.
- `Consumer` and `Selector` offer precise rebuild control.
- Constructor injection keeps business logic testable.
- Mature ecosystem, documentation, and community knowledge.

## 6. Provider tradeoffs

- Dependencies are runtime lookups; a missing or incorrectly scoped provider
  fails at runtime rather than compile time.
- The nearest provider of a type wins, which can become confusing in large
  trees or when several instances share one type.
- `ChangeNotifier` is mutable and `notifyListeners()` is manual; forgetting it,
  calling it too often, or exposing mutable collections causes subtle bugs.
- One notifier notification is broad. Consumers must use `select`/`Selector`
  or split state to avoid excessive rebuilds.
- Async loading/error/data conventions are designed by your team rather than
  enforced by the package.
- Reading providers during lifecycle methods requires understanding when the
  widget is mounted and whether listening is allowed.
- Refactoring dependencies can require moving provider scope in the widget tree.

These are engineering tradeoffs, not reasons that Provider is bad. Provider is
excellent for small and medium apps when the team maintains clear boundaries.

## 7. Common mistakes and fixes

### Calling `watch` in an event callback

Use `read`; callbacks need an action target, not a subscription.

### Calling `read` for rendered state

Use `watch`, `Consumer`, or `Selector`; otherwise the UI becomes stale.

### Mutating a public list

Keep collections private and return `List.unmodifiable`, as both controllers do.

### Performing HTTP work in a widget

Put I/O behind a repository and trigger it through a controller action. Builds
can run many times and must stay free of side effects.

### One app-wide `ChangeNotifier`

Split by responsibility and lifecycle. Then select the smallest render value.

### Creating a notifier with `.value` inside `build`

Use `create:` so Provider owns disposal. Reserve `.value` for an existing
instance.

### Calling `notifyListeners()` for derived-only reads

Compute derived values such as sorted/filtered movies in a getter, or cache them
only when profiling proves it is needed. Notify only after source state changes.

### Storing `BuildContext` in a notifier

Pass plain dependencies and data instead. Navigation and visual feedback stay
at the UI boundary.

## 8. Testing strategy

- Unit-test controller transitions using a fake `MovieRepository`.
- Widget-test provider wiring and user-visible behavior.
- Override the dependency at the app composition root rather than adding test
  flags to production logic.
- Verify failure, empty, retry, out-of-order response, filtering, sorting, and
  favorite removal—not only the happy path.

## 9. Deliberate practice roadmap

Complete these in order:

1. Add a `MovieSort.titleAZ` option and its test.
2. Persist favorites behind a `FavoritesRepository` using shared preferences.
3. Add pagination while preserving the selected genre and sort.
4. Add an authenticated settings object and inject it with `ProxyProvider`.
5. Profile rebuilds in DevTools; replace one broad consumer with a selector and
   explain the measured difference.
6. Add repository caching with an expiry time and force-refresh action.
7. Write a widget test proving that a stale request cannot replace a new query.
8. Rebuild the same requirements on the `riverpod` branch and compare code,
   tests, lifecycle handling, overrides, and async state—not line counts alone.

## 10. Specialist checklist

You can reasonably call yourself a Provider specialist when you can:

- explain `read`, `watch`, `select`, `Consumer`, and `Selector` from memory;
- choose between local widget state and provided app state;
- place provider scope according to ownership and lifecycle;
- explain `create` versus `.value` and disposal behavior;
- design small, cohesive notifiers with immutable public state;
- prevent unnecessary rebuilds and verify them with profiling;
- handle loading, refresh, empty, error, retry, races, and disposal;
- inject repositories and replace them in tests;
- use `ProxyProvider`, `FutureProvider`, and `StreamProvider` only when their
  dependency/lifecycle model fits;
- identify when Provider remains sufficient and when a more structured state
  solution would reduce team risk.

The goal is not memorizing package syntax. It is being able to defend state
ownership, lifecycle, dependency, rebuild, and testing decisions in a real app.
