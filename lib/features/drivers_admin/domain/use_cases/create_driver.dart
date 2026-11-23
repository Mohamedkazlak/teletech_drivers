import 'package:teletech_drivers/features/drivers_admin/domain/repositories/driver_repository.dart';

class CreateDriverUseCase {
  const CreateDriverUseCase(this._repository);

  final DriverRepository _repository;

  Future<void> call({
    required String nameEn,
    required String nameAr,
    required String email,
    required String password,
    required String phone,
    required String nationalId,
    required String carLicense,
    required String personalLicense,
    List<String> favoritePlaceIds = const [],
  }) {
    return _repository.createDriver(
      nameEn: nameEn.trim(),
      nameAr: nameAr.trim(),
      email: email.trim().toLowerCase(),
      password: password,
      phone: phone.trim(),
      nationalId: nationalId.trim(),
      carLicense: carLicense.trim(),
      personalLicense: personalLicense.trim(),
      favoritePlaceIds: favoritePlaceIds,
    );
  }
}
