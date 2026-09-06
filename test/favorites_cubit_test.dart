import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/presentation/view_models/favorites_cubit.dart';

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
    'toggle exposes pending and committed state for add and remove',
    build: () => FavoritesCubit(FakeFavoritesRepository()),
    act: (cubit) async {
      await cubit.toggle(testMovies.first);
      await cubit.toggle(testMovies.first);
    },
    expect:
        () => [
          isA<FavoritesState>()
              .having((s) => s.count, 'count', 1)
              .having((s) => s.isBusy(testMovies.first.id), 'saving', true),
          isA<FavoritesState>()
              .having((s) => s.count, 'count', 1)
              .having((s) => s.isBusy(testMovies.first.id), 'saved', false),
          isA<FavoritesState>()
              .having((s) => s.count, 'count', 0)
              .having((s) => s.isBusy(testMovies.first.id), 'removing', true),
          isA<FavoritesState>()
              .having((s) => s.count, 'count', 0)
              .having((s) => s.isBusy(testMovies.first.id), 'removed', false),
        ],
  );
}
