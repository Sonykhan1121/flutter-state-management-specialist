import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/trailer_repository.dart';
import '../models/trailer_state.dart';

class TrailerCubit extends Cubit<TrailerState> {
  TrailerCubit(this._repository, this._movie)
    : super(
        TrailerState(
          searchUri: _repository.youtubeSearchUri(_movie),
          canSearchAutomatically: _repository.canSearchAutomatically,
        ),
      );
  void _update(TrailerState value) => emit(value);
  final TrailerRepository _repository;
  final Movie _movie;
  int _requestId = 0;
  TrailerState _createState({
    bool loading = false,
    Trailer? trailer,
    String? error,
  }) => TrailerState(
    searchUri: _repository.youtubeSearchUri(_movie),
    canSearchAutomatically: _repository.canSearchAutomatically,
    isLoading: loading,
    trailer: trailer,
    errorMessage: error,
  );
  Future<void> load() async {
    if (isClosed || !_repository.canSearchAutomatically) return;
    final request = ++_requestId;
    _update(_createState(loading: true));
    try {
      final trailer = await _repository.findTrailer(_movie);
      if (isClosed || request != _requestId) return;
      _update(_createState(trailer: trailer));
    } catch (error) {
      if (isClosed || request != _requestId) return;
      _update(_createState(error: 'Could not load the trailer. Please retry.'));
    }
  }
}
