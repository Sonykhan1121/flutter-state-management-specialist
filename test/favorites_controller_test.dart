import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/state/favorites_controller.dart';

import 'fakes.dart';

void main() {
  test('loads persisted favorites, then toggle adds and removes', () async {
    final repository = FakeFavoritesRepository([testMovies.last]);
    final favorites = FavoritesController(repository);
    final movie = testMovies.first;

    await favorites.load();
    expect(favorites.isFavorite(testMovies.last.id), isTrue);

    await favorites.toggle(movie);
    expect(favorites.isFavorite(movie.id), isTrue);
    expect(favorites.count, 2);

    await favorites.toggle(movie);
    expect(favorites.isFavorite(movie.id), isFalse);
    expect(favorites.count, 1);
  });
}
