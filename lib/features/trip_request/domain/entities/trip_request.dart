import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/linked_trip.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_tracking.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// An employee's request for a company trip.
class TripRequest extends Equatable {
  const TripRequest({
    required this.id,
    required this.employeeId,
    required this.employeeName,
    required this.pickupPlaceName,
    required this.destinationPlaceName,
    required this.requestedDateTime,
    required this.notes,
    required this.status,
    required this.createdAt,
    this.pickupPlaceId,
    this.destinationPlaceId,
    this.pickupLat,
    this.pickupLng,
    this.pickupAddress,
    this.destinationLat,
    this.destinationLng,
    this.destinationAddress,
    this.employeeBranch,
    this.employeePhone,
    this.tripId,
    this.rejectionReason,
    this.handledByUid,
    this.handledByName,
    this.handledAt,
    this.autoApproved = false,
    this.requesterRole,
    this.suggestedGroupId,
    this.linkedTrip,
    this.tracking,
  });

  final String id;
  final String employeeId;
  final String employeeName;

  /// Snapshot of the requester's branch at request time (null on legacy docs).
  final Branch? employeeBranch;

  /// Snapshot of the requester's phone at request time (null on legacy docs).
  final String? employeePhone;

  /// True when company/drivers admin self-requested (false on legacy docs).
  final bool autoApproved;

  /// [UserRole.name] of the requester at create time (null on legacy docs).
  final String? requesterRole;

  /// Shared id when company admin approved requests as a suggested group.
  final String? suggestedGroupId;

  /// Approved place id; null for legacy free-text requests.
  final String? pickupPlaceId;

  /// Place name snapshot (or legacy free-text pickup).
  final String pickupPlaceName;

  /// Optional pickup coordinates (custom / map picks; null on legacy docs).
  final double? pickupLat;
  final double? pickupLng;
  final String? pickupAddress;

  /// Approved place id; null for legacy free-text requests.
  final String? destinationPlaceId;

  /// Place name snapshot (or legacy free-text destination).
  final String destinationPlaceName;

  /// Optional destination coordinates (custom / map picks; null on legacy docs).
  final double? destinationLat;
  final double? destinationLng;
  final String? destinationAddress;

  bool get hasCustomPickupLocation =>
      pickupLat != null &&
      pickupLng != null &&
      (pickupPlaceId == null || pickupPlaceId!.startsWith('custom:'));

  bool get hasCustomDestinationLocation =>
      destinationLat != null &&
      destinationLng != null &&
      (destinationPlaceId == null ||
          destinationPlaceId!.startsWith('custom:'));

  final DateTime requestedDateTime;
  final String notes;
  final TripRequestStatus status;
  final String? tripId;
  final String? rejectionReason;
  final String? handledByUid;
  final String? handledByName;
  final DateTime? handledAt;
  final DateTime createdAt;

  /// Assigned trip summary from the request resource. Null when unlinked.
  final LinkedTrip? linkedTrip;

  /// Server-derived lifecycle. Null only when an older payload omits it.
  final RequestTracking? tracking;

  /// Pending, or approved and not yet linked to a trip (unassigned).
  bool get canCancel =>
      status == TripRequestStatus.pending || isAwaitingTrip;

  /// Approved and not yet linked to a trip (Drivers Admin queue).
  bool get isAwaitingTrip =>
      status == TripRequestStatus.approved && tripId == null;

  /// Self-request from company / drivers / system admin (chip in admin queues).
  bool get isAdminRequest =>
      autoApproved ||
      requesterRole == 'companyAdmin' ||
      requesterRole == 'driversAdmin' ||
      requesterRole == 'admin';

  @override
  List<Object?> get props => [
    id,
    employeeId,
    employeeName,
    employeeBranch,
    employeePhone,
    pickupPlaceId,
    pickupPlaceName,
    pickupLat,
    pickupLng,
    pickupAddress,
    destinationPlaceId,
    destinationPlaceName,
    destinationLat,
    destinationLng,
    destinationAddress,
    requestedDateTime,
    notes,
    status,
    tripId,
    rejectionReason,
    handledByUid,
    handledByName,
    handledAt,
    autoApproved,
    requesterRole,
    suggestedGroupId,
    createdAt,
    linkedTrip,
    tracking,
  ];
}
