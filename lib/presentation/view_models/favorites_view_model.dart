import 'package:flutter/foundation.dart';

import 'package:provider_project/domain/repositories/favorites_repository.dart';
import 'package:provider_project/domain/models/movie.dart';

class FavoritesViewModel extends ChangeNotifier {
  FavoritesViewModel(this._repository);

  final FavoritesRepository _repository;
  final Map<String, Movie> _byId = {};
  final Set<String> _pendingIds = {};
  bool _isLoading = false;
  bool _disposed = false;
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

  bool isBusy(String movieId) => _isLoading || _pendingIds.contains(movieId);

  Future<void> load() async {
    if (_disposed || _isLoading || _pendingIds.isNotEmpty) return;
    _isLoading = true;
    _errorMessage = null;
    _notify();
    try {
      final movies = await _repository.loadFavorites();
      if (_disposed) return;
      _byId
        ..clear()
        ..addEntries(movies.map((movie) => MapEntry(movie.id, movie)));
    } catch (error) {
      if (_disposed) return;
      _errorMessage = error.toString();
    } finally {
      _isLoading = false;
      _notify();
    }
  }

  Future<void> toggle(Movie movie) async {
    if (_disposed || isBusy(movie.id)) return;
    _pendingIds.add(movie.id);
    _errorMessage = null;
    final wasFavorite = _byId.containsKey(movie.id);
    if (wasFavorite) {
      _byId.remove(movie.id);
    } else {
      _byId[movie.id] = movie;
    }
    _notify();

    try {
      if (wasFavorite) {
        await _repository.removeFavorite(movie.id);
      } else {
        await _repository.saveFavorite(movie);
      }
    } catch (error) {
      if (_disposed) return;
      if (wasFavorite) {
        _byId[movie.id] = movie;
      } else {
        _byId.remove(movie.id);
      }
      _errorMessage = error.toString();
      _notify();
    } finally {
      _pendingIds.remove(movie.id);
      _notify();
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
