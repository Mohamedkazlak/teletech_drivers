import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/state/fix_legacy_drivers_state.dart';

/// Dependency Injection: Riverpod.
final fixLegacyDriversControllerProvider =
    NotifierProvider.autoDispose<
      FixLegacyDriversController,
      FixLegacyDriversState
    >(FixLegacyDriversController.new);

class FixLegacyDriversController extends Notifier<FixLegacyDriversState> {
  @override
  FixLegacyDriversState build() => const FixLegacyDriversState();

  Future<int?> run() async {
    if (state.isLoading) return null;

    state = const FixLegacyDriversState(isLoading: true);
    try {
      final updatedCount = await ref.read(fixLegacyDriversUseCaseProvider)();
      if (!ref.mounted) return null;
      state = const FixLegacyDriversState();
      return updatedCount;
    } on Failure catch (failure) {
      if (!ref.mounted) return null;
      state = FixLegacyDriversState(failure: failure);
      return null;
    } on Object {
      if (!ref.mounted) return null;
      state = const FixLegacyDriversState(failure: UnknownFailure());
      return null;
    }
  }
}
