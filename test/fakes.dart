import 'package:provider_project/data/favorites_repository.dart';
import 'package:provider_project/data/movie_repository.dart';
import 'package:provider_project/models/movie.dart';

class FakeMovieRepository implements MovieRepository {
  FakeMovieRepository(
    List<Movie> movies, {
    this.error,
    Map<int, List<Movie>>? pages,
  }) : pages = pages ?? {1: movies};

  final Map<int, List<Movie>> pages;
  final Object? error;
  final List<String> queries = [];
  final List<int> requestedPages = [];

  @override
  Future<MoviePage> searchMovies(String query, {int page = 1}) async {
    queries.add(query);
    requestedPages.add(page);
    if (error != null) throw error!;
    final movies = pages[page] ?? const [];
    final totalResults = pages.values.fold<int>(
      0,
      (total, pageMovies) => total + pageMovies.length,
    );
    return MoviePage(
      movies: movies,
      page: page,
      totalResults: totalResults,
      hasMore: pages.keys.any((availablePage) => availablePage > page),
    );
  }
}

class FakeFavoritesRepository implements FavoritesRepository {
  FakeFavoritesRepository([Iterable<Movie> initialMovies = const []])
    : _byId = {for (final movie in initialMovies) movie.id: movie};

  final Map<String, Movie> _byId;

  @override
  Future<List<Movie>> loadFavorites() async => _byId.values.toList();

  @override
  Future<void> removeFavorite(String movieId) async {
    _byId.remove(movieId);
  }

  @override
  Future<void> saveFavorite(Movie movie) async {
    _byId[movie.id] = movie;
  }
}

const testMovies = <Movie>[
  Movie(
    id: 'one',
    title: 'Older Drama',
    year: 1990,
    genres: ['Drama'],
    rating: 7.2,
    posterUrl: '',
    plot: 'Plot one',
    director: 'Director one',
    actors: 'Actor one',
    runtime: '100 min',
    rated: 'PG',
  ),
  Movie(
    id: 'two',
    title: 'New Action',
    year: 2024,
    genres: ['Action'],
    rating: 8.8,
    posterUrl: '',
    plot: 'Plot two',
    director: 'Director two',
    actors: 'Actor two',
    runtime: '120 min',
    rated: 'PG-13',
  ),
];

const moreTestMovies = <Movie>[
  Movie(
    id: 'three',
    title: 'More Comedy',
    year: 2020,
    genres: ['Comedy'],
    rating: 6.9,
    posterUrl: '',
    plot: 'Plot three',
    director: 'Director three',
    actors: 'Actor three',
    runtime: '95 min',
    rated: 'PG',
  ),
];
