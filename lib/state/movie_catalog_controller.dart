import 'package:flutter/foundation.dart';

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

class MovieCatalogController extends ChangeNotifier {
  MovieCatalogController(this._repository);

  final MovieRepository _repository;
  List<Movie> _movies = const [];
  CatalogStatus _status = CatalogStatus.initial;
  MovieSort _sort = MovieSort.ratingHighToLow;
  String? _genre;
  String _query = '';
  String? _errorMessage;
  int _requestId = 0;
  bool _disposed = false;

  CatalogStatus get status => _status;
  MovieSort get sort => _sort;
  String? get genre => _genre;
  String get query => _query;
  String? get errorMessage => _errorMessage;
  bool get isRefreshing =>
      _status == CatalogStatus.loading && _movies.isNotEmpty;

  List<String> get availableGenres {
    final genres =
        _movies.expand((movie) => movie.genres).toSet().toList()..sort();
    return List.unmodifiable(genres);
  }

  List<Movie> get visibleMovies {
    final filtered =
        _genre == null
            ? List<Movie>.of(_movies)
            : _movies.where((movie) => movie.genres.contains(_genre)).toList();
    filtered.sort(switch (_sort) {
      MovieSort.ratingHighToLow => (a, b) => b.rating.compareTo(a.rating),
      MovieSort.yearNewest => (a, b) => b.year.compareTo(a.year),
      MovieSort.yearOldest => (a, b) => a.year.compareTo(b.year),
    });
    return List.unmodifiable(filtered);
  }

  Future<void> load() => search('');

  Future<void> search(String query) async {
    final requestId = ++_requestId;
    _query = query.trim();
    _status = CatalogStatus.loading;
    _errorMessage = null;
    _notify();

    try {
      final movies = await _repository.searchMovies(_query);
      if (requestId != _requestId || _disposed) return;
      _movies = movies;
      final genres = availableGenres;
      if (_genre != null && !genres.contains(_genre)) _genre = null;
      _status = CatalogStatus.success;
    } catch (error) {
      if (requestId != _requestId || _disposed) return;
      _status = CatalogStatus.error;
      _errorMessage = error.toString();
    }
    _notify();
  }

  Future<void> retry() => search(_query);

  void setGenre(String? genre) {
    if (_genre == genre) return;
    _genre = genre;
    _notify();
  }

  void setSort(MovieSort sort) {
    if (_sort == sort) return;
    _sort = sort;
    _notify();
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
