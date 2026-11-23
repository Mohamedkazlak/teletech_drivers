import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';
import 'package:teletech_drivers/features/tracking/domain/repositories/location_repository.dart';

class WatchLiveMapUseCase {
  const WatchLiveMapUseCase(this._repository);

  final LocationRepository _repository;

  Stream<List<LiveMapDriver>> call(String? driverId) {
    final id = driverId?.trim();
    return _repository.watchLiveMap(
      driverId: (id == null || id.isEmpty) ? null : id,
    );
  }
}
