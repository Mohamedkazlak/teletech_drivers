import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_attendance_filter.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

class WatchAllDriverProfilesUseCase {
  const WatchAllDriverProfilesUseCase(this._repository);

  final DriverRepository _repository;

  Stream<List<DriverProfile>> call({DriverAttendanceFilter? attendance}) {
    return _repository.watchDriverProfiles(attendance: attendance);
  }
}
