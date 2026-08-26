import 'package:flutter/foundation.dart';

import '../models/movie.dart';

class FavoritesController extends ChangeNotifier {
  final Map<String, Movie> _byId = {};

  List<Movie> get movies {
    final result =
        _byId.values.toList()..sort((a, b) => a.title.compareTo(b.title));
    return List.unmodifiable(result);
  }

  int get count => _byId.length;

  bool isFavorite(String movieId) => _byId.containsKey(movieId);

  void toggle(Movie movie) {
    if (_byId.containsKey(movie.id)) {
      _byId.remove(movie.id);
    } else {
      _byId[movie.id] = movie;
    }
    notifyListeners();
  }
}
