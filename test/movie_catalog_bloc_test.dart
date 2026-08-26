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

  blocTest<MovieCatalogBloc, MovieCatalogState>(
    'loads another page and appends unique movies',
    build:
        () => MovieCatalogBloc(
          FakeMovieRepository(
            testMovies,
            pages: {1: testMovies, 2: moreTestMovies},
          ),
        ),
    act: (bloc) async {
      bloc.add(const CatalogLoadRequested());
      await bloc.stream.firstWhere(
        (state) => state.status == CatalogStatus.success,
      );
      bloc.add(const CatalogLoadMoreRequested());
    },
    expect:
        () => [
          isA<MovieCatalogState>().having(
            (state) => state.status,
            'status',
            CatalogStatus.loading,
          ),
          isA<MovieCatalogState>()
              .having((state) => state.page, 'page', 1)
              .having((state) => state.hasMore, 'has more', isTrue),
          isA<MovieCatalogState>().having(
            (state) => state.isLoadingMore,
            'is loading more',
            isTrue,
          ),
          isA<MovieCatalogState>()
              .having((state) => state.page, 'page', 2)
              .having((state) => state.visibleMovies.length, 'movie count', 3)
              .having((state) => state.hasMore, 'has more', isFalse),
        ],
  );
}
