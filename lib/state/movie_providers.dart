import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/movie_repository.dart';
import '../models/movie.dart';

enum CatalogStatus { initial, loading, success, error }

enum MovieSort { ratingHighToLow, yearNewest, yearOldest }

extension MovieSortLabel on MovieSort {
  String get label => switch (this) {
    MovieSort.ratingHighToLow => 'Top rated',
    MovieSort.yearNewest => 'Newest',
    MovieSort.yearOldest => 'Oldest',
  };
}

class MovieCatalogState {
  const MovieCatalogState({
    this.movies = const [],
    this.status = CatalogStatus.initial,
    this.sort = MovieSort.ratingHighToLow,
    this.genre,
    this.query = '',
    this.errorMessage,
  });

  final List<Movie> movies;
  final CatalogStatus status;
  final MovieSort sort;
  final String? genre;
  final String query;
  final String? errorMessage;

  bool get isRefreshing => status == CatalogStatus.loading && movies.isNotEmpty;

  List<String> get availableGenres {
    final result =
        movies.expand((movie) => movie.genres).toSet().toList()..sort();
    return List.unmodifiable(result);
  }

  List<Movie> get visibleMovies {
    final result =
        genre == null
            ? List<Movie>.of(movies)
            : movies.where((movie) => movie.genres.contains(genre)).toList();
    result.sort(switch (sort) {
      MovieSort.ratingHighToLow => (a, b) => b.rating.compareTo(a.rating),
      MovieSort.yearNewest => (a, b) => b.year.compareTo(a.year),
      MovieSort.yearOldest => (a, b) => a.year.compareTo(b.year),
    });
    return List.unmodifiable(result);
  }
}

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => createMovieRepository(),
);

final movieCatalogProvider =
    NotifierProvider<MovieCatalogNotifier, MovieCatalogState>(
      MovieCatalogNotifier.new,
    );

class MovieCatalogNotifier extends Notifier<MovieCatalogState> {
  int _requestId = 0;
  bool _disposed = false;

  @override
  MovieCatalogState build() {
    ref.onDispose(() => _disposed = true);
    return const MovieCatalogState();
  }

  Future<void> load() => search('');

  Future<void> search(String query) async {
    final requestId = ++_requestId;
    final normalizedQuery = query.trim();
    state = MovieCatalogState(
      movies: state.movies,
      status: CatalogStatus.loading,
      sort: state.sort,
      genre: state.genre,
      query: normalizedQuery,
    );

    try {
      final movies = await ref
          .read(movieRepositoryProvider)
          .searchMovies(normalizedQuery);
      if (requestId != _requestId || _disposed) return;
      final genres = movies.expand((movie) => movie.genres).toSet();
      state = MovieCatalogState(
        movies: List.unmodifiable(movies),
        status: CatalogStatus.success,
        sort: state.sort,
        genre: genres.contains(state.genre) ? state.genre : null,
        query: normalizedQuery,
      );
    } catch (error) {
      if (requestId != _requestId || _disposed) return;
      state = MovieCatalogState(
        movies: state.movies,
        status: CatalogStatus.error,
        sort: state.sort,
        genre: state.genre,
        query: normalizedQuery,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> retry() => search(state.query);

  void setGenre(String? genre) {
    if (state.genre == genre) return;
    state = MovieCatalogState(
      movies: state.movies,
      status: state.status,
      sort: state.sort,
      genre: genre,
      query: state.query,
      errorMessage: state.errorMessage,
    );
  }

  void setSort(MovieSort sort) {
    if (state.sort == sort) return;
    state = MovieCatalogState(
      movies: state.movies,
      status: state.status,
      sort: sort,
      genre: state.genre,
      query: state.query,
      errorMessage: state.errorMessage,
    );
  }
}

final favoriteMoviesProvider =
    NotifierProvider<FavoriteMoviesNotifier, Map<String, Movie>>(
      FavoriteMoviesNotifier.new,
    );

class FavoriteMoviesNotifier extends Notifier<Map<String, Movie>> {
  @override
  Map<String, Movie> build() => const {};

  void toggle(Movie movie) {
    if (state.containsKey(movie.id)) {
      state = {
        for (final entry in state.entries)
          if (entry.key != movie.id) entry.key: entry.value,
      };
    } else {
      state = {...state, movie.id: movie};
    }
  }
}

final favoriteMovieListProvider = Provider<List<Movie>>((ref) {
  final result =
      ref.watch(favoriteMoviesProvider).values.toList()
        ..sort((a, b) => a.title.compareTo(b.title));
  return List.unmodifiable(result);
});

final isFavoriteProvider = Provider.family<bool, String>(
  (ref, movieId) => ref.watch(
    favoriteMoviesProvider.select((movies) => movies.containsKey(movieId)),
  ),
);
