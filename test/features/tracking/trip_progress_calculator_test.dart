import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/trip_progress_calculator.dart';

void main() {
  late TripProgressCalculator calculator;

  setUp(() {
    calculator = TripProgressCalculator(arrivalRadiusMeters: 100);
  });

  final route = <RoutePoint>[
    const RoutePoint(24.7136, 46.6753),
    const RoutePoint(24.7200, 46.6800),
    const RoutePoint(24.7300, 46.6900),
    const RoutePoint(24.7400, 46.7000),
  ];

  test('on route near start reports low progress', () {
    final progress = calculator.calculate(
      polyline: route,
      position: route.first,
      target: route.last,
      routeDurationSeconds: 600,
    );
    expect(progress.percentComplete, closeTo(0, 0.05));
    expect(progress.distanceCoveredMeters, lessThan(50));
    expect(progress.arrived, isFalse);
  });

  test('on route near end reports high progress', () {
    final progress = calculator.calculate(
      polyline: route,
      position: route.last,
      target: route.last,
      routeDurationSeconds: 600,
    );
    expect(progress.percentComplete, greaterThan(0.9));
    expect(progress.arrived, isTrue);
  });

  test('off route still snaps and reports distance to route', () {
    calculator.reset();
    // ~5 km north of the route corridor.
    const off = RoutePoint(24.78, 46.68);
    final progress = calculator.calculate(
      polyline: route,
      position: off,
      target: route.last,
      routeDurationSeconds: 600,
    );
    expect(progress.distanceToRouteMeters, greaterThan(500));
    expect(progress.percentComplete, inInclusiveRange(0, 1));
  });

  test('percent is monotonic against GPS jitter backwards', () {
    final mid = route[1];
    final first = calculator.calculate(
      polyline: route,
      position: mid,
      target: route.last,
      routeDurationSeconds: 600,
    );
    final jitterBack = RoutePoint(mid.lat - 0.0003, mid.lng - 0.0003);
    final second = calculator.calculate(
      polyline: route,
      position: jitterBack,
      target: route.last,
      routeDurationSeconds: 600,
    );
    expect(second.percentComplete, greaterThanOrEqualTo(first.percentComplete));
  });

  test('arrival when within 100m of target', () {
    final near = RoutePoint(route.last.lat + 0.0005, route.last.lng);
    final progress = calculator.calculate(
      polyline: route,
      position: near,
      target: route.last,
      routeDurationSeconds: 120,
    );
    expect(progress.arrived, isTrue);
  });

  test('straight-line fallback uses remaining over initial', () {
    calculator.reset();
    final origin = const RoutePoint(24.71, 46.67);
    final target = const RoutePoint(24.75, 46.72);
    final start = calculator.calculate(
      polyline: [origin, target],
      position: origin,
      target: target,
      straightLineFallback: true,
    );
    expect(start.percentComplete, closeTo(0, 0.05));

    final mid = RoutePoint(
      (origin.lat + target.lat) / 2,
      (origin.lng + target.lng) / 2,
    );
    final halfway = calculator.calculate(
      polyline: [origin, target],
      position: mid,
      target: target,
      straightLineFallback: true,
    );
    expect(halfway.percentComplete, greaterThan(0.3));
    expect(halfway.percentComplete, lessThan(0.8));
  });

  test('splitPolyline returns covered and remaining parts', () {
    final (covered, remaining) = TripProgressCalculator.splitPolyline(
      polyline: route,
      distanceCoveredMeters: 500,
    );
    expect(covered.length, greaterThanOrEqualTo(2));
    expect(remaining.length, greaterThanOrEqualTo(1));
    expect(covered.last.lat, closeTo(remaining.first.lat, 0.0001));
  });
}
