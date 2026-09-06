import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_player_iframe/youtube_player_iframe.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/trailer_repository.dart';
import '../models/trailer_state.dart';
import '../view_models/trailer_view_model.dart';

class TrailerScreen extends StatelessWidget {
  const TrailerScreen({
    super.key,
    required this.movie,
    required this.repository,
  });
  final Movie movie;
  final TrailerRepository repository;
  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TrailerCubit(repository, movie)..load(),
      child: BlocBuilder<TrailerCubit, TrailerState>(
        builder:
            (context, state) => _TrailerBody(
              state: state,
              onRetry: context.read<TrailerCubit>().load,
            ),
      ),
    );
  }
}

class _TrailerBody extends StatelessWidget {
  const _TrailerBody({required this.state, required this.onRetry});
  final TrailerState state;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const Scaffold(
        appBar: _TrailerAppBar(),
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!state.canSearchAutomatically) {
      return _TrailerFallbackScaffold(
        searchUri: state.searchUri,
        message:
            'Automatic trailer search is not configured. You can search YouTube in the in-app browser.',
      );
    }
    if (state.errorMessage != null) {
      return _TrailerFallbackScaffold(
        searchUri: state.searchUri,
        message: state.errorMessage!,
        onRetry: onRetry,
      );
    }
    if (state.trailer == null) {
      return _TrailerFallbackScaffold(
        searchUri: state.searchUri,
        message: 'No embeddable trailer was found automatically.',
        onRetry: onRetry,
      );
    }
    return _TrailerPlayerScaffold(trailer: state.trailer!);
  }
}

class _TrailerPlayerScaffold extends StatefulWidget {
  const _TrailerPlayerScaffold({required this.trailer});

  final Trailer trailer;

  @override
  State<_TrailerPlayerScaffold> createState() => _TrailerPlayerScaffoldState();
}

class _TrailerPlayerScaffoldState extends State<_TrailerPlayerScaffold> {
  late final YoutubePlayerController _controller;

  @override
  void initState() {
    super.initState();
    _controller = YoutubePlayerController.fromVideoId(
      videoId: widget.trailer.videoId,
      autoPlay: false,
      params: const YoutubePlayerParams(showFullscreenButton: true),
    );
  }

  @override
  void dispose() {
    _controller.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return YoutubePlayerScaffold(
      controller: _controller,
      builder:
          (context, player) => Scaffold(
            appBar: const _TrailerAppBar(),
            body: ListView(
              padding: const EdgeInsets.only(bottom: 24),
              children: [
                player,
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.trailer.title,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      OutlinedButton.icon(
                        onPressed:
                            () => launchUrl(
                              widget.trailer.watchUri,
                              mode: LaunchMode.externalApplication,
                            ),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open on YouTube'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
    );
  }
}

class _TrailerFallbackScaffold extends StatelessWidget {
  const _TrailerFallbackScaffold({
    required this.searchUri,
    required this.message,
    this.onRetry,
  });

  final Uri searchUri;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const _TrailerAppBar(),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.ondemand_video, size: 60),
              const SizedBox(height: 16),
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 18),
              FilledButton.icon(
                onPressed: () => _openSearch(context),
                icon: const Icon(Icons.search),
                label: const Text('Search YouTube'),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 8),
                TextButton(onPressed: onRetry, child: const Text('Try again')),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openSearch(BuildContext context) async {
    final opened = await launchUrl(
      searchUri,
      mode: LaunchMode.inAppBrowserView,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Could not open YouTube.')));
    }
  }
}

class _TrailerAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _TrailerAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Trailer'));
  }
}
