import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/bloc/favorites_cubit.dart';

import 'fakes.dart';

void main() {
  blocTest<FavoritesCubit, FavoritesState>(
    'loads favorites persisted by the repository',
    build: () => FavoritesCubit(FakeFavoritesRepository([testMovies.last])),
    act: (cubit) => cubit.load(),
    expect:
        () => [
          isA<FavoritesState>().having(
            (state) => state.isLoading,
            'is loading',
            isTrue,
          ),
          isA<FavoritesState>()
              .having((state) => state.isLoading, 'is loading', isFalse)
              .having((state) => state.count, 'count', 1)
              .having(
                (state) => state.isFavorite(testMovies.last.id),
                'persisted favorite',
                isTrue,
              ),
        ],
  );

  blocTest<FavoritesCubit, FavoritesState>(
    'toggle adds and removes a favorite',
    build: () => FavoritesCubit(FakeFavoritesRepository()),
    act: (cubit) async {
      await cubit.toggle(testMovies.first);
      await cubit.toggle(testMovies.first);
    },
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
