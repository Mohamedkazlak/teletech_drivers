import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/tracking/data/mappers/live_map_item_dto_mapper.dart';
import 'package:teletech_drivers/features/tracking/data/models/live_map_item_dto.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

import '../../support/api_fixtures.dart';

void main() {
  test('maps a fresh fix with a trip', () {
    final item = LiveMapItemDtoMapper.toEntity(
      LiveMapItemDto.fromJson(_json(stale: false)),
    );

    expect(item.isStale, isFalse);
    expect(item.isTracking, isTrue);
    expect(item.lat, 30.2);
    expect(item.lng, 31.3);
    expect(item.heading, 90);
    expect(item.speed, 12);
    expect(item.accuracy, 6);
    expect(item.updatedAt, DateTime.utc(2026, 11, 3, 8, 1));
    expect(item.driver.id, 'drv-1');
    expect(item.driver.role, UserRole.driver);
    expect(item.trip?.id, 'trip-1');
    expect(item.trip?.status, TripStatus.going);
    expect(item.trip?.pickupSummary, 'HQ');
    expect(item.trip?.scheduledAt, isNull);
    expect(item.trip?.goingStartedAt, isNull);
    expect(item.hasFix, isTrue);
  });

  test('maps scheduled_at and going_started_at as UTC', () {
    final json = _json(stale: false);
    final trip = json['trip'] as Map<String, dynamic>;
    trip['scheduled_at'] = '2026-11-03T08:00:00Z';
    trip['going_started_at'] = '2026-11-03T08:05:00Z';

    final item = LiveMapItemDtoMapper.toEntity(LiveMapItemDto.fromJson(json));
    expect(item.trip?.scheduledAt, DateTime.utc(2026, 11, 3, 8));
    expect(item.trip?.goingStartedAt, DateTime.utc(2026, 11, 3, 8, 5));
  });

  test('maps a stale row and a null trip without coordinates', () {
    final item = LiveMapItemDtoMapper.toEntity(
      LiveMapItemDto.fromJson(
        _json(stale: true, includeTrip: false, includeFix: false),
      ),
    );

    expect(item.isStale, isTrue);
    expect(item.trip, isNull);
    expect(item.lat, isNull);
    expect(item.lng, isNull);
    expect(item.updatedAt, isNull);
    expect(item.hasFix, isFalse);
    expect(item.driver.nameEn, 'Omar Driver');
  });
}

Map<String, dynamic> liveMapJson({
  bool stale = false,
  bool includeTrip = true,
  bool includeFix = true,
}) {
  return {
    'driver': ApiFixtures.user(),
    'trip': includeTrip
        ? {
            'id': 'trip-1',
            'status': 'going',
            'pickup_summary': 'HQ',
            'destination_summary': 'Airport',
          }
        : null,
    'lat': includeFix ? 30.2 : null,
    'lng': includeFix ? 31.3 : null,
    'heading': includeFix ? 90 : null,
    'speed': includeFix ? 12 : null,
    'accuracy': includeFix ? 6 : null,
    'updated_at': includeFix ? '2026-11-03T08:01:00Z' : null,
    'is_stale': stale,
    'is_tracking': includeFix,
  };
}

Map<String, dynamic> _json({
  required bool stale,
  bool includeTrip = true,
  bool includeFix = true,
}) {
  return liveMapJson(
    stale: stale,
    includeTrip: includeTrip,
    includeFix: includeFix,
  );
}
