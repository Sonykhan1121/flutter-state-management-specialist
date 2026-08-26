import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/favorites_repository.dart';
import '../data/movie_repository.dart';
import '../data/trailer_repository.dart';
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
    this.loadMoreError,
    this.page = 0,
    this.totalResults = 0,
    this.hasMore = false,
    this.isLoadingMore = false,
  });

  final List<Movie> movies;
  final CatalogStatus status;
  final MovieSort sort;
  final String? genre;
  final String query;
  final String? errorMessage;
  final String? loadMoreError;
  final int page;
  final int totalResults;
  final bool hasMore;
  final bool isLoadingMore;

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

  MovieCatalogState copyWith({
    List<Movie>? movies,
    CatalogStatus? status,
    MovieSort? sort,
    String? genre,
    bool clearGenre = false,
    String? query,
    String? errorMessage,
    bool clearError = false,
    String? loadMoreError,
    bool clearLoadMoreError = false,
    int? page,
    int? totalResults,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    return MovieCatalogState(
      movies: movies ?? this.movies,
      status: status ?? this.status,
      sort: sort ?? this.sort,
      genre: clearGenre ? null : genre ?? this.genre,
      query: query ?? this.query,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      loadMoreError:
          clearLoadMoreError ? null : loadMoreError ?? this.loadMoreError,
      page: page ?? this.page,
      totalResults: totalResults ?? this.totalResults,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => createMovieRepository(),
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => createFavoritesRepository(),
);

final trailerRepositoryProvider = Provider<TrailerRepository>(
  (ref) => createTrailerRepository(),
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
    state = state.copyWith(
      status: CatalogStatus.loading,
      query: normalizedQuery,
      clearError: true,
      clearLoadMoreError: true,
      isLoadingMore: false,
    );

    try {
      final result = await ref
          .read(movieRepositoryProvider)
          .searchMovies(normalizedQuery);
      if (requestId != _requestId || _disposed) return;
      final genres = result.movies.expand((movie) => movie.genres).toSet();
      final selectedGenre = state.genre;
      state = state.copyWith(
        movies: List.unmodifiable(result.movies),
        status: CatalogStatus.success,
        clearGenre: selectedGenre != null && !genres.contains(selectedGenre),
        query: normalizedQuery,
        clearError: true,
        page: result.page,
        totalResults: result.totalResults,
        hasMore: result.hasMore,
      );
    } catch (error) {
      if (requestId != _requestId || _disposed) return;
      state = state.copyWith(
        status: CatalogStatus.error,
        errorMessage: error.toString(),
      );
    }
  }

  Future<void> retry() => search(state.query);

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status == CatalogStatus.loading) {
      return;
    }
    final requestId = _requestId;
    final query = state.query;
    final nextPage = state.page + 1;
    state = state.copyWith(isLoadingMore: true, clearLoadMoreError: true);

    try {
      final result = await ref
          .read(movieRepositoryProvider)
          .searchMovies(query, page: nextPage);
      if (requestId != _requestId || _disposed) return;
      final byId = {for (final movie in state.movies) movie.id: movie};
      for (final movie in result.movies) {
        byId[movie.id] = movie;
      }
      state = state.copyWith(
        movies: List.unmodifiable(byId.values),
        page: result.page,
        totalResults: result.totalResults,
        hasMore: result.hasMore,
        isLoadingMore: false,
      );
    } catch (error) {
      if (requestId != _requestId || _disposed) return;
      state = state.copyWith(
        loadMoreError: error.toString(),
        isLoadingMore: false,
      );
    }
  }

  void setGenre(String? genre) {
    if (state.genre == genre) return;
    state = state.copyWith(genre: genre, clearGenre: genre == null);
  }

  void setSort(MovieSort sort) {
    if (state.sort == sort) return;
    state = state.copyWith(sort: sort);
  }
}

class FavoriteMoviesState {
  const FavoriteMoviesState({
    this.byId = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final Map<String, Movie> byId;
  final bool isLoading;
  final String? errorMessage;

  FavoriteMoviesState copyWith({
    Map<String, Movie>? byId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FavoriteMoviesState(
      byId: byId ?? this.byId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final favoriteMoviesProvider =
    NotifierProvider<FavoriteMoviesNotifier, FavoriteMoviesState>(
      FavoriteMoviesNotifier.new,
    );

class FavoriteMoviesNotifier extends Notifier<FavoriteMoviesState> {
  final Set<String> _pendingIds = {};

  @override
  FavoriteMoviesState build() => const FavoriteMoviesState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final movies =
          await ref.read(favoritesRepositoryProvider).loadFavorites();
      if (!ref.mounted) return;
      state = FavoriteMoviesState(
        byId: {for (final movie in movies) movie.id: movie},
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = FavoriteMoviesState(errorMessage: error.toString());
    }
  }

  Future<void> toggle(Movie movie) async {
    if (_pendingIds.contains(movie.id)) return;
    _pendingIds.add(movie.id);
    final wasFavorite = state.byId.containsKey(movie.id);
    final updated = Map<String, Movie>.of(state.byId);
    if (wasFavorite) {
      updated.remove(movie.id);
    } else {
      updated[movie.id] = movie;
    }
    state = state.copyWith(byId: Map.unmodifiable(updated), clearError: true);

    try {
      if (wasFavorite) {
        await ref.read(favoritesRepositoryProvider).removeFavorite(movie.id);
      } else {
        await ref.read(favoritesRepositoryProvider).saveFavorite(movie);
      }
    } catch (error) {
      if (!ref.mounted) return;
      final rolledBack = Map<String, Movie>.of(state.byId);
      if (wasFavorite) {
        rolledBack[movie.id] = movie;
      } else {
        rolledBack.remove(movie.id);
      }
      state = state.copyWith(
        byId: Map.unmodifiable(rolledBack),
        errorMessage: error.toString(),
      );
    } finally {
      _pendingIds.remove(movie.id);
    }
  }
}

final favoriteMovieListProvider = Provider<List<Movie>>((ref) {
  final result =
      ref.watch(favoriteMoviesProvider).byId.values.toList()
        ..sort((a, b) => a.title.compareTo(b.title));
  return List.unmodifiable(result);
});

final isFavoriteProvider = Provider.family<bool, String>(
  (ref, movieId) => ref.watch(
    favoriteMoviesProvider.select((state) => state.byId.containsKey(movieId)),
  ),
);
