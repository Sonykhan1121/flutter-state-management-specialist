import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/movie_providers.dart';
import '../widgets/movie_card.dart';

class FavoritesScreen extends ConsumerWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final movies = ref.watch(favoriteMovieListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body:
          movies.isEmpty
              ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.favorite_border, size: 52),
                      SizedBox(height: 12),
                      Text(
                        'No favorites yet.\nTap the heart on a movie to add one.',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
              : GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: 220,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.60,
                ),
                itemCount: movies.length,
                itemBuilder:
                    (context, index) => MovieCard(movie: movies[index]),
              ),
    );
  }
}
