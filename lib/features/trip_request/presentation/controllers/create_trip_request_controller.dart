import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/utils/invalidate_trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/create_trip_request_result.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/state/trip_request_form_state.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/invalidate_trip_request_providers.dart';

/// Dependency Injection: Riverpod.
final createTripRequestControllerProvider =
    NotifierProvider.autoDispose<
      CreateTripRequestController,
      TripRequestFormState
    >(CreateTripRequestController.new);

class CreateTripRequestController extends Notifier<TripRequestFormState> {
  @override
  TripRequestFormState build() => const TripRequestFormState();

  void clearFailure() {
    if (state.failure == null || state.isLoading) return;
    state = const TripRequestFormState();
  }

  /// Returns the create result on success, or null when validation/submit failed.
  Future<CreateTripRequestResult?> submit({
    required String pickupPlaceId,
    required String pickupPlaceName,
    required String destinationPlaceId,
    required String destinationPlaceName,
    required DateTime requestedDateTime,
    required String notes,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? destinationLat,
    double? destinationLng,
    String? destinationAddress,
  }) async {
    if (state.isLoading) return null;

    final user = ref.read(currentUserProvider).asData?.value;
    final branch = user?.branch;
    final phone = user?.phone?.trim();
    if (user == null ||
        branch == null ||
        phone == null ||
        phone.isEmpty) {
      state = const TripRequestFormState(failure: UnknownFailure());
      return null;
    }

    state = const TripRequestFormState(isLoading: true);
    try {
      final result = await ref.read(createTripRequestUseCaseProvider)(
        requesterRole: user.role,
        employeeId: user.id,
        employeeName: user.name,
        employeeBranch: branch,
        employeePhone: phone,
        pickupPlaceId: pickupPlaceId,
        pickupPlaceName: pickupPlaceName,
        destinationPlaceId: destinationPlaceId,
        destinationPlaceName: destinationPlaceName,
        requestedDateTime: requestedDateTime,
        notes: notes,
        pickupLat: pickupLat,
        pickupLng: pickupLng,
        pickupAddress: pickupAddress,
        destinationLat: destinationLat,
        destinationLng: destinationLng,
        destinationAddress: destinationAddress,
      );
      if (!ref.mounted) return null;
      invalidateTripRequestProviders(ref);
      if (result.tripId != null) invalidateTripProviders(ref);
      state = TripRequestFormState(createdTripId: result.tripId);
      return result;
    } on Failure catch (failure) {
      if (!ref.mounted) return null;
      state = TripRequestFormState(failure: failure);
      return null;
    } on Object {
      if (!ref.mounted) return null;
      state = const TripRequestFormState(failure: UnknownFailure());
      return null;
    }
  }
}
