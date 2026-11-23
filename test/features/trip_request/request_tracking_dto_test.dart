import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/trip_request/data/models/request_tracking_dto.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/request_tracking.dart';

void main() {
  test('parses a submitted request with no driver', () {
    final tracking = RequestTrackingDto.fromJson({
      'stage': 'submitted',
      'timeline': [
        {
          'stage': 'submitted',
          'reached_at': '2026-11-02T10:00:00Z',
          'actor_role': 'employee',
        },
        {
          'stage': 'approved',
          'reached_at': null,
          'actor_role': 'company_admin',
        },
      ],
      'rejection_reason': null,
      'driver': null,
      'scheduled_at': null,
      'vehicle': null,
    }).toEntity();

    expect(tracking.stage, RequestTrackingStage.submitted);
    expect(tracking.isApproved, isFalse);
    expect(tracking.isDriverAssigned, isFalse);
    expect(tracking.driver, isNull);
    expect(tracking.vehicle, isNull);
    expect(
      tracking.eventFor(RequestTrackingStage.submitted)?.actorRole,
      UserRole.employee,
    );
    expect(
      tracking.eventFor(RequestTrackingStage.approved)?.reachedAt,
      isNull,
    );
  });

  test('parses an assigned driver, plate, and schedule', () {
    final tracking = RequestTrackingDto.fromJson({
      'stage': 'driver_assigned',
      'timeline': [
        {
          'stage': 'driver_assigned',
          'reached_at': '2026-11-03T09:00:00Z',
          'actor_role': 'drivers_admin',
        },
      ],
      'driver': {
        'name_en': 'Nader Hassan',
        'name_ar': 'نادر حسن',
        'phone': '01099998888',
      },
      'scheduled_at': '2026-11-04T08:00:00Z',
      'vehicle': {'car_license': 'PLATE-9'},
    }).toEntity();

    expect(tracking.stage, RequestTrackingStage.driverAssigned);
    expect(tracking.driver?.nameEn, 'Nader Hassan');
    expect(tracking.driver?.phone, '01099998888');
    expect(tracking.driver?.localizedName('ar'), 'نادر حسن');
    expect(tracking.scheduledAt, DateTime.utc(2026, 11, 4, 8));
    expect(tracking.vehicle?.carLicense, 'PLATE-9');
  });

  test('parses a rejection reason and hides a missing vehicle', () {
    final tracking = RequestTrackingDto.fromJson({
      'stage': 'rejected',
      'timeline': [
        {'stage': 'rejected', 'reached_at': '2026-11-02T12:00:00Z'},
      ],
      'rejection_reason': 'No cars that day',
    }).toEntity();

    expect(tracking.stage, RequestTrackingStage.rejected);
    expect(tracking.rejectionReason, 'No cars that day');
    expect(tracking.eventFor(RequestTrackingStage.rejected)?.actorRole, isNull);
  });

  test('rejects an unknown stage', () {
    expect(
      () => RequestTrackingDto.fromJson({
        'stage': 'mystery',
        'timeline': <Map<String, dynamic>>[],
      }),
      throwsFormatException,
    );
  });
}
