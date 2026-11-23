import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/state/driver_form_state.dart';

/// Dependency Injection: Riverpod.
final updateDriverControllerProvider =
    NotifierProvider.autoDispose<UpdateDriverController, DriverFormState>(
      UpdateDriverController.new,
    );

class UpdateDriverController extends Notifier<DriverFormState> {
  @override
  DriverFormState build() => const DriverFormState();

  void clearFailure() {
    if (state.failure == null || state.isLoading) return;
    state = const DriverFormState();
  }

  Future<bool> submit({
    required String driverId,
    required String nameEn,
    required String nameAr,
    required String phone,
    required String nationalId,
    required String carLicense,
    required String personalLicense,
    List<String> favoritePlaceIds = const [],
  }) async {
    if (state.isLoading) return false;

    state = const DriverFormState(isLoading: true);
    try {
      await ref.read(updateDriverUseCaseProvider)(
        driverId: driverId,
        nameEn: nameEn,
        nameAr: nameAr,
        phone: phone,
        nationalId: nationalId,
        carLicense: carLicense,
        personalLicense: personalLicense,
        favoritePlaceIds: favoritePlaceIds,
      );
      if (!ref.mounted) return false;
      state = const DriverFormState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = DriverFormState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const DriverFormState(failure: UnknownFailure());
      return false;
    }
  }
}
