import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/state/trip_action_state.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/utils/invalidate_trip_providers.dart';

/// Dependency Injection: Riverpod.
final tripAssignmentControllerProvider =
    NotifierProvider.autoDispose<TripAssignmentController, TripActionState>(
      TripAssignmentController.new,
    );

class TripAssignmentController extends Notifier<TripActionState> {
  @override
  TripActionState build() => const TripActionState();

  Future<bool> assign({
    required String tripId,
    required String driverId,
  }) {
    return _run(
      tripId: tripId,
      action: () => ref.read(assignDriverUseCaseProvider)(
        tripId: tripId,
        driverId: driverId,
      ),
    );
  }

  Future<bool> reassign({
    required String tripId,
    required String driverId,
  }) {
    return _run(
      tripId: tripId,
      action: () => ref.read(reassignDriverUseCaseProvider)(
        tripId: tripId,
        driverId: driverId,
      ),
    );
  }

  Future<bool> cancel(String tripId) {
    return _run(
      tripId: tripId,
      action: () => ref.read(cancelTripUseCaseProvider)(tripId),
    );
  }

  Future<bool> _run({
    required String tripId,
    required Future<void> Function() action,
  }) async {
    if (state.isLoading) return false;

    state = TripActionState(isLoading: true, activeTripId: tripId);
    try {
      await action();
      if (!ref.mounted) return false;
      invalidateTripProviders(ref);
      state = const TripActionState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = TripActionState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const TripActionState(failure: UnknownFailure());
      return false;
    }
  }
}
