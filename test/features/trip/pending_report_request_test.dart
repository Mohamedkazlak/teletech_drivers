import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

void main() {
  test('only the requester of a pending finished trip can confirm', () {
    final trip = _trip(
      status: TripStatus.completed,
      confirmation: TripConfirmationStatus.pending,
      passengerIds: const ['owner', 'other'],
      requestIds: const ['req-owner', 'req-other'],
    );

    expect(trip.pendingReportRequestIdFor('owner'), 'req-owner');
    expect(trip.pendingReportRequestIdFor('other'), 'req-other');
    expect(trip.pendingReportRequestIdFor('stranger'), isNull);
    expect(trip.pendingReportRequestIdFor(null), isNull);
    expect(trip.pendingReportRequestIdFor(''), isNull);
  });

  test('a confirmed or unfinished trip has no report to file', () {
    final confirmed = _trip(
      status: TripStatus.completed,
      confirmation: TripConfirmationStatus.confirmed,
    );
    final going = _trip(
      status: TripStatus.going,
      confirmation: TripConfirmationStatus.pending,
    );

    expect(confirmed.pendingReportRequestIdFor('owner'), isNull);
    expect(going.pendingReportRequestIdFor('owner'), isNull);
  });
}

Trip _trip({
  required TripStatus status,
  required TripConfirmationStatus confirmation,
  List<String> passengerIds = const ['owner'],
  List<String> requestIds = const ['req-owner'],
}) {
  return Trip(
    id: 'trip-1',
    requestIds: requestIds,
    passengerIds: passengerIds,
    passengerNames: const ['Owner'],
    passengerBranches: const [],
    pickupSummary: 'HQ',
    destinationSummary: 'Site',
    scheduledAt: DateTime.utc(2026, 11, 10),
    status: status,
    createdBy: 'admin',
    createdAt: DateTime.utc(2026, 11, 1),
    confirmationStatus: confirmation,
  );
}
