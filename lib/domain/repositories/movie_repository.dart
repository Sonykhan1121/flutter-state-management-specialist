import '../models/movie.dart';

abstract interface class MovieRepository {
  Future<MoviePage> searchMovies(String query, {int page = 1});
}

class MoviePage {
  const MoviePage({
    required this.movies,
    required this.page,
    required this.totalResults,
    required this.hasMore,
  });

  final List<Movie> movies;
  final int page;
  final int totalResults;
  final bool hasMore;
}

class MovieRepositoryException implements Exception {
  const MovieRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
