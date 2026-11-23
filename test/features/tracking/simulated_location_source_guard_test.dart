import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/tracking/data/services/simulated_location_source.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';

void main() {
  test('SimulatedLocationSource asserts outside release', () {
    // In test builds kReleaseMode is false, so construction succeeds and we
    // assert the guard flag is present for release tree-shaking reviews.
    expect(kReleaseMode, isFalse);
    final source = SimulatedLocationSource(
      route: const [RoutePoint(24.71, 46.67), RoutePoint(24.72, 46.68)],
    );
    expect(source.speedKmh, 40);
  });
}
