import 'package:flutter/material.dart';
import '../widgets/favorites_body.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../view_models/favorites_cubit.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: BlocBuilder<FavoritesCubit, FavoritesState>(
        builder:
            (context, state) => FavoritesBody(
              movies: state.movies,
              isLoading: state.isLoading,
              errorMessage: state.errorMessage,
              onRetry: context.read<FavoritesCubit>().load,
            ),
      ),
    );
  }
}
