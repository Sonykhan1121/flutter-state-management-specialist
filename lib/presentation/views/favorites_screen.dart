import 'package:flutter/material.dart';
import '../widgets/favorites_body.dart';
import 'package:provider/provider.dart';
import '../view_models/favorites_view_model.dart';

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Favorites')),
      body: Consumer<FavoritesViewModel>(
        builder:
            (_, vm, __) => FavoritesBody(
              movies: vm.movies,
              isLoading: vm.isLoading,
              errorMessage: vm.errorMessage,
              onRetry: vm.load,
            ),
      ),
    );
  }
}
