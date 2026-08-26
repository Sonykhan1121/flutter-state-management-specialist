import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/state/movie_providers.dart';

import 'fakes.dart';

void main() {
  test('toggle adds and removes a favorite', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(favoriteMoviesProvider.notifier);
    final movie = testMovies.first;

    notifier.toggle(movie);
    expect(container.read(isFavoriteProvider(movie.id)), isTrue);
    expect(container.read(favoriteMoviesProvider), hasLength(1));

    notifier.toggle(movie);
    expect(container.read(isFavoriteProvider(movie.id)), isFalse);
    expect(container.read(favoriteMovieListProvider), isEmpty);
  });
}
