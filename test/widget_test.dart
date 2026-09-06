import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/app.dart';
import 'package:provider_project/domain/models/movie.dart';

import 'fakes.dart';

void main() {
  testWidgets('movie can be favorited and appears on favorites screen', (
    tester,
  ) async {
    await tester.pumpWidget(
      MovieApp(
        repository: FakeMovieRepository(testMovies),
        favoritesRepository: FakeFavoritesRepository(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Movie Explorer'), findsOneWidget);
    expect(find.text('New Action'), findsWidgets);

    await tester.tap(find.byIcon(Icons.favorite_border).first);
    await tester.pump();
    await tester.tap(find.byTooltip('Favorites'));
    await tester.pumpAndSettle();

    expect(find.text('Favorites'), findsOneWidget);
    expect(find.text('New Action'), findsWidgets);
  });

  testWidgets('a database load error is visible and can be retried', (
    tester,
  ) async {
    final favorites = _RetryableFavoritesRepository();
    await tester.pumpWidget(
      MovieApp(
        repository: FakeMovieRepository(testMovies),
        favoritesRepository: favorites,
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Favorites'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Storage unavailable'), findsOneWidget);
    expect(find.textContaining('No favorites yet.'), findsNothing);
    favorites.fail = false;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Storage unavailable'), findsNothing);
    expect(find.textContaining('No favorites yet.'), findsOneWidget);
  });
}

class _RetryableFavoritesRepository extends FakeFavoritesRepository {
  bool fail = true;
  @override
  Future<List<Movie>> loadFavorites() async {
    if (fail) throw Exception('Storage unavailable');
    return super.loadFavorites();
  }
}
