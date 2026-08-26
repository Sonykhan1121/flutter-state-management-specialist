import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/bloc/favorites_cubit.dart';

import 'fakes.dart';

void main() {
  blocTest<FavoritesCubit, FavoritesState>(
    'toggle adds and removes a favorite',
    build: FavoritesCubit.new,
    act:
        (cubit) =>
            cubit
              ..toggle(testMovies.first)
              ..toggle(testMovies.first),
    expect:
        () => [
          isA<FavoritesState>()
              .having((state) => state.count, 'count', 1)
              .having(
                (state) => state.isFavorite(testMovies.first.id),
                'is favorite',
                isTrue,
              ),
          isA<FavoritesState>()
              .having((state) => state.count, 'count', 0)
              .having((state) => state.movies, 'movies', isEmpty),
        ],
  );
}
