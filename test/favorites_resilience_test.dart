import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:provider_project/presentation/view_models/movie_providers.dart';
import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/domain/models/movie.dart';
import 'fakes.dart';

class ControlledFavoritesRepository extends FakeFavoritesRepository {
  ControlledFavoritesRepository([super.initialMovies]);
  Completer<List<Movie>>? loadGate;
  Completer<void>? writeGate;
  Exception? writeError;
  int loadCalls = 0;
  int writeCalls = 0;
  @override
  Future<List<Movie>> loadFavorites() {
    loadCalls++;
    return loadGate?.future ?? super.loadFavorites();
  }

  Future<void> _write() async {
    writeCalls++;
    if (writeGate != null) await writeGate!.future;
    if (writeError != null) throw writeError!;
  }

  @override
  Future<void> saveFavorite(Movie movie) async {
    await _write();
    await super.saveFavorite(movie);
  }

  @override
  Future<void> removeFavorite(String id) async {
    await _write();
    await super.removeFavorite(id);
  }
}

class Harness {
  Harness({
    required this.load,
    required this.toggle,
    required this.isFavorite,
    required this.isBusy,
    required this.error,
    required Future<void> Function() dispose,
  }) : _dispose = dispose;
  final Future<void> Function() load;
  final Future<void> Function(Movie) toggle;
  final bool Function(String) isFavorite;
  final bool Function(String) isBusy;
  final String? Function() error;
  final Future<void> Function() _dispose;
  bool _disposed = false;
  Future<void> dispose() async {
    if (!_disposed) {
      _disposed = true;
      await _dispose();
    }
  }
}

void main() {
  test(
    'failed insert rolls back optimistic state and exposes the failure',
    () async {
      final repo =
          ControlledFavoritesRepository()..writeError = Exception('Disk full');
      final vm = createHarness(repo);
      addTearDown(vm.dispose);
      await vm.load();
      await vm.toggle(testMovies.first);
      expect(vm.isFavorite(testMovies.first.id), isFalse);
      expect(vm.isBusy(testMovies.first.id), isFalse);
      expect(vm.error(), contains('Disk full'));
    },
  );
  test('failed remove restores the existing favorite', () async {
    final repo = ControlledFavoritesRepository([testMovies.first])
      ..writeError = Exception('Read only');
    final vm = createHarness(repo);
    addTearDown(vm.dispose);
    await vm.load();
    await vm.toggle(testMovies.first);
    expect(vm.isFavorite(testMovies.first.id), isTrue);
  });
  test(
    'rapid taps and refresh during a write cannot clobber optimistic state',
    () async {
      final repo =
          ControlledFavoritesRepository()..writeGate = Completer<void>();
      final vm = createHarness(repo);
      addTearDown(vm.dispose);
      await vm.load();
      final pending = vm.toggle(testMovies.first);
      expect(vm.isBusy(testMovies.first.id), isTrue);
      await vm.toggle(testMovies.first);
      await vm.load();
      expect(repo.writeCalls, 1);
      expect(repo.loadCalls, 1);
      repo.writeGate!.complete();
      await pending;
      expect(vm.isFavorite(testMovies.first.id), isTrue);
      expect(vm.isBusy(testMovies.first.id), isFalse);
    },
  );
  test(
    'initial hydration prevents a write from racing the saved snapshot',
    () async {
      final repo =
          ControlledFavoritesRepository()..loadGate = Completer<List<Movie>>();
      final vm = createHarness(repo);
      addTearDown(vm.dispose);
      final loading = vm.load();
      expect(vm.isBusy(testMovies.first.id), isTrue);
      await vm.toggle(testMovies.first);
      expect(repo.writeCalls, 0);
      repo.loadGate!.complete([testMovies.last]);
      await loading;
      expect(vm.isFavorite(testMovies.last.id), isTrue);
    },
  );
  test(
    'closing the ViewModel during a read does not emit late state',
    () async {
      final repo =
          ControlledFavoritesRepository()..loadGate = Completer<List<Movie>>();
      final vm = createHarness(repo);
      addTearDown(vm.dispose);
      final loading = vm.load();
      await vm.dispose();
      repo.loadGate!.complete(testMovies);
      await expectLater(loading, completes);
    },
  );
}

Harness createHarness(ControlledFavoritesRepository repo) {
  final container = ProviderContainer(
    overrides: [favoritesRepositoryProvider.overrideWithValue(repo)],
  );
  final vm = container.read(favoriteMoviesProvider.notifier);
  return Harness(
    load: vm.load,
    toggle: vm.toggle,
    isFavorite:
        (id) => container.read(favoriteMoviesProvider).byId.containsKey(id),
    isBusy: (id) => container.read(favoriteMoviesProvider).isBusy(id),
    error: () => container.read(favoriteMoviesProvider).errorMessage,
    dispose: () async => container.dispose(),
  );
}
