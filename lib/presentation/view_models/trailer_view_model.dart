import 'package:flutter/foundation.dart';
import '../../domain/models/movie.dart';
import '../../domain/repositories/trailer_repository.dart';
import '../models/trailer_state.dart';

class TrailerViewModel extends ChangeNotifier {
  TrailerViewModel(this._repository, this._movie);
  TrailerState get state => _state ?? _createState();
  TrailerState? _state;
  bool _disposed = false;
  void _update(TrailerState value) {
    _state = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

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
    if (_disposed || !_repository.canSearchAutomatically) return;
    final request = ++_requestId;
    _update(_createState(loading: true));
    try {
      final trailer = await _repository.findTrailer(_movie);
      if (_disposed || request != _requestId) return;
      _update(_createState(trailer: trailer));
    } catch (error) {
      if (_disposed || request != _requestId) return;
      _update(_createState(error: 'Could not load the trailer. Please retry.'));
    }
  }
}
