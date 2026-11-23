import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

class UpdateDriverUseCase {
  const UpdateDriverUseCase(this._repository);

  final DriverRepository _repository;

  Future<void> call({
    required String driverId,
    required String nameEn,
    required String nameAr,
    required String phone,
    required String nationalId,
    required String carLicense,
    required String personalLicense,
    List<String> favoritePlaceIds = const [],
  }) {
    return _repository.updateDriver(
      driverId: driverId,
      nameEn: nameEn.trim(),
      nameAr: nameAr.trim(),
      phone: phone.trim(),
      nationalId: nationalId.trim(),
      carLicense: carLicense.trim(),
      personalLicense: personalLicense.trim(),
      favoritePlaceIds: favoritePlaceIds,
    );
  }
}
