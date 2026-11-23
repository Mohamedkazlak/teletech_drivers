import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/create_trip_request_result.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/group_suggestion.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_query.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_bucket.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// Repository: employee trip requests.
abstract interface class TripRequestRepository {
  /// Creates a request. Status, auto-approval and trip creation are decided
  /// server-side from the authenticated role.
  Future<CreateTripRequestResult> createRequest({
    required String employeeId,
    required String employeeName,
    required Branch employeeBranch,
    required String employeePhone,
    required String pickupPlaceId,
    required String pickupPlaceName,
    required String destinationPlaceId,
    required String destinationPlaceName,
    required DateTime requestedDateTime,
    required String notes,
    required TripRequestStatus status,
    required bool autoApproved,
    required String requesterRole,
    required bool createTrip,
    String? handledByUid,
    String? handledByName,
    double? pickupLat,
    double? pickupLng,
    String? pickupAddress,
    double? destinationLat,
    double? destinationLng,
    String? destinationAddress,
  });

  /// Observer: the employee's requests, newest [TripRequest.createdAt] first.
  Stream<List<TripRequest>> watchEmployeeRequests(String employeeId);

  /// Observer: own requests for one tab. Null [bucket] is the unfiltered list.
  Stream<List<TripRequest>> watchMyRequests({TripRequestListBucket? bucket});

  /// Observer: own requests with `awaiting_confirmation=true`.
  Stream<List<TripRequest>> watchAwaitingConfirmation();

  /// Files the trip report. Throws [ConflictFailure] when it is already closed.
  Future<TripRequest> confirmTrip({
    required String requestId,
    required bool driverShowedUp,
    String? note,
  });

  /// Observer: a single trip request by id (live).
  Stream<TripRequest?> watchRequestById(String requestId);

  /// Observer: pending requests for company admin, earliest requested time first.
  Stream<List<TripRequest>> watchPendingRequests();

  /// Observer: approved requests not yet linked to a trip (Drivers Admin).
  Stream<List<TripRequest>> watchApprovedAwaitingTripRequests();

  /// Observer: all requests for company admin filters.
  Stream<List<TripRequest>> watchAllRequests();

  /// Observer: requests for one admin tab. [TripRequestListQuery.branch] is
  /// sent as the `branch` query param and omitted when null.
  Stream<List<TripRequest>> watchRequests(TripRequestListQuery query);

  /// Loads requests by document id. Missing ids are skipped.
  Future<List<TripRequest>> getRequestsByIds(List<String> requestIds);

  /// Cancels an owned request while pending, or approved with no trip yet.
  Future<void> cancelPendingRequest({
    required String requestId,
    required String employeeId,
  });

  /// Company admin approves a pending request (transaction).
  Future<void> approvePendingRequest({
    required String requestId,
    required String handledByUid,
    required String handledByName,
  });

  /// Company admin approves several pending requests as one suggested group.
  ///
  /// Writes `status=approved` and the same [suggestedGroupId] in one transaction.
  Future<void> approvePendingRequestsAsGroup({
    required List<String> requestIds,
    required String suggestedGroupId,
    required String handledByUid,
    required String handledByName,
  });

  /// Company admin rejects a pending request with an optional reason (transaction).
  Future<void> rejectPendingRequest({
    required String requestId,
    required String handledByUid,
    required String handledByName,
    String? reason,
  });

  /// Grouping suggestions (clusters of >= 2 requests), joined with
  /// [knownRequests]. Clusters whose members are not all loaded are dropped.
  Future<List<GroupSuggestion>> getGroupingSuggestions({
    required List<TripRequest> knownRequests,
  });
}
