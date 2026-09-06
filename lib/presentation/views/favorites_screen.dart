import 'package:flutter/material.dart';
import '../widgets/favorites_body.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/movie_providers.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(favoriteMoviesProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: FavoritesBody(
        movies: ref.watch(favoriteMovieListProvider),
        isLoading: state.isLoading,
        errorMessage: state.errorMessage,
        onRetry: () => ref.read(favoriteMoviesProvider.notifier).load(),
      ),
    );
  }
}
