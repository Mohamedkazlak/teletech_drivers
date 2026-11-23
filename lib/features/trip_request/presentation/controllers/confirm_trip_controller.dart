import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/trip/presentation/utils/invalidate_trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/invalidate_trip_request_providers.dart';

/// Result of posting a trip report.
enum ConfirmTripResult { success, alreadyClosed, failed }

class ConfirmTripState extends Equatable {
  const ConfirmTripState({this.isSubmitting = false, this.failure});

  final bool isSubmitting;
  final Failure? failure;

  @override
  List<Object?> get props => [isSubmitting, failure];
}

/// Dependency Injection: Riverpod.
final confirmTripControllerProvider =
    NotifierProvider.autoDispose<ConfirmTripController, ConfirmTripState>(
      ConfirmTripController.new,
    );

class ConfirmTripController extends Notifier<ConfirmTripState> {
  @override
  ConfirmTripState build() => const ConfirmTripState();

  Future<ConfirmTripResult> submit({
    required String requestId,
    required bool driverShowedUp,
    String? note,
  }) async {
    if (state.isSubmitting) return ConfirmTripResult.failed;
    state = const ConfirmTripState(isSubmitting: true);
    try {
      await ref.read(confirmTripUseCaseProvider)(
        requestId: requestId,
        driverShowedUp: driverShowedUp,
        note: note,
      );
      if (!ref.mounted) return ConfirmTripResult.failed;
      _refresh();
      state = const ConfirmTripState();
      return ConfirmTripResult.success;
    } on ConflictFailure {
      if (!ref.mounted) return ConfirmTripResult.failed;
      _refresh();
      state = const ConfirmTripState();
      return ConfirmTripResult.alreadyClosed;
    } on Failure catch (failure) {
      if (!ref.mounted) return ConfirmTripResult.failed;
      state = ConfirmTripState(failure: failure);
      return ConfirmTripResult.failed;
    } on Object {
      if (!ref.mounted) return ConfirmTripResult.failed;
      state = const ConfirmTripState(failure: UnknownFailure());
      return ConfirmTripResult.failed;
    }
  }

  void _refresh() {
    invalidateTripRequestProviders(ref);
    invalidateTripProviders(ref);
  }
}
