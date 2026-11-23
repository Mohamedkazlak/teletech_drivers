import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/driving_route.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/trip_endpoint.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/trip_progress.dart';

enum TripBootstrapStep {
  gettingLocation,
  loadingLocations,
  preparingRoute,
  sharingLocation,
  done,
}

/// State: live-map navigation for one active trip.
class TripNavigationState extends Equatable {
  const TripNavigationState({
    this.bootstrapStep = TripBootstrapStep.gettingLocation,
    this.completedBootstrap = const {},
    this.leg = TripLeg.going,
    this.endpoints,
    this.route,
    this.progress,
    this.travelledPoints = const [],
    this.waitingForGps = false,
    this.locatingPosition = false,
    this.positionTimedOut = false,
    this.bootstrapping = true,
    this.fetchingRoute = false,
    this.simulating = false,
    this.simulateSpeedKmh = 40,
    this.simulatePaused = false,
  });

  final TripBootstrapStep bootstrapStep;
  final Set<TripBootstrapStep> completedBootstrap;
  final TripLeg leg;
  final TripEndpoints? endpoints;
  final DrivingRoute? route;
  final TripProgress? progress;

  /// Actual GPS trail from [LocationTrackingService] for the active phase.
  final List<RoutePoint> travelledPoints;

  final bool waitingForGps;
  final bool locatingPosition;
  final bool positionTimedOut;
  final bool bootstrapping;
  final bool fetchingRoute;
  final bool simulating;
  final double simulateSpeedKmh;
  final bool simulatePaused;

  bool get arrived => progress?.arrived ?? false;

  bool get isApproximateRoute => route?.isApproximate ?? false;

  bool get isReturning => leg == TripLeg.returning;

  TripNavigationState copyWith({
    TripBootstrapStep? bootstrapStep,
    Set<TripBootstrapStep>? completedBootstrap,
    TripLeg? leg,
    TripEndpoints? endpoints,
    DrivingRoute? route,
    TripProgress? progress,
    List<RoutePoint>? travelledPoints,
    bool? waitingForGps,
    bool? locatingPosition,
    bool? positionTimedOut,
    bool? bootstrapping,
    bool? fetchingRoute,
    bool? simulating,
    double? simulateSpeedKmh,
    bool? simulatePaused,
    bool clearRoute = false,
    bool clearProgress = false,
    bool clearEndpoints = false,
  }) {
    return TripNavigationState(
      bootstrapStep: bootstrapStep ?? this.bootstrapStep,
      completedBootstrap: completedBootstrap ?? this.completedBootstrap,
      leg: leg ?? this.leg,
      endpoints: clearEndpoints ? null : (endpoints ?? this.endpoints),
      route: clearRoute ? null : (route ?? this.route),
      progress: clearProgress ? null : (progress ?? this.progress),
      travelledPoints: travelledPoints ?? this.travelledPoints,
      waitingForGps: waitingForGps ?? this.waitingForGps,
      locatingPosition: locatingPosition ?? this.locatingPosition,
      positionTimedOut: positionTimedOut ?? this.positionTimedOut,
      bootstrapping: bootstrapping ?? this.bootstrapping,
      fetchingRoute: fetchingRoute ?? this.fetchingRoute,
      simulating: simulating ?? this.simulating,
      simulateSpeedKmh: simulateSpeedKmh ?? this.simulateSpeedKmh,
      simulatePaused: simulatePaused ?? this.simulatePaused,
    );
  }

  @override
  List<Object?> get props => [
    bootstrapStep,
    completedBootstrap,
    leg,
    endpoints,
    route,
    progress,
    travelledPoints,
    waitingForGps,
    locatingPosition,
    positionTimedOut,
    bootstrapping,
    fetchingRoute,
    simulating,
    simulateSpeedKmh,
    simulatePaused,
  ];
}
