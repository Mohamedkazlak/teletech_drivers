import 'package:teletech_drivers/core/network/paginated_response.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip/data/models/driver_recommendation_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_dto.dart';
import 'package:teletech_drivers/features/trip/data/models/trip_report_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_lifecycle.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_stage.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

/// Remote access to trips (Laravel API).
abstract interface class TripRemoteDataSource {
  Future<List<TripDto>> listTrips({
    TripStatus? status,
    String? driverId,
    TripStage? stage,
    Branch? branch,
    TripLifecycle? lifecycle,
  });

  /// One page of trips created by the signed-in user.
  Future<PaginatedResponse<TripDto>> listCreatedByMe({
    required CreatedTripBucket bucket,
    required int page,
  });

  Future<List<TripDto>> listMyTrips({
    TripStatus? status,
    String? statusFilter,
    String? period,
    String? date,
  });

  Future<TripDto> getTrip(String tripId);

  Future<List<TripDto>> createFromRequests({
    required String mode,
    required List<String> requestIds,
    DateTime? scheduledAt,
  });

  Future<TripDto> assign({required String tripId, required String driverId});

  Future<TripDto> cancel(String tripId);

  Future<TripDto> start({
    required String tripId,
    required double startLat,
    required double startLng,
  });

  Future<TripDto> arrive({
    required String tripId,
    required double goingDistanceM,
    required String goingRoute,
  });

  Future<TripDto> startReturn(String tripId);

  Future<TripDto> end({
    required String tripId,
    required double returnDistanceM,
    required String returnRoute,
  });

  Future<TripReportDto> getReport(String tripId);

  Future<List<DriverRecommendationDto>> getDriverRecommendations(String tripId);
}
