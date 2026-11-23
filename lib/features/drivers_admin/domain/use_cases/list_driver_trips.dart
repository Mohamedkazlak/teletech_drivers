import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_completed_trip.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

class ListDriverTripsUseCase {
  const ListDriverTripsUseCase(this._repository);

  final DriverRepository _repository;

  Future<List<DriverCompletedTrip>> call({
    required String driverId,
    String? period,
    String? date,
  }) {
    return _repository.listDriverTrips(
      driverId: driverId,
      period: period,
      date: date,
    );
  }
}
