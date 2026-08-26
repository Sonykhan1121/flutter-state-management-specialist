import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/movie_providers.dart';
import '../widgets/movie_card.dart';
import 'favorites_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(movieCatalogProvider.notifier).load();
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _scheduleSearch(String value) {
    _debounce?.cancel();
    _debounce = Timer(
      const Duration(milliseconds: 450),
      () => ref.read(movieCatalogProvider.notifier).search(value),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [_BrandMark(), SizedBox(width: 10), Text('Movie Explorer')],
        ),
        actions: const [_FavoritesAction(), SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
              child: TextField(
                key: const Key('movie-search-field'),
                controller: _searchController,
                textInputAction: TextInputAction.search,
                onChanged: _scheduleSearch,
                onSubmitted: (value) {
                  _debounce?.cancel();
                  ref.read(movieCatalogProvider.notifier).search(value);
                },
                decoration: InputDecoration(
                  hintText: 'Search IMDb movies',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    tooltip: 'Clear search',
                    onPressed: () {
                      _searchController.clear();
                      _scheduleSearch('');
                    },
                    icon: const Icon(Icons.close),
                  ),
                ),
              ),
            ),
            const _CatalogControls(),
            const SizedBox(height: 8),
            const Expanded(child: _CatalogBody()),
          ],
        ),
      ),
    );
  }
}

class _BrandMark extends StatelessWidget {
  const _BrandMark();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        borderRadius: BorderRadius.circular(5),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 7, vertical: 4),
        child: Text(
          'IMDb',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w900,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _FavoritesAction extends ConsumerWidget {
  const _FavoritesAction();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(
      favoriteMoviesProvider.select((movies) => movies.length),
    );
    return Badge(
      isLabelVisible: count > 0,
      label: Text('$count'),
      child: IconButton(
        tooltip: 'Favorites',
        onPressed:
            () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => const FavoritesScreen()),
            ),
        icon: const Icon(Icons.favorite_outline),
      ),
    );
  }
}

class _CatalogControls extends ConsumerWidget {
  const _CatalogControls();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(movieCatalogProvider);
    final notifier = ref.read(movieCatalogProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: 42,
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            children: [
              ChoiceChip(
                label: const Text('All genres'),
                selected: catalog.genre == null,
                onSelected: (_) => notifier.setGenre(null),
              ),
              for (final genre in catalog.availableGenres) ...[
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text(genre),
                  selected: catalog.genre == genre,
                  onSelected: (_) => notifier.setGenre(genre),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
          child: Row(
            children: [
              Text('${catalog.visibleMovies.length} movies'),
              const Spacer(),
              const Text('Sort: '),
              DropdownButton<MovieSort>(
                value: catalog.sort,
                underline: const SizedBox.shrink(),
                onChanged: (value) {
                  if (value != null) notifier.setSort(value);
                },
                items: [
                  for (final sort in MovieSort.values)
                    DropdownMenuItem(value: sort, child: Text(sort.label)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogBody extends ConsumerWidget {
  const _CatalogBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(movieCatalogProvider);
    final notifier = ref.read(movieCatalogProvider.notifier);

    if ((catalog.status == CatalogStatus.initial ||
            catalog.status == CatalogStatus.loading) &&
        catalog.visibleMovies.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    if (catalog.status == CatalogStatus.error &&
        catalog.visibleMovies.isEmpty) {
      return _ErrorState(
        message: catalog.errorMessage ?? 'Could not load movies.',
        onRetry: notifier.retry,
      );
    }
    if (catalog.visibleMovies.isEmpty) return const _EmptyState();

    return Column(
      children: [
        if (catalog.isRefreshing) const LinearProgressIndicator(),
        Expanded(
          child: RefreshIndicator(
            onRefresh: notifier.retry,
            child: GridView.builder(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 220,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.60,
              ),
              itemCount: catalog.visibleMovies.length,
              itemBuilder:
                  (context, index) =>
                      MovieCard(movie: catalog.visibleMovies[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text('No movies match this search and genre.'),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 48),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            FilledButton.tonal(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
