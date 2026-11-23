import 'package:equatable/equatable.dart';

/// WGS84 point used by pure-Dart routing / progress math.
class RoutePoint extends Equatable {
  const RoutePoint(this.lat, this.lng);

  final double lat;
  final double lng;

  @override
  List<Object?> get props => [lat, lng];
}
