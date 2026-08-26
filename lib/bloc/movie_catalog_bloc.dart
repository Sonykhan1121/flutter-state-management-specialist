import 'package:flutter_bloc/flutter_bloc.dart';

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

sealed class MovieCatalogEvent {
  const MovieCatalogEvent();
}

final class CatalogLoadRequested extends MovieCatalogEvent {
  const CatalogLoadRequested();
}

final class CatalogSearchRequested extends MovieCatalogEvent {
  const CatalogSearchRequested(this.query);

  final String query;
}

final class CatalogRetryRequested extends MovieCatalogEvent {
  const CatalogRetryRequested();
}

final class CatalogLoadMoreRequested extends MovieCatalogEvent {
  const CatalogLoadMoreRequested();
}

final class CatalogGenreChanged extends MovieCatalogEvent {
  const CatalogGenreChanged(this.genre);

  final String? genre;
}

final class CatalogSortChanged extends MovieCatalogEvent {
  const CatalogSortChanged(this.sort);

  final MovieSort sort;
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
    final genres =
        movies.expand((movie) => movie.genres).toSet().toList()..sort();
    return List.unmodifiable(genres);
  }

  List<Movie> get visibleMovies {
    final filtered =
        genre == null
            ? List<Movie>.of(movies)
            : movies.where((movie) => movie.genres.contains(genre)).toList();
    filtered.sort(switch (sort) {
      MovieSort.ratingHighToLow => (a, b) => b.rating.compareTo(a.rating),
      MovieSort.yearNewest => (a, b) => b.year.compareTo(a.year),
      MovieSort.yearOldest => (a, b) => a.year.compareTo(b.year),
    });
    return List.unmodifiable(filtered);
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

class MovieCatalogBloc extends Bloc<MovieCatalogEvent, MovieCatalogState> {
  MovieCatalogBloc(this._repository) : super(const MovieCatalogState()) {
    on<CatalogLoadRequested>((_, emit) => _fetch('', emit));
    on<CatalogSearchRequested>((event, emit) => _fetch(event.query, emit));
    on<CatalogRetryRequested>((_, emit) => _fetch(state.query, emit));
    on<CatalogLoadMoreRequested>(_onLoadMore);
    on<CatalogGenreChanged>(_onGenreChanged);
    on<CatalogSortChanged>(_onSortChanged);
  }

  final MovieRepository _repository;
  int _requestId = 0;

  Future<void> _fetch(String query, Emitter<MovieCatalogState> emit) async {
    final requestId = ++_requestId;
    final normalizedQuery = query.trim();
    emit(
      state.copyWith(
        status: CatalogStatus.loading,
        query: normalizedQuery,
        clearError: true,
        clearLoadMoreError: true,
        isLoadingMore: false,
      ),
    );

    try {
      final result = await _repository.searchMovies(normalizedQuery);
      if (requestId != _requestId || emit.isDone) return;
      final genres = result.movies.expand((movie) => movie.genres).toSet();
      final selectedGenre = state.genre;
      emit(
        state.copyWith(
          movies: List.unmodifiable(result.movies),
          status: CatalogStatus.success,
          clearGenre: selectedGenre != null && !genres.contains(selectedGenre),
          clearError: true,
          page: result.page,
          totalResults: result.totalResults,
          hasMore: result.hasMore,
        ),
      );
    } catch (error) {
      if (requestId != _requestId || emit.isDone) return;
      emit(
        state.copyWith(
          status: CatalogStatus.error,
          errorMessage: error.toString(),
        ),
      );
    }
  }

  Future<void> _onLoadMore(
    CatalogLoadMoreRequested event,
    Emitter<MovieCatalogState> emit,
  ) async {
    if (state.isLoadingMore ||
        !state.hasMore ||
        state.status == CatalogStatus.loading) {
      return;
    }
    final requestId = _requestId;
    final query = state.query;
    final nextPage = state.page + 1;
    emit(state.copyWith(isLoadingMore: true, clearLoadMoreError: true));

    try {
      final result = await _repository.searchMovies(query, page: nextPage);
      if (requestId != _requestId || emit.isDone) return;
      final byId = {for (final movie in state.movies) movie.id: movie};
      for (final movie in result.movies) {
        byId[movie.id] = movie;
      }
      emit(
        state.copyWith(
          movies: List.unmodifiable(byId.values),
          page: result.page,
          totalResults: result.totalResults,
          hasMore: result.hasMore,
          isLoadingMore: false,
        ),
      );
    } catch (error) {
      if (requestId != _requestId || emit.isDone) return;
      emit(
        state.copyWith(loadMoreError: error.toString(), isLoadingMore: false),
      );
    }
  }

  void _onGenreChanged(
    CatalogGenreChanged event,
    Emitter<MovieCatalogState> emit,
  ) {
    if (state.genre == event.genre) return;
    emit(state.copyWith(genre: event.genre, clearGenre: event.genre == null));
  }

  void _onSortChanged(
    CatalogSortChanged event,
    Emitter<MovieCatalogState> emit,
  ) {
    if (state.sort == event.sort) return;
    emit(state.copyWith(sort: event.sort));
  }
}
