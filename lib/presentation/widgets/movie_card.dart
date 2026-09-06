import 'favorite_button.dart';
import 'package:flutter/material.dart';

import 'package:provider_project/domain/models/movie.dart';
import 'package:provider_project/presentation/views/movie_details_screen.dart';
import 'package:provider_project/presentation/widgets/movie_poster.dart';

class MovieCard extends StatelessWidget {
  const MovieCard({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
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
                    child: FavoriteButton(movie: movie, filled: true),
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
