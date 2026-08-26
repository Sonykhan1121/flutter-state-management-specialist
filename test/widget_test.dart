import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/app.dart';

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
}
