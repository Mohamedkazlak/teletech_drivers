import 'package:geolocator/geolocator.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driver_location_publish_outcome.dart';
import 'package:teletech_drivers/features/tracking/domain/repositories/location_repository.dart';

class PublishLocationUseCase {
  const PublishLocationUseCase(this._repository);

  final LocationRepository _repository;

  /// Sends [tripId] only while [tripInProgress] is true.
  Future<DriverLocationPublishOutcome> call({
    required Position position,
    String? tripId,
    required bool tripInProgress,
  }) {
    final id = tripId?.trim();
    return _repository.publishLocation(
      position: position,
      tripId: tripInProgress && id != null && id.isNotEmpty ? id : null,
    );
  }
}
