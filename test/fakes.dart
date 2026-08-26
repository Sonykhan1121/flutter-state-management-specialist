import 'package:provider_project/data/movie_repository.dart';
import 'package:provider_project/models/movie.dart';

class FakeMovieRepository implements MovieRepository {
  FakeMovieRepository(this.movies, {this.error});

  final List<Movie> movies;
  final Object? error;
  final List<String> queries = [];

  @override
  Future<List<Movie>> searchMovies(String query) async {
    queries.add(query);
    if (error != null) throw error!;
    return movies;
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
