import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/movie.dart';
import '../state/movie_providers.dart';
import '../widgets/movie_poster.dart';

class MovieDetailsScreen extends ConsumerWidget {
  const MovieDetailsScreen({super.key, required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isFavorite = ref.watch(isFavoriteProvider(movie.id));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Movie details'),
        actions: [
          IconButton(
            tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
            onPressed:
                () => ref.read(favoriteMoviesProvider.notifier).toggle(movie),
            icon: Icon(
              isFavorite ? Icons.favorite : Icons.favorite_border,
              color: isFavorite ? Colors.redAccent : null,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final wide = constraints.maxWidth >= 680;
          final poster = SizedBox(
            width: wide ? 270 : 210,
            height: wide ? 405 : 315,
            child: MoviePoster(
              url: movie.posterUrl,
              title: movie.title,
              borderRadius: BorderRadius.circular(16),
            ),
          );
          final details = _MovieInformation(movie: movie);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 960),
                child:
                    wide
                        ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            poster,
                            const SizedBox(width: 28),
                            Expanded(child: details),
                          ],
                        )
                        : Column(
                          children: [
                            poster,
                            const SizedBox(height: 22),
                            details,
                          ],
                        ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _MovieInformation extends StatelessWidget {
  const _MovieInformation({required this.movie});

  final Movie movie;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          movie.title,
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _FactChip(icon: Icons.calendar_today, label: '${movie.year}'),
            _FactChip(icon: Icons.schedule, label: movie.runtime),
            _FactChip(icon: Icons.theaters, label: movie.rated),
            _FactChip(
              icon: Icons.star_rounded,
              label: '${movie.rating.toStringAsFixed(1)} / 10',
            ),
          ],
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final genre in movie.genres) Chip(label: Text(genre)),
          ],
        ),
        const SizedBox(height: 20),
        Text(movie.plot, style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 24),
        _LabelValue(label: 'Director', value: movie.director),
        const SizedBox(height: 12),
        _LabelValue(label: 'Cast', value: movie.actors),
        const SizedBox(height: 12),
        _LabelValue(label: 'IMDb ID', value: movie.id),
      ],
    );
  }
}

class _FactChip extends StatelessWidget {
  const _FactChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(avatar: Icon(icon, size: 17), label: Text(label));
  }
}

class _LabelValue extends StatelessWidget {
  const _LabelValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          TextSpan(text: value),
        ],
      ),
    );
  }
}
