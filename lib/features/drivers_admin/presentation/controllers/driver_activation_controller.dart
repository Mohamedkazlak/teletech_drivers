import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/state/driver_action_state.dart';

/// Dependency Injection: Riverpod.
final driverActivationControllerProvider =
    NotifierProvider.autoDispose<DriverActivationController, DriverActionState>(
      DriverActivationController.new,
    );

class DriverActivationController extends Notifier<DriverActionState> {
  @override
  DriverActionState build() => const DriverActionState();

  Future<bool> setActive({
    required String driverId,
    required bool isActive,
  }) async {
    if (state.isLoading) return false;

    state = DriverActionState(isLoading: true, activeDriverId: driverId);
    try {
      await ref.read(setDriverActiveUseCaseProvider)(
        driverId: driverId,
        isActive: isActive,
      );
      if (!ref.mounted) return false;
      state = const DriverActionState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = DriverActionState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const DriverActionState(failure: UnknownFailure());
      return false;
    }
  }
}
