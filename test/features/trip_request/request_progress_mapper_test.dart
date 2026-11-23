import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_id.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_progress_step_state.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/mappers/request_progress_mapper.dart';

void main() {
  final createdAt = DateTime.utc(2026, 10, 1, 8);
  final handledAt = DateTime.utc(2026, 10, 1, 9);
  final goingStartedAt = DateTime.utc(2026, 10, 2, 10);
  final goingEndedAt = DateTime.utc(2026, 10, 2, 11);
  final returnStartedAt = DateTime.utc(2026, 10, 2, 12);
  final finishedAt = DateTime.utc(2026, 10, 2, 13);

  TripRequest request({
    TripRequestStatus status = TripRequestStatus.pending,
    bool autoApproved = false,
    String? tripId,
    String? rejectionReason,
    DateTime? handledAtOverride,
  }) {
    return TripRequest(
      id: 'req-1',
      employeeId: 'user-1',
      employeeName: 'Ada',
      pickupPlaceName: 'HQ',
      destinationPlaceName: 'Villa',
      requestedDateTime: createdAt.add(const Duration(hours: 2)),
      notes: '',
      status: status,
      createdAt: createdAt,
      autoApproved: autoApproved,
      tripId: tripId,
      rejectionReason: rejectionReason,
      handledAt: handledAtOverride,
    );
  }

  Trip trip({
    TripStatus status = TripStatus.unassigned,
    String? driverId,
    DateTime? goingStarted,
    DateTime? goingEnded,
    DateTime? returnStarted,
    DateTime? finished,
  }) {
    return Trip(
      id: 'trip-1',
      requestIds: const ['req-1'],
      passengerIds: const ['user-1'],
      passengerNames: const ['Ada'],
      passengerBranches: const [],
      pickupSummary: 'HQ',
      destinationSummary: 'Villa',
      scheduledAt: createdAt.add(const Duration(hours: 2)),
      status: status,
      createdBy: 'admin',
      createdAt: createdAt.add(const Duration(hours: 1)),
      driverId: driverId,
      goingStartedAt: goingStarted,
      goingEndedAt: goingEnded,
      returnStartedAt: returnStarted,
      finishedAt: finished,
    );
  }

  RequestProgressStepState stateAt(
    List<RequestProgressStep> steps,
    RequestProgressStepId id,
  ) {
    return steps.firstWhere((step) => step.id == id).state;
  }

  test('pending: Requested done, Approved current', () {
    final progress = RequestProgressMapper.map(request(), null);

    expect(progress.steps, hasLength(7));
    expect(
      stateAt(progress.steps, RequestProgressStepId.requested),
      RequestProgressStepState.done,
    );
    expect(
      stateAt(progress.steps, RequestProgressStepId.approved),
      RequestProgressStepState.current,
    );
    expect(
      stateAt(progress.steps, RequestProgressStepId.driverAssigned),
      RequestProgressStepState.pending,
    );
    expect(progress.currentStep?.id, RequestProgressStepId.approved);
  });

  test('auto-approved: Approved done, Driver assigned current', () {
    final progress = RequestProgressMapper.map(
      request(status: TripRequestStatus.approved, autoApproved: true),
      null,
    );

    expect(
      stateAt(progress.steps, RequestProgressStepId.approved),
      RequestProgressStepState.done,
    );
    expect(
      stateAt(progress.steps, RequestProgressStepId.driverAssigned),
      RequestProgressStepState.current,
    );
  });

  test('assigned: Driver assigned current, Going pending', () {
    final progress = RequestProgressMapper.map(
      request(
        status: TripRequestStatus.approved,
        autoApproved: true,
        tripId: 'trip-1',
      ),
      trip(status: TripStatus.assigned, driverId: 'driver-1'),
    );

    expect(
      stateAt(progress.steps, RequestProgressStepId.approved),
      RequestProgressStepState.done,
    );
    expect(
      stateAt(progress.steps, RequestProgressStepId.driverAssigned),
      RequestProgressStepState.current,
    );
    expect(
      stateAt(progress.steps, RequestProgressStepId.going),
      RequestProgressStepState.pending,
    );
  });

  test('going: Going current with timestamp', () {
    final progress = RequestProgressMapper.map(
      request(
        status: TripRequestStatus.approved,
        tripId: 'trip-1',
        handledAtOverride: handledAt,
      ),
      trip(status: TripStatus.going, driverId: 'd1', goingStarted: goingStartedAt),
    );

    expect(
      stateAt(progress.steps, RequestProgressStepId.driverAssigned),
      RequestProgressStepState.done,
    );
    expect(
      stateAt(progress.steps, RequestProgressStepId.going),
      RequestProgressStepState.current,
    );
    final going = progress.steps.firstWhere(
      (step) => step.id == RequestProgressStepId.going,
    );
    expect(going.at, goingStartedAt);
  });

  test('completed: all steps done', () {
    final progress = RequestProgressMapper.map(
      request(
        status: TripRequestStatus.approved,
        tripId: 'trip-1',
        handledAtOverride: handledAt,
      ),
      trip(
        status: TripStatus.completed,
        driverId: 'd1',
        goingStarted: goingStartedAt,
        goingEnded: goingEndedAt,
        returnStarted: returnStartedAt,
        finished: finishedAt,
      ),
    );

    for (final step in progress.steps) {
      expect(step.state, RequestProgressStepState.done, reason: '${step.id}');
    }
    expect(progress.currentStep, isNull);
    expect(
      progress.steps.lastWhere((s) => s.id == RequestProgressStepId.completed).at,
      finishedAt,
    );
  });

  test('rejected: ends at Approved failed with reason', () {
    final progress = RequestProgressMapper.map(
      request(
        status: TripRequestStatus.rejected,
        rejectionReason: 'No cars',
        handledAtOverride: handledAt,
      ),
      null,
    );

    expect(progress.steps, hasLength(2));
    expect(
      stateAt(progress.steps, RequestProgressStepId.requested),
      RequestProgressStepState.done,
    );
    final failed = progress.failedStep!;
    expect(failed.id, RequestProgressStepId.approved);
    expect(failed.state, RequestProgressStepState.failed);
    expect(failed.failureReason, 'No cars');
    expect(failed.at, handledAt);
  });

  test('cancelled: ends at Approved failed', () {
    final progress = RequestProgressMapper.map(
      request(status: TripRequestStatus.cancelled),
      null,
    );

    expect(progress.steps, hasLength(2));
    expect(
      stateAt(progress.steps, RequestProgressStepId.approved),
      RequestProgressStepState.failed,
    );
    expect(progress.failedStep?.id, RequestProgressStepId.approved);
  });

  test('manually approved unassigned: Approved is current', () {
    final progress = RequestProgressMapper.map(
      request(
        status: TripRequestStatus.approved,
        handledAtOverride: handledAt,
      ),
      trip(status: TripStatus.unassigned),
    );

    expect(
      stateAt(progress.steps, RequestProgressStepId.approved),
      RequestProgressStepState.current,
    );
    expect(
      stateAt(progress.steps, RequestProgressStepId.driverAssigned),
      RequestProgressStepState.pending,
    );
  });
}
