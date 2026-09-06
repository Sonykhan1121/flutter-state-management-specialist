class Movie {
  const Movie({
    required this.id,
    required this.title,
    required this.year,
    required this.genres,
    required this.rating,
    required this.posterUrl,
    required this.plot,
    required this.director,
    required this.actors,
    required this.runtime,
    required this.rated,
  });

  final String id;
  final String title;
  final int year;
  final List<String> genres;
  final double rating;
  final String posterUrl;
  final String plot;
  final String director;
  final String actors;
  final String runtime;
  final String rated;
}
