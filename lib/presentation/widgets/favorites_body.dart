import 'package:flutter/material.dart';
import '../../domain/models/movie.dart';
import 'movie_card.dart';

class FavoritesBody extends StatelessWidget {
  const FavoritesBody({
    super.key,
    required this.movies,
    required this.isLoading,
    required this.errorMessage,
    required this.onRetry,
  });
  final List<Movie> movies;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      if (isLoading) const LinearProgressIndicator(),
      if (errorMessage != null)
        MaterialBanner(
          content: Text(errorMessage!),
          actions: [
            TextButton(
              onPressed: isLoading ? null : onRetry,
              child: const Text('Retry'),
            ),
          ],
        ),
      Expanded(
        child:
            movies.isEmpty
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      isLoading
                          ? 'Loading saved favorites…'
                          : errorMessage != null
                          ? 'Your saved favorites could not be loaded.'
                          : 'No favorites yet.\nTap the heart on a movie to add one.',
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
                : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 220,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    childAspectRatio: .60,
                  ),
                  itemCount: movies.length,
                  itemBuilder: (_, index) => MovieCard(movie: movies[index]),
                ),
      ),
    ],
  );
}
