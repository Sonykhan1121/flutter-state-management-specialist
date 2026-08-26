import 'package:flutter_bloc/flutter_bloc.dart';

import '../data/favorites_repository.dart';
import '../models/movie.dart';

class FavoritesState {
  const FavoritesState({
    this.byId = const {},
    this.isLoading = false,
    this.errorMessage,
  });

  final Map<String, Movie> byId;
  final bool isLoading;
  final String? errorMessage;

  List<Movie> get movies {
    final result =
        byId.values.toList()..sort((a, b) => a.title.compareTo(b.title));
    return List.unmodifiable(result);
  }

  int get count => byId.length;

  bool isFavorite(String movieId) => byId.containsKey(movieId);

  FavoritesState copyWith({
    Map<String, Movie>? byId,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FavoritesState(
      byId: byId ?? this.byId,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit(this._repository) : super(const FavoritesState());

  final FavoritesRepository _repository;
  final Set<String> _pendingIds = {};

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final movies = await _repository.loadFavorites();
      if (isClosed) return;
      emit(FavoritesState(byId: {for (final movie in movies) movie.id: movie}));
    } catch (error) {
      if (isClosed) return;
      emit(FavoritesState(errorMessage: error.toString()));
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
    emit(state.copyWith(byId: Map.unmodifiable(updated), clearError: true));

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(movie.id);
      } else {
        await _repository.saveFavorite(movie);
      }
    } catch (error) {
      if (isClosed) return;
      final rolledBack = Map<String, Movie>.of(state.byId);
      if (wasFavorite) {
        rolledBack[movie.id] = movie;
      } else {
        rolledBack.remove(movie.id);
      }
      emit(
        state.copyWith(
          byId: Map.unmodifiable(rolledBack),
          errorMessage: error.toString(),
        ),
      );
    } finally {
      _pendingIds.remove(movie.id);
    }
  }
}
