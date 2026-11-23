import 'package:flutter_test/flutter_test.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/polyline_encoder.dart';

void main() {
  test('PolylineEncoder round-trips points at precision 5', () {
    const points = [
      RoutePoint(38.5, -120.2),
      RoutePoint(40.7, -120.95),
      RoutePoint(43.252, -126.453),
    ];
    final encoded = PolylineEncoder.encode(points);
    expect(encoded, isNotEmpty);
    final decoded = PolylineEncoder.decode(encoded);
    expect(decoded.length, points.length);
    for (var i = 0; i < points.length; i++) {
      expect(decoded[i].lat, closeTo(points[i].lat, 0.00001));
      expect(decoded[i].lng, closeTo(points[i].lng, 0.00001));
    }
  });
}
