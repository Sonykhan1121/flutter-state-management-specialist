import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/favorites_controller.dart';
import '../state/movie_catalog_controller.dart';
import '../widgets/movie_card.dart';
import 'favorites_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

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
      () => context.read<MovieCatalogController>().search(value),
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
                  context.read<MovieCatalogController>().search(value);
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

class _FavoritesAction extends StatelessWidget {
  const _FavoritesAction();

  @override
  Widget build(BuildContext context) {
    return Selector<FavoritesController, int>(
      selector: (_, favorites) => favorites.count,
      builder:
          (context, count, _) => Badge(
            isLabelVisible: count > 0,
            label: Text('$count'),
            child: IconButton(
              tooltip: 'Favorites',
              onPressed:
                  () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const FavoritesScreen(),
                    ),
                  ),
              icon: const Icon(Icons.favorite_outline),
            ),
          ),
    );
  }
}

class _CatalogControls extends StatelessWidget {
  const _CatalogControls();

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieCatalogController>(
      builder:
          (context, catalog, _) => Column(
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
                      onSelected: (_) => catalog.setGenre(null),
                    ),
                    for (final genre in catalog.availableGenres) ...[
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: Text(genre),
                        selected: catalog.genre == genre,
                        onSelected: (_) => catalog.setGenre(genre),
                      ),
                    ],
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Row(
                  children: [
                    Text(
                      catalog.totalResults > catalog.visibleMovies.length
                          ? '${catalog.visibleMovies.length} loaded · '
                              '${catalog.totalResults} results'
                          : '${catalog.visibleMovies.length} movies',
                    ),
                    const Spacer(),
                    const Text('Sort: '),
                    DropdownButton<MovieSort>(
                      value: catalog.sort,
                      underline: const SizedBox.shrink(),
                      onChanged: (value) {
                        if (value != null) catalog.setSort(value);
                      },
                      items: [
                        for (final sort in MovieSort.values)
                          DropdownMenuItem(
                            value: sort,
                            child: Text(sort.label),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
    );
  }
}

class _CatalogBody extends StatelessWidget {
  const _CatalogBody();

  @override
  Widget build(BuildContext context) {
    return Consumer<MovieCatalogController>(
      builder: (context, catalog, _) {
        if (catalog.status == CatalogStatus.loading &&
            catalog.visibleMovies.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        if (catalog.status == CatalogStatus.error &&
            catalog.visibleMovies.isEmpty) {
          return _ErrorState(
            message: catalog.errorMessage ?? 'Could not load movies.',
            onRetry: catalog.retry,
          );
        }
        if (catalog.visibleMovies.isEmpty) {
          return const _EmptyState();
        }

        return Column(
          children: [
            if (catalog.isRefreshing) const LinearProgressIndicator(),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  if (constraints.maxWidth <= 0 || constraints.maxHeight <= 0) {
                    return const SizedBox.shrink();
                  }
                  return NotificationListener<ScrollNotification>(
                    onNotification: (notification) {
                      if (notification.metrics.axis == Axis.vertical &&
                          notification.metrics.extentAfter < 600) {
                        catalog.loadMore();
                      }
                      return false;
                    },
                    child: RefreshIndicator(
                      onRefresh: catalog.retry,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          SliverPadding(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                            sliver: SliverGrid.builder(
                              gridDelegate:
                                  const SliverGridDelegateWithMaxCrossAxisExtent(
                                    maxCrossAxisExtent: 220,
                                    mainAxisSpacing: 14,
                                    crossAxisSpacing: 14,
                                    childAspectRatio: 0.60,
                                  ),
                              itemCount: catalog.visibleMovies.length,
                              itemBuilder:
                                  (context, index) => MovieCard(
                                    movie: catalog.visibleMovies[index],
                                  ),
                            ),
                          ),
                          SliverToBoxAdapter(
                            child: _CatalogFooter(catalog: catalog),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _CatalogFooter extends StatelessWidget {
  const _CatalogFooter({required this.catalog});

  final MovieCatalogController catalog;

  @override
  Widget build(BuildContext context) {
    if (catalog.isLoadingMore) {
      return const Padding(
        padding: EdgeInsets.all(24),
        child: Center(
          child: SizedBox.square(
            dimension: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
        ),
      );
    }
    if (catalog.loadMoreError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          children: [
            Text(
              catalog.loadMoreError!,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            TextButton.icon(
              onPressed: catalog.loadMore,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry loading more'),
            ),
          ],
        ),
      );
    }
    if (catalog.hasMore) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: OutlinedButton.icon(
          onPressed: catalog.loadMore,
          icon: const Icon(Icons.expand_more),
          label: const Text('Load more'),
        ),
      );
    }
    return const Padding(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Center(child: Text('You have reached the end.')),
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
