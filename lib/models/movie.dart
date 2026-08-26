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

  factory Movie.fromOmdb(Map<String, dynamic> json) {
    final yearMatch = RegExp(r'\d{4}').firstMatch('${json['Year'] ?? ''}');
    final poster = '${json['Poster'] ?? ''}';

    return Movie(
      id: '${json['imdbID'] ?? ''}',
      title: '${json['Title'] ?? 'Untitled'}',
      year: int.tryParse(yearMatch?.group(0) ?? '') ?? 0,
      genres: _split('${json['Genre'] ?? ''}'),
      rating: double.tryParse('${json['imdbRating'] ?? ''}') ?? 0,
      posterUrl: poster == 'N/A' ? '' : poster,
      plot: _valueOrFallback(json['Plot'], 'Plot unavailable.'),
      director: _valueOrFallback(json['Director'], 'Unknown'),
      actors: _valueOrFallback(json['Actors'], 'Unknown'),
      runtime: _valueOrFallback(json['Runtime'], 'Unknown'),
      rated: _valueOrFallback(json['Rated'], 'Not rated'),
    );
  }

  static List<String> _split(String value) =>
      value == 'N/A' || value.isEmpty
          ? const []
          : value.split(',').map((part) => part.trim()).toList(growable: false);

  static String _valueOrFallback(Object? value, String fallback) {
    final text = '${value ?? ''}'.trim();
    return text.isEmpty || text == 'N/A' ? fallback : text;
  }
}
