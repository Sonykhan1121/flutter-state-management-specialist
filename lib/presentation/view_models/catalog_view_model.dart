import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/movie.dart';
import '../../di/repository_providers.dart';

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
