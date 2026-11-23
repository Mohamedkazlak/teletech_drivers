import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/company_admin/presentation/state/admin_action_state.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/approved_request_selection_controller.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/trip_grouping_strategy.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/utils/invalidate_trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/utils/invalidate_trip_request_providers.dart';

/// Dependency Injection: Riverpod.
final createTripsControllerProvider =
    NotifierProvider.autoDispose<CreateTripsController, AdminActionState>(
      CreateTripsController.new,
    );

class CreateTripsController extends Notifier<AdminActionState> {
  @override
  AdminActionState build() => const AdminActionState();

  /// Created trips, or null when the write failed or a write is already running.
  Future<List<Trip>?> create({
    required List<TripRequest> requests,
    required TripGroupingStrategy strategy,
    DateTime? scheduledAt,
  }) async {
    if (state.isLoading) return null;

    final user = ref.read(currentUserProvider).asData?.value;
    if (user == null) {
      state = const AdminActionState(failure: UnknownFailure());
      return null;
    }

    state = const AdminActionState(isLoading: true);
    try {
      final trips = await ref.read(createTripsFromRequestsUseCaseProvider)(
        requests: requests,
        strategy: strategy,
        createdBy: user.id,
        scheduledAt: scheduledAt,
      );
      if (!ref.mounted) return null;
      ref.read(approvedRequestSelectionProvider.notifier).clear();
      invalidateTripRequestProviders(ref);
      invalidateTripProviders(ref);
      state = const AdminActionState();
      return trips;
    } on Failure catch (failure) {
      if (!ref.mounted) return null;
      state = AdminActionState(failure: failure);
      return null;
    } on Object {
      if (!ref.mounted) return null;
      state = const AdminActionState(failure: UnknownFailure());
      return null;
    }
  }
}
