import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/state/movie_catalog_controller.dart';

import 'fakes.dart';

void main() {
  test('loads, filters, and sorts movies', () async {
    final repository = FakeMovieRepository(testMovies);
    final controller = MovieCatalogController(repository);

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
    final controller = MovieCatalogController(
      FakeMovieRepository(const [], error: Exception('offline')),
    );

    await controller.search('matrix');

    expect(controller.status, CatalogStatus.error);
    expect(controller.errorMessage, contains('offline'));
  });
}
