import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/state/movie_providers.dart';

import 'fakes.dart';

void main() {
  test('loads persisted favorites, then toggle adds and removes', () async {
    final repository = FakeFavoritesRepository([testMovies.last]);
    final container = ProviderContainer(
      overrides: [favoritesRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(favoriteMoviesProvider.notifier);
    final movie = testMovies.first;

    await notifier.load();
    expect(container.read(isFavoriteProvider(testMovies.last.id)), isTrue);

    await notifier.toggle(movie);
    expect(container.read(isFavoriteProvider(movie.id)), isTrue);
    expect(container.read(favoriteMoviesProvider).byId, hasLength(2));

    await notifier.toggle(movie);
    expect(container.read(isFavoriteProvider(movie.id)), isFalse);
    expect(container.read(favoriteMovieListProvider), [testMovies.last]);
  });
}
