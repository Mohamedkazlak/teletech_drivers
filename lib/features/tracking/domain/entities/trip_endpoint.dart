import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';

/// Resolved From / To point for the live map (display only).
class TripEndpoint extends Equatable {
  const TripEndpoint({
    required this.name,
    this.point,
    this.isApproximate = false,
    this.isDriverFallback = false,
  });

  final String name;
  final RoutePoint? point;
  final bool isApproximate;
  final bool isDriverFallback;

  bool get hasPoint => point != null;

  @override
  List<Object?> get props => [name, point, isApproximate, isDriverFallback];
}

/// Pair of endpoints for the current trip leg.
class TripEndpoints extends Equatable {
  const TripEndpoints({
    required this.from,
    required this.to,
  });

  final TripEndpoint from;
  final TripEndpoint to;

  @override
  List<Object?> get props => [from, to];
}

enum TripLeg { going, returning }
