import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/bloc/movie_catalog_bloc.dart';

import 'fakes.dart';

void main() {
  blocTest<MovieCatalogBloc, MovieCatalogState>(
    'emits loading and success when movies load',
    build: () => MovieCatalogBloc(FakeMovieRepository(testMovies)),
    act: (bloc) => bloc.add(const CatalogLoadRequested()),
    expect:
        () => [
          isA<MovieCatalogState>().having(
            (state) => state.status,
            'status',
            CatalogStatus.loading,
          ),
          isA<MovieCatalogState>()
              .having((state) => state.status, 'status', CatalogStatus.success)
              .having(
                (state) => state.visibleMovies.first.id,
                'top-rated movie',
                'two',
              )
              .having((state) => state.availableGenres, 'available genres', [
                'Action',
                'Drama',
              ]),
        ],
  );

  blocTest<MovieCatalogBloc, MovieCatalogState>(
    'filters by genre and sorts by oldest year',
    build: () => MovieCatalogBloc(FakeMovieRepository(testMovies)),
    seed:
        () => MovieCatalogState(
          movies: testMovies,
          status: CatalogStatus.success,
        ),
    act:
        (bloc) =>
            bloc
              ..add(const CatalogGenreChanged('Drama'))
              ..add(const CatalogGenreChanged(null))
              ..add(const CatalogSortChanged(MovieSort.yearOldest)),
    verify: (bloc) {
      expect(bloc.state.genre, isNull);
      expect(bloc.state.visibleMovies.first.id, 'one');
    },
  );

  blocTest<MovieCatalogBloc, MovieCatalogState>(
    'exposes repository failures for the UI',
    build:
        () => MovieCatalogBloc(
          FakeMovieRepository(const [], error: Exception('offline')),
        ),
    act: (bloc) => bloc.add(const CatalogSearchRequested('matrix')),
    expect:
        () => [
          isA<MovieCatalogState>().having(
            (state) => state.status,
            'status',
            CatalogStatus.loading,
          ),
          isA<MovieCatalogState>()
              .having((state) => state.status, 'status', CatalogStatus.error)
              .having(
                (state) => state.errorMessage,
                'error message',
                contains('offline'),
              ),
        ],
  );
}
