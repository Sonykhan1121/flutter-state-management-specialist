import 'package:flutter/material.dart';
import '../../domain/models/movie.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../view_models/favorites_cubit.dart';

class FavoriteButton extends StatelessWidget {
  const FavoriteButton({super.key, required this.movie, this.filled = false});
  final Movie movie;
  final bool filled;
  @override
  Widget build(BuildContext context) {
    return BlocSelector<FavoritesCubit, FavoritesState, (bool, bool)>(
      selector: (state) => (state.isFavorite(movie.id), state.isBusy(movie.id)),
      builder:
          (context, flags) => _button(context, flags, () async {
            final vm = context.read<FavoritesCubit>();
            await vm.toggle(movie);
            return vm.state.errorMessage;
          }),
    );
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
