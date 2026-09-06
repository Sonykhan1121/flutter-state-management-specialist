import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_dependencies.dart';
import '../domain/repositories/favorites_repository.dart';
import '../domain/repositories/movie_repository.dart';
import '../domain/repositories/trailer_repository.dart';

final appDependenciesProvider = Provider<AppDependencies>((ref) {
  final dependencies = AppDependencies();
  ref.onDispose(dependencies.dispose);
  return dependencies;
});

final movieRepositoryProvider = Provider<MovieRepository>(
  (ref) => ref.watch(appDependenciesProvider).movies,
);

final favoritesRepositoryProvider = Provider<FavoritesRepository>(
  (ref) => ref.watch(appDependenciesProvider).favorites,
);

final trailerRepositoryProvider = Provider<TrailerRepository>(
  (ref) => ref.watch(appDependenciesProvider).trailers,
);
