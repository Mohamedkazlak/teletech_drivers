import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_id.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_state.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// Pure function: maps a [TripRequest] + optional [Trip] to a progress timeline.
///
/// Pattern: Mapper (domain).
abstract final class RequestProgressMapper {
  static const _orderedIds = RequestProgressStepId.values;

  /// Builds an ordered list of steps with done / current / pending / failed.
  static RequestProgress map(TripRequest request, Trip? trip) {
    if (request.status == TripRequestStatus.rejected) {
      return _terminalFailed(
        request: request,
        failedId: RequestProgressStepId.approved,
        reason: request.rejectionReason,
        failedAt: request.handledAt,
      );
    }

    if (request.status == TripRequestStatus.cancelled) {
      return _terminalFailed(
        request: request,
        failedId: RequestProgressStepId.approved,
        reason: request.rejectionReason,
        failedAt: request.handledAt ?? request.createdAt,
      );
    }

    if (trip?.status == TripStatus.cancelled) {
      return _terminalFailed(
        request: request,
        failedId: RequestProgressStepId.driverAssigned,
        reason: null,
        failedAt: trip?.finishedAt,
        trip: trip,
      );
    }

    final currentId = _currentStepId(request, trip);
    return RequestProgress(
      steps: [
        for (final id in _orderedIds)
          RequestProgressStep(
            id: id,
            state: _stateFor(id: id, currentId: currentId),
            at: _timestampFor(id: id, request: request, trip: trip),
          ),
      ],
    );
  }

  static RequestProgressStepId _currentStepId(TripRequest request, Trip? trip) {
    final status = trip?.status;

    if (status == TripStatus.completed) {
      return RequestProgressStepId.completed;
    }
    if (status == TripStatus.returning) {
      return RequestProgressStepId.returning;
    }
    if (status == TripStatus.atDestination) {
      return RequestProgressStepId.arrived;
    }
    if (status == TripStatus.going) {
      return RequestProgressStepId.going;
    }
    if (status == TripStatus.assigned) {
      return RequestProgressStepId.driverAssigned;
    }

    // No trip, or trip still unassigned.
    if (request.status == TripRequestStatus.pending) {
      return RequestProgressStepId.approved;
    }

    // autoApproved: Approved is done immediately → Driver assigned is current.
    if (request.autoApproved) {
      return RequestProgressStepId.driverAssigned;
    }

    // Manually approved, awaiting trip / assignment → Approved is current.
    return RequestProgressStepId.approved;
  }

  static RequestProgressStepState _stateFor({
    required RequestProgressStepId id,
    required RequestProgressStepId currentId,
  }) {
    final index = id.index;
    final currentIndex = currentId.index;

    if (currentId == RequestProgressStepId.completed &&
        id == RequestProgressStepId.completed) {
      return RequestProgressStepState.done;
    }
    if (index < currentIndex) return RequestProgressStepState.done;
    if (index == currentIndex) return RequestProgressStepState.current;
    return RequestProgressStepState.pending;
  }

  static DateTime? _timestampFor({
    required RequestProgressStepId id,
    required TripRequest request,
    required Trip? trip,
  }) {
    return switch (id) {
      RequestProgressStepId.requested => request.createdAt,
      RequestProgressStepId.approved =>
        request.handledAt ??
            (request.autoApproved || request.status != TripRequestStatus.pending
                ? request.createdAt
                : null),
      // No assignedAt field on Trip; leave null until phase timestamps exist.
      RequestProgressStepId.driverAssigned => null,
      RequestProgressStepId.going => trip?.goingStartedAt,
      RequestProgressStepId.arrived => trip?.goingEndedAt,
      RequestProgressStepId.returning => trip?.returnStartedAt,
      RequestProgressStepId.completed => trip?.finishedAt,
    };
  }

  static RequestProgress _terminalFailed({
    required TripRequest request,
    required RequestProgressStepId failedId,
    required String? reason,
    required DateTime? failedAt,
    Trip? trip,
  }) {
    final failedIndex = failedId.index;
    return RequestProgress(
      steps: [
        for (final id in _orderedIds)
          if (id.index <= failedIndex)
            RequestProgressStep(
              id: id,
              state: id == failedId
                  ? RequestProgressStepState.failed
                  : RequestProgressStepState.done,
              at: id == failedId
                  ? failedAt
                  : _timestampFor(id: id, request: request, trip: trip),
              failureReason: id == failedId ? reason : null,
            ),
      ],
    );
  }
}
