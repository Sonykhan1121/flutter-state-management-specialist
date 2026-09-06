import 'package:flutter/material.dart';
import '../../domain/models/movie.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../view_models/movie_providers.dart';

class FavoriteButton extends ConsumerWidget {
  const FavoriteButton({super.key, required this.movie, this.filled = false});
  final Movie movie;
  final bool filled;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final flags = ref.watch(
      favoriteMoviesProvider.select(
        (state) => (state.byId.containsKey(movie.id), state.isBusy(movie.id)),
      ),
    );
    return _button(context, flags, () async {
      await ref.read(favoriteMoviesProvider.notifier).toggle(movie);
      return context.mounted
          ? ref.read(favoriteMoviesProvider).errorMessage
          : null;
    });
  }

  Widget _button(
    BuildContext context,
    (bool, bool) flags,
    Future<String?> Function() toggle,
  ) {
    final (isFavorite, isBusy) = flags;
    final tooltip =
        isFavorite
            ? 'Remove ${movie.title} from favorites'
            : 'Add ${movie.title} to favorites';
    final icon = Icon(
      isFavorite ? Icons.favorite : Icons.favorite_border,
      color: isFavorite ? Colors.redAccent : null,
    );
    Future<void> onPressed() async {
      final error = await toggle();
      if (error != null && context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }

    return filled
        ? IconButton.filledTonal(
          tooltip: tooltip,
          onPressed: isBusy ? null : onPressed,
          icon: icon,
        )
        : IconButton(
          tooltip: tooltip,
          onPressed: isBusy ? null : onPressed,
          icon: icon,
        );
  }
}
