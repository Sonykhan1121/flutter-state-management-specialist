import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/movie.dart';
import '../../di/repository_providers.dart';

class FavoriteMoviesState {
  const FavoriteMoviesState({
    this.byId = const {},
    this.isLoading = false,
    this.pendingIds = const {},
    this.errorMessage,
  });

  final Map<String, Movie> byId;
  final bool isLoading;
  final Set<String> pendingIds;

  bool isBusy(String id) => isLoading || pendingIds.contains(id);
  final String? errorMessage;

  FavoriteMoviesState copyWith({
    Map<String, Movie>? byId,
    bool? isLoading,
    Set<String>? pendingIds,
    String? errorMessage,
    bool clearError = false,
  }) {
    return FavoriteMoviesState(
      byId: byId ?? this.byId,
      isLoading: isLoading ?? this.isLoading,
      pendingIds: pendingIds ?? this.pendingIds,
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
    if (!ref.mounted || state.isLoading || _pendingIds.isNotEmpty) return;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final movies =
          await ref.read(favoritesRepositoryProvider).loadFavorites();
      if (!ref.mounted) return;
      state = FavoriteMoviesState(
        byId: Map.unmodifiable({for (final movie in movies) movie.id: movie}),
      );
    } catch (error) {
      if (!ref.mounted) return;
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> toggle(Movie movie) async {
    if (!ref.mounted || state.isBusy(movie.id)) return;
    _pendingIds.add(movie.id);
    final wasFavorite = state.byId.containsKey(movie.id);
    final updated = Map<String, Movie>.of(state.byId);
    if (wasFavorite) {
      updated.remove(movie.id);
    } else {
      updated[movie.id] = movie;
    }
    state = state.copyWith(
      byId: Map.unmodifiable(updated),
      pendingIds: Set.unmodifiable(_pendingIds),
      clearError: true,
    );

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
      if (ref.mounted) {
        state = state.copyWith(pendingIds: Set.unmodifiable(_pendingIds));
      }
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
