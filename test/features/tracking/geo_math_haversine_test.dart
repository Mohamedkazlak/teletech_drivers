import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/geo_math.dart';

void main() {
  group('GeoMath.distanceMeters (Haversine)', () {
    test('returns ~0 for identical points', () {
      const point = RoutePoint(24.7136, 46.6753);
      expect(GeoMath.distanceMeters(point, point), closeTo(0, 0.01));
    });

    test('computes ~111.2 km for 1 degree of latitude', () {
      const a = RoutePoint(0, 0);
      const b = RoutePoint(1, 0);
      expect(GeoMath.distanceMeters(a, b), closeTo(111195, 50));
    });

    test('is symmetric', () {
      const a = RoutePoint(24.7, 46.6);
      const b = RoutePoint(24.75, 46.65);
      expect(
        GeoMath.distanceMeters(a, b),
        closeTo(GeoMath.distanceMeters(b, a), 0.001),
      );
    });
  });
}
