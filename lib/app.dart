import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'data/movie_repository.dart';
import 'screens/home_screen.dart';
import 'state/favorites_controller.dart';
import 'state/movie_catalog_controller.dart';

class MovieApp extends StatelessWidget {
  const MovieApp({super.key, this.repository});

  final MovieRepository? repository;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<MovieRepository>.value(
          value: repository ?? createMovieRepository(),
        ),
        ChangeNotifierProvider(
          create:
              (context) =>
                  MovieCatalogController(context.read<MovieRepository>())
                    ..load(),
        ),
        ChangeNotifierProvider(create: (_) => FavoritesController()),
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
