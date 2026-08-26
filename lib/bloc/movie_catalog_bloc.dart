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
  });

  final List<Movie> movies;
  final CatalogStatus status;
  final MovieSort sort;
  final String? genre;
  final String query;
  final String? errorMessage;

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
  }) {
    return MovieCatalogState(
      movies: movies ?? this.movies,
      status: status ?? this.status,
      sort: sort ?? this.sort,
      genre: clearGenre ? null : genre ?? this.genre,
      query: query ?? this.query,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class MovieCatalogBloc extends Bloc<MovieCatalogEvent, MovieCatalogState> {
  MovieCatalogBloc(this._repository) : super(const MovieCatalogState()) {
    on<CatalogLoadRequested>((_, emit) => _fetch('', emit));
    on<CatalogSearchRequested>((event, emit) => _fetch(event.query, emit));
    on<CatalogRetryRequested>((_, emit) => _fetch(state.query, emit));
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
      ),
    );

    try {
      final movies = await _repository.searchMovies(normalizedQuery);
      if (requestId != _requestId || emit.isDone) return;
      final genres = movies.expand((movie) => movie.genres).toSet();
      final selectedGenre = state.genre;
      emit(
        state.copyWith(
          movies: List.unmodifiable(movies),
          status: CatalogStatus.success,
          clearGenre: selectedGenre != null && !genres.contains(selectedGenre),
          clearError: true,
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
