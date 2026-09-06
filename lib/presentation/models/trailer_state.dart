import '../../domain/repositories/trailer_repository.dart';

class TrailerState {
  const TrailerState({
    required this.searchUri,
    required this.canSearchAutomatically,
    this.isLoading = false,
    this.trailer,
    this.errorMessage,
  });
  final Uri searchUri;
  final bool canSearchAutomatically;
  final bool isLoading;
  final Trailer? trailer;
  final String? errorMessage;
}
