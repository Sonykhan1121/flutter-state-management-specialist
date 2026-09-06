import '../models/movie.dart';

class Trailer {
  const Trailer({required this.videoId, required this.title});

  final String videoId;
  final String title;

  Uri get watchUri => Uri.https('www.youtube.com', '/watch', {'v': videoId});
}

abstract interface class TrailerRepository {
  bool get canSearchAutomatically;

  Future<Trailer?> findTrailer(Movie movie);

  Uri youtubeSearchUri(Movie movie);
}

class TrailerRepositoryException implements Exception {
  const TrailerRepositoryException(this.message);

  final String message;

  @override
  String toString() => message;
}
