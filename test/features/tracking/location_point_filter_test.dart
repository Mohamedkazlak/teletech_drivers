import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/tracked_location_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/location_point_filter.dart';

void main() {
  const filter = LocationPointFilter();

  TrackedLocationPoint point({
    double lat = 24.7136,
    double lng = 46.6753,
    double accuracy = 10,
    DateTime? timestamp,
  }) {
    return TrackedLocationPoint(
      lat: lat,
      lng: lng,
      accuracyMeters: accuracy,
      speedMps: 0,
      headingDegrees: 0,
      timestamp: timestamp ?? DateTime.utc(2026, 1, 1, 12),
    );
  }

  group('LocationPointFilter', () {
    test('accepts the first point', () {
      expect(filter.shouldAccept(point()), isTrue);
    });

    test('drops accuracy worse than 30 m', () {
      expect(
        filter.shouldAccept(point(accuracy: 31), lastAccepted: point()),
        isFalse,
      );
    });

    test('drops points closer than 5 m', () {
      final last = point();
      // ~1 m north
      final next = point(lat: 24.713609, timestamp: DateTime.utc(2026, 1, 1, 12, 0, 1));
      expect(filter.shouldAccept(next, lastAccepted: last), isFalse);
    });

    test('accepts points far enough with good accuracy', () {
      final last = point();
      // ~50 m north
      final next = point(
        lat: 24.71405,
        timestamp: DateTime.utc(2026, 1, 1, 12, 0, 10),
      );
      expect(filter.shouldAccept(next, lastAccepted: last), isTrue);
    });

    test('drops impossible jumps over 55 m/s', () {
      final last = point();
      // ~1 km north in 1 second => ~1000 m/s
      final next = point(
        lat: 24.7226,
        timestamp: DateTime.utc(2026, 1, 1, 12, 0, 1),
      );
      expect(filter.shouldAccept(next, lastAccepted: last), isFalse);
    });
  });
}
