import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/driver/presentation/controllers/driver_trip_lifecycle_controller.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_tracking_service.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/location_tracking_controller.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/location_tracking_service_provider.dart';
import 'package:teletech_drivers/features/tracking/presentation/state/location_tracking_state.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// Observer: resumes GPS after relaunch when a trip is still going/returning.
final resumeTrackingProvider = Provider.autoDispose<void>((ref) {
  final user = ref.watch(currentUserProvider).asData?.value;
  if (user == null) return;

  // Best-effort flush of phase finals that failed while offline.
  ref.listen(driverTripsProvider(user.id), (previous, next) {
    next.whenData((_) {
      ref
          .read(driverTripLifecycleControllerProvider.notifier)
          .retryPendingPhaseUploads();
    });
  });

  ref.listen(driverTripsProvider(user.id), (previous, next) {
    next.whenData((trips) async {
      final active = trips
          .where((trip) => trip.status.isActivelyTracking)
          .firstOrNull;
      if (active == null) return;

      final service = ref.read(locationTrackingServiceProvider);
      final controller = ref.read(locationTrackingControllerProvider.notifier);
      final tracking = ref.read(locationTrackingControllerProvider);

      if (controller.isStarting) return;
      if (tracking.isSharing && tracking.tripId == active.id) return;
      if (tracking.tripId == active.id &&
          tracking.status == LocationTrackingStatus.requestingPermission) {
        return;
      }

      final phase = active.status == TripStatus.returning
          ? TripTrackPhase.returning
          : TripTrackPhase.going;

      if (!service.isTracking || service.activeTripId != active.id) {
        try {
          await service.startTracking(tripId: active.id, phase: phase);
        } on Object {
          // Permission / services issues surface via the sharing banner.
        }
      }

      controller.start(active.id);
    });
  });
});
