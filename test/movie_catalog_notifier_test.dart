import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/state/movie_providers.dart';

import 'fakes.dart';

void main() {
  test('loads, filters, and sorts movies', () async {
    final repository = FakeMovieRepository(testMovies);
    final container = ProviderContainer(
      overrides: [movieRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    final notifier = container.read(movieCatalogProvider.notifier);

    await notifier.load();

    expect(container.read(movieCatalogProvider).status, CatalogStatus.success);
    expect(container.read(movieCatalogProvider).visibleMovies.first.id, 'two');
    expect(container.read(movieCatalogProvider).availableGenres, [
      'Action',
      'Drama',
    ]);

    notifier.setGenre('Drama');
    expect(
      container
          .read(movieCatalogProvider)
          .visibleMovies
          .map((movie) => movie.id),
      ['one'],
    );

    notifier.setGenre(null);
    notifier.setSort(MovieSort.yearOldest);
    expect(container.read(movieCatalogProvider).visibleMovies.first.id, 'one');
  });

  test('exposes repository failures for the UI', () async {
    final container = ProviderContainer(
      overrides: [
        movieRepositoryProvider.overrideWithValue(
          FakeMovieRepository(const [], error: Exception('offline')),
        ),
      ],
    );
    addTearDown(container.dispose);

    await container.read(movieCatalogProvider.notifier).search('matrix');
    final catalog = container.read(movieCatalogProvider);

    expect(catalog.status, CatalogStatus.error);
    expect(catalog.errorMessage, contains('offline'));
  });
}
