import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// Filter chips for the company admin "My Requests" list.
enum MyRequestListFilter {
  all,
  active,
  completed,
  cancelledRejected;

  bool matches(TripRequest request, Trip? trip) {
    final isCancelledOrRejected =
        request.status == TripRequestStatus.cancelled ||
        request.status == TripRequestStatus.rejected ||
        trip?.status == TripStatus.cancelled;
    final isCompleted = trip?.status == TripStatus.completed;

    return switch (this) {
      MyRequestListFilter.all => true,
      MyRequestListFilter.completed => isCompleted,
      MyRequestListFilter.cancelledRejected => isCancelledOrRejected,
      MyRequestListFilter.active => !isCompleted && !isCancelledOrRejected,
    };
  }
}
