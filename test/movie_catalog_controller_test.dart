import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/presentation/view_models/movie_catalog_view_model.dart';

import 'fakes.dart';

void main() {
  test('loads, filters, and sorts movies', () async {
    final repository = FakeMovieRepository(testMovies);
    final controller = MovieCatalogViewModel(repository);

    await controller.load();

    expect(controller.status, CatalogStatus.success);
    expect(controller.visibleMovies.first.id, 'two');
    expect(controller.availableGenres, ['Action', 'Drama']);

    controller.setGenre('Drama');
    expect(controller.visibleMovies.map((movie) => movie.id), ['one']);

    controller.setGenre(null);
    controller.setSort(MovieSort.yearOldest);
    expect(controller.visibleMovies.first.id, 'one');
  });

  test('exposes repository failures for the UI', () async {
    final controller = MovieCatalogViewModel(
      FakeMovieRepository(const [], error: Exception('offline')),
    );

    await controller.search('matrix');

    expect(controller.status, CatalogStatus.error);
    expect(controller.errorMessage, contains('offline'));
  });

  test('loads another page and appends unique movies', () async {
    final repository = FakeMovieRepository(
      testMovies,
      pages: {1: testMovies, 2: moreTestMovies},
    );
    final controller = MovieCatalogViewModel(repository);

    await controller.load();
    expect(controller.hasMore, isTrue);

    await controller.loadMore();

    expect(repository.requestedPages, [1, 2]);
    expect(controller.visibleMovies.length, 3);
    expect(controller.hasMore, isFalse);
  });
}
