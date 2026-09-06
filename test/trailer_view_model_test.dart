import 'package:flutter_test/flutter_test.dart';
import 'package:provider_project/domain/models/movie.dart';
import 'package:provider_project/domain/repositories/trailer_repository.dart';
import 'package:provider_project/presentation/models/trailer_state.dart';
import 'package:provider_project/presentation/view_models/trailer_view_model.dart';
import 'fakes.dart';

class FakeTrailerRepository implements TrailerRepository {
  bool fail = false;
  bool enabled = true;
  int calls = 0;
  @override
  bool get canSearchAutomatically => enabled;
  @override
  Uri youtubeSearchUri(Movie movie) =>
      Uri.https('www.youtube.com', '/results', {'search_query': movie.title});
  @override
  Future<Trailer?> findTrailer(Movie movie) async {
    calls++;
    if (fail) throw Exception('Network failed');
    return const Trailer(videoId: 'test-video', title: 'Trailer');
  }
}

void main() {
  test(
    'the trailer ViewModel maps a repository result into renderable state',
    () async {
      final repo = FakeTrailerRepository();
      final load = createLoader(repo);
      final state = await load();
      expect(state.trailer?.videoId, 'test-video');
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    },
  );
  test(
    'a failed trailer request exposes an error and retry can recover',
    () async {
      final repo = FakeTrailerRepository()..fail = true;
      final load = createLoader(repo);
      expect((await load()).errorMessage, contains('Please retry'));
      repo.fail = false;
      expect((await load()).trailer?.videoId, 'test-video');
      expect(repo.calls, 2);
    },
  );
  test(
    'without automatic search, the ViewModel exposes a fallback without I/O',
    () async {
      final repo = FakeTrailerRepository()..enabled = false;
      final state = await createLoader(repo)();
      expect(state.canSearchAutomatically, isFalse);
      expect(
        state.searchUri.queryParameters['search_query'],
        testMovies.first.title,
      );
      expect(repo.calls, 0);
    },
  );
}

Future<TrailerState> Function() createLoader(FakeTrailerRepository repo) {
  final vm = TrailerCubit(repo, testMovies.first);
  addTearDown(vm.close);
  return () async {
    await vm.load();
    return vm.state;
  };
}
