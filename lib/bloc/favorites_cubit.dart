import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/movie.dart';

class FavoritesState {
  const FavoritesState([this.byId = const {}]);

  final Map<String, Movie> byId;

  List<Movie> get movies {
    final result =
        byId.values.toList()..sort((a, b) => a.title.compareTo(b.title));
    return List.unmodifiable(result);
  }

  int get count => byId.length;

  bool isFavorite(String movieId) => byId.containsKey(movieId);
}

class FavoritesCubit extends Cubit<FavoritesState> {
  FavoritesCubit() : super(const FavoritesState());

  void toggle(Movie movie) {
    final updated = Map<String, Movie>.of(state.byId);
    if (updated.containsKey(movie.id)) {
      updated.remove(movie.id);
    } else {
      updated[movie.id] = movie;
    }
    emit(FavoritesState(Map.unmodifiable(updated)));
  }
}
