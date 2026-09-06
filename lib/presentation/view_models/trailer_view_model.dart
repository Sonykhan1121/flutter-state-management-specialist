import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/trailer_repository.dart';
import '../models/trailer_state.dart';

// A read-only async ViewModel. Riverpod owns loading/error/disposal state.
final trailerViewModelProvider = FutureProvider.autoDispose
    .family<TrailerState, (Movie, TrailerRepository)>((ref, input) async {
      final (movie, repository) = input;
      TrailerState result({Trailer? trailer, String? error}) => TrailerState(
        searchUri: repository.youtubeSearchUri(movie),
        canSearchAutomatically: repository.canSearchAutomatically,
        trailer: trailer,
        errorMessage: error,
      );
      if (!repository.canSearchAutomatically) return result();
      try {
        return result(trailer: await repository.findTrailer(movie));
      } catch (_) {
        return result(error: 'Could not load the trailer. Please retry.');
      }
    });
