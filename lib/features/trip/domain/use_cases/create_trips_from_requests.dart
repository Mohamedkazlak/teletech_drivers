import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/trip_grouping_strategy.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';

class CreateTripsFromRequestsUseCase {
  const CreateTripsFromRequestsUseCase(this._repository);

  final TripRepository _repository;

  Future<List<Trip>> call({
    required List<TripRequest> requests,
    required TripGroupingStrategy strategy,
    required String createdBy,
    DateTime? scheduledAt,
  }) {
    if (requests.isEmpty) {
      throw ArgumentError('At least one request is required');
    }
    for (final request in requests) {
      if (!request.isAwaitingTrip) {
        throw ArgumentError(
          'Only approved requests without a trip can become trips',
        );
      }
    }

    return _repository.createTripsFromRequests(
      requests: requests,
      strategy: strategy,
      createdBy: createdBy,
      scheduledAt: scheduledAt,
    );
  }
}
