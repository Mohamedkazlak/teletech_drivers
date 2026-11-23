import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_requester.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_tracking.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// A company trip created from one or more employee requests.
class Trip extends Equatable {
  const Trip({
    required this.id,
    required this.requestIds,
    required this.passengerIds,
    required this.passengerNames,
    required this.passengerBranches,
    required this.pickupSummary,
    required this.destinationSummary,
    required this.scheduledAt,
    required this.status,
    required this.createdBy,
    required this.createdAt,
    this.driverId,
    this.goingStartedAt,
    this.goingEndedAt,
    this.returnStartedAt,
    this.finishedAt,
    this.startLat,
    this.startLng,
    this.goingDistanceMeters,
    this.returnDistanceMeters,
    this.totalDistanceMeters,
    this.goingRoute,
    this.returnRoute,
    this.confirmationStatus,
    this.driverShowedUp,
    this.requesters = const [],
    this.passengerCount = 0,
    this.tracking,
  });

  final String id;
  final String? driverId;
  final List<String> requestIds;
  final List<String> passengerIds;
  final List<String> passengerNames;

  /// Branch snapshot per passenger (parallel to [passengerNames]); empty on
  /// legacy trips that predate the field.
  final List<Branch?> passengerBranches;

  final String pickupSummary;
  final String destinationSummary;
  final DateTime scheduledAt;
  final TripStatus status;
  final String createdBy;
  final DateTime createdAt;
  final DateTime? goingStartedAt;
  final DateTime? goingEndedAt;
  final DateTime? returnStartedAt;
  final DateTime? finishedAt;

  /// Driver position recorded when Start trip was pressed.
  final double? startLat;
  final double? startLng;

  final double? goingDistanceMeters;
  final double? returnDistanceMeters;
  final double? totalDistanceMeters;
  final String? goingRoute;
  final String? returnRoute;

  /// Passenger report state. Null until the trip is completed.
  final TripConfirmationStatus? confirmationStatus;

  /// False when a passenger reported that the driver did not show.
  final bool? driverShowedUp;

  /// One entry per linked request. Grouped trips have more than one.
  /// The requester is `trip_requests.employee_id`, not [createdBy].
  final List<TripRequester> requesters;

  /// Server total of passenger rows across every request on this trip.
  final int passengerCount;

  /// Present when the signed-in user is a requester on this trip.
  final RequestTracking? tracking;

  /// Request id [userId] may confirm, when this finished trip is waiting on them.
  /// The requester is the passenger (`employee_id`), parallel to [requestIds].
  String? pendingReportRequestIdFor(String? userId) {
    if (userId == null || userId.isEmpty) return null;
    if (status != TripStatus.completed) return null;
    if (confirmationStatus != TripConfirmationStatus.pending) return null;
    final count = passengerIds.length < requestIds.length
        ? passengerIds.length
        : requestIds.length;
    for (var index = 0; index < count; index++) {
      if (passengerIds[index] == userId && requestIds[index].isNotEmpty) {
        return requestIds[index];
      }
    }
    return null;
  }

  bool get hasStartCoordinates =>
      startLat != null &&
      startLng != null &&
      startLat!.isFinite &&
      startLng!.isFinite;

  /// Legacy alias used by older admin UI for "when the trip began".
  DateTime? get startedAt => goingStartedAt;

  /// Legacy alias used by older admin UI for "when the trip finished".
  DateTime? get endedAt => finishedAt;

  /// Unique non-null branches on this trip (for chips / filters).
  List<Branch> get branches {
    final seen = <Branch>{};
    final ordered = <Branch>[];
    for (final branch in passengerBranches) {
      if (branch != null && seen.add(branch)) {
        ordered.add(branch);
      }
    }
    return ordered;
  }

  @override
  List<Object?> get props => [
    id,
    driverId,
    requestIds,
    passengerIds,
    passengerNames,
    passengerBranches,
    pickupSummary,
    destinationSummary,
    scheduledAt,
    status,
    createdBy,
    createdAt,
    goingStartedAt,
    goingEndedAt,
    returnStartedAt,
    finishedAt,
    startLat,
    startLng,
    goingDistanceMeters,
    returnDistanceMeters,
    totalDistanceMeters,
    goingRoute,
    returnRoute,
    confirmationStatus,
    driverShowedUp,
    requesters,
    passengerCount,
    tracking,
  ];
}
