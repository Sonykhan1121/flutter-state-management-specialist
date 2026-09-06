import 'package:flutter/material.dart';
import 'di/app_dependencies.dart';
import 'package:provider/provider.dart';

import 'package:provider_project/domain/repositories/favorites_repository.dart';
import 'package:provider_project/domain/repositories/movie_repository.dart';
import 'package:provider_project/domain/repositories/trailer_repository.dart';
import 'package:provider_project/presentation/views/home_screen.dart';
import 'package:provider_project/presentation/view_models/favorites_view_model.dart';
import 'package:provider_project/presentation/view_models/movie_catalog_view_model.dart';

class MovieApp extends StatefulWidget {
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
  State<MovieApp> createState() => _MovieAppState();
}

class _MovieAppState extends State<MovieApp> {
  late final AppDependencies _dependencies;

  @override
  void initState() {
    super.initState();
    _dependencies = AppDependencies(
      movies: widget.repository,
      favorites: widget.favoritesRepository,
      trailers: widget.trailerRepository,
    );
  }

  @override
  void dispose() {
    _dependencies.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MovieRepository>.value(value: _dependencies.movies),
        Provider<FavoritesRepository>.value(value: _dependencies.favorites),
        Provider<TrailerRepository>.value(value: _dependencies.trailers),
        ChangeNotifierProvider(
          create:
              (context) =>
                  MovieCatalogViewModel(context.read<MovieRepository>())
                    ..load(),
        ),
        ChangeNotifierProvider(
          create:
              (context) =>
                  FavoritesViewModel(context.read<FavoritesRepository>())
                    ..load(),
        ),
      ],
      child: MaterialApp(
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
      ),
    );
  }
}
