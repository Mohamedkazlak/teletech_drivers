import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/invalidate_trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/state/trip_request_form_state.dart';

/// Dependency Injection: Riverpod.
final cancelTripRequestControllerProvider =
    NotifierProvider.autoDispose<
      CancelTripRequestController,
      TripRequestFormState
    >(CancelTripRequestController.new);

class CancelTripRequestController extends Notifier<TripRequestFormState> {
  @override
  TripRequestFormState build() => const TripRequestFormState();

  /// Returns true when the request was cancelled successfully.
  Future<bool> cancel(String requestId) async {
    if (state.isLoading) return false;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      state = const TripRequestFormState(failure: UnknownFailure());
      return false;
    }

    state = TripRequestFormState(isLoading: true, activeRequestId: requestId);
    try {
      await ref.read(cancelPendingTripRequestUseCaseProvider)(
        requestId: requestId,
        employeeId: user.id,
      );
      if (!ref.mounted) return false;
      invalidateTripRequestProviders(ref);
      state = const TripRequestFormState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = TripRequestFormState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const TripRequestFormState(failure: UnknownFailure());
      return false;
    }
  }
}
