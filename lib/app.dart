import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'bloc/favorites_cubit.dart';
import 'bloc/movie_catalog_bloc.dart';
import 'data/favorites_repository.dart';
import 'data/movie_repository.dart';
import 'data/trailer_repository.dart';
import 'screens/home_screen.dart';

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
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<MovieRepository>.value(
          value: repository ?? createMovieRepository(),
        ),
        RepositoryProvider<FavoritesRepository>.value(
          value: favoritesRepository ?? createFavoritesRepository(),
        ),
        RepositoryProvider<TrailerRepository>.value(
          value: trailerRepository ?? createTrailerRepository(),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create:
                (context) =>
                    MovieCatalogBloc(context.read<MovieRepository>())
                      ..add(const CatalogLoadRequested()),
          ),
          BlocProvider(
            create:
                (context) =>
                    FavoritesCubit(context.read<FavoritesRepository>())..load(),
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
      ),
    );
  }
}
