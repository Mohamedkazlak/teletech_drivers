import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_page.dart';
import 'package:teletech_drivers/features/trip/domain/repositories/trip_repository.dart';

class ListCreatedByMeTripsUseCase {
  const ListCreatedByMeTripsUseCase(this._repository);

  final TripRepository _repository;

  Future<TripPage> call({
    required CreatedTripBucket bucket,
    required int page,
  }) {
    return _repository.listCreatedByMe(bucket: bucket, page: page);
  }
}
