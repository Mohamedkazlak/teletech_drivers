import 'package:teletech_drivers/features/trip_request/domain/entities/group_suggestion.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/repositories/trip_request_repository.dart';

class GetGroupingSuggestionsUseCase {
  const GetGroupingSuggestionsUseCase(this._repository);

  final TripRequestRepository _repository;

  /// Server-built clusters (scoped to the caller's role), joined with
  /// [knownRequests].
  Future<List<GroupSuggestion>> call(List<TripRequest> knownRequests) {
    return _repository.getGroupingSuggestions(knownRequests: knownRequests);
  }
}
