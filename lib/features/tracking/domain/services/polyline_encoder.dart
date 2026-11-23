import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';

/// Google Encoded Polyline Algorithm Format (precision 5).
///
/// Encodes routes as compact strings so stored paths stay small.
abstract final class PolylineEncoder {
  static const int precision = 5;

  static String encode(List<RoutePoint> points) {
    if (points.isEmpty) return '';

    final buffer = StringBuffer();
    var prevLat = 0;
    var prevLng = 0;
    final factor = _pow10(precision);

    for (final point in points) {
      final lat = (point.lat * factor).round();
      final lng = (point.lng * factor).round();
      _encodeSigned(lat - prevLat, buffer);
      _encodeSigned(lng - prevLng, buffer);
      prevLat = lat;
      prevLng = lng;
    }
    return buffer.toString();
  }

  static List<RoutePoint> decode(String encoded) {
    if (encoded.isEmpty) return const [];

    final points = <RoutePoint>[];
    var index = 0;
    var lat = 0;
    var lng = 0;
    final factor = _pow10(precision).toDouble();

    while (index < encoded.length) {
      final latResult = _decodeSigned(encoded, index);
      index = latResult.$2;
      lat += latResult.$1;

      final lngResult = _decodeSigned(encoded, index);
      index = lngResult.$2;
      lng += lngResult.$1;

      points.add(RoutePoint(lat / factor, lng / factor));
    }
    return points;
  }

  static void _encodeSigned(int value, StringBuffer buffer) {
    var v = value < 0 ? ~(value << 1) : (value << 1);
    while (v >= 0x20) {
      buffer.writeCharCode(((0x20 | (v & 0x1f)) + 63));
      v >>= 5;
    }
    buffer.writeCharCode(v + 63);
  }

  static (int value, int nextIndex) _decodeSigned(String encoded, int index) {
    var result = 0;
    var shift = 0;
    var current = index;

    while (current < encoded.length) {
      final b = encoded.codeUnitAt(current++) - 63;
      result |= (b & 0x1f) << shift;
      shift += 5;
      if (b < 0x20) break;
    }

    final value = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
    return (value, current);
  }

  static int _pow10(int exp) {
    var result = 1;
    for (var i = 0; i < exp; i++) {
      result *= 10;
    }
    return result;
  }
}
