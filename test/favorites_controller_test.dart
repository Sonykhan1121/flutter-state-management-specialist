import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/state/favorites_controller.dart';

import 'fakes.dart';

void main() {
  test('toggle adds and removes a favorite', () {
    final favorites = FavoritesController();
    final movie = testMovies.first;

    favorites.toggle(movie);
    expect(favorites.isFavorite(movie.id), isTrue);
    expect(favorites.count, 1);

    favorites.toggle(movie);
    expect(favorites.isFavorite(movie.id), isFalse);
    expect(favorites.movies, isEmpty);
  });
}
