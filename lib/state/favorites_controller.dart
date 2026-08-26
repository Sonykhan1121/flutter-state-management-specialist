import 'package:flutter/foundation.dart';

import '../data/favorites_repository.dart';
import '../models/movie.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController(this._repository);

  final FavoritesRepository _repository;
  final Map<String, Movie> _byId = {};
  final Set<String> _pendingIds = {};
  bool _isLoading = false;
  String? _errorMessage;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<Movie> get movies {
    final result =
        _byId.values.toList()..sort((a, b) => a.title.compareTo(b.title));
    return List.unmodifiable(result);
  }

  int get count => _byId.length;

  bool isFavorite(String movieId) => _byId.containsKey(movieId);

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final movies = await _repository.loadFavorites();
      _byId
        ..clear()
        ..addEntries(movies.map((movie) => MapEntry(movie.id, movie)));
    } catch (error) {
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggle(Movie movie) async {
    if (_pendingIds.contains(movie.id)) return;
    _pendingIds.add(movie.id);
    _errorMessage = null;
    final wasFavorite = _byId.containsKey(movie.id);
    if (wasFavorite) {
      _byId.remove(movie.id);
    } else {
      _byId[movie.id] = movie;
    }
    notifyListeners();

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(movie.id);
      } else {
        await _repository.saveFavorite(movie);
      }
    } catch (error) {
      if (wasFavorite) {
        _byId[movie.id] = movie;
      } else {
        _byId.remove(movie.id);
      }
      _errorMessage = error.toString();
      notifyListeners();
    } finally {
      _pendingIds.remove(movie.id);
    }
  }
}
