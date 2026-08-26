import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/favorites_repository.dart';
import 'data/movie_repository.dart';
import 'data/trailer_repository.dart';
import 'screens/home_screen.dart';
import 'state/movie_providers.dart';

class MovieApp extends StatelessWidget {
  const MovieApp({
    super.key,
    this.repository,
    this.favoritesRepository,
    this.trailerRepository,
  });

  final MovieRepository? repository;
  final FavoritesRepository? favoritesRepository;
  final TrailerRepository? trailerRepository;

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        if (repository != null)
          movieRepositoryProvider.overrideWithValue(repository!),
        if (favoritesRepository != null)
          favoritesRepositoryProvider.overrideWithValue(favoritesRepository!),
        if (trailerRepository != null)
          trailerRepositoryProvider.overrideWithValue(trailerRepository!),
      ],
      child: const _MovieMaterialApp(),
    );
  }
}

class _MovieMaterialApp extends StatelessWidget {
  const _MovieMaterialApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Movie Explorer',
      theme: ThemeData(
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF5C518),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF0D0F12),
        cardTheme: const CardThemeData(
          color: Color(0xFF171A20),
          clipBehavior: Clip.antiAlias,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
        useMaterial3: true,
      ),
      home: const HomeScreen(),
    );
  }
}
