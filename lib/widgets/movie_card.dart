import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie.dart';
import '../screens/movie_details_screen.dart';
import '../state/movie_providers.dart';
import 'movie_poster.dart';

class MovieCard extends ConsumerWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(movie.id));

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => MovieDetailsScreen(movie: movie),
              ),
            ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  MoviePoster(url: movie.posterUrl, title: movie.title),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: IconButton.filledTonal(
                      tooltip:
                          isFavorite
                              ? 'Remove ${movie.title} from favorites'
                              : 'Add ${movie.title} to favorites',
                      onPressed:
                          () => ref
                              .read(favoriteMoviesProvider.notifier)
                              .toggle(movie),
                      icon: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.redAccent : null,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 2),
              child: Text(
                movie.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.star_rounded,
                    size: 17,
                    color: Color(0xFFF5C518),
                  ),
                  const SizedBox(width: 3),
                  Text(
                    movie.rating == 0 ? '—' : movie.rating.toStringAsFixed(1),
                  ),
                  const Spacer(),
                  Text(movie.year == 0 ? '—' : '${movie.year}'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
