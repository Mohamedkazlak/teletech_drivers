import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/driver/presentation/controllers/driver_trip_lifecycle_controller.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/location_tracking_controller.dart';
import 'package:teletech_drivers/features/tracking/presentation/controllers/trip_navigation_controller.dart';
import 'package:teletech_drivers/features/tracking/presentation/state/location_tracking_state.dart';
import 'package:teletech_drivers/features/tracking/presentation/state/trip_navigation_state.dart';
import 'package:teletech_drivers/features/tracking/presentation/widgets/dev_tools_sheet.dart';
import 'package:teletech_drivers/features/tracking/presentation/widgets/driver_position_marker.dart';
import 'package:teletech_drivers/features/tracking/presentation/utils/location_sharing_message.dart';
import 'package:teletech_drivers/features/tracking/presentation/widgets/osm_map_layer.dart';
import 'package:teletech_drivers/features/tracking/presentation/widgets/tracking_status_chip.dart';
import 'package:teletech_drivers/features/trip/domain/controllers/trip_phase_controller.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_requester.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_requesters_section.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';

/// Going planned-route color (TeleTech deep blue).
const Color _goingRouteColor = AppColors.deepBlue;

/// Returning planned-route color (distinct warm accent).
const Color _returningRouteColor = Color(0xFFC45C26);

/// Actual GPS trail already travelled this phase.
const Color _travelledRouteColor = AppColors.success;

/// Uber-like live map for the assigned driver during an active trip.
class DriverLiveMapScreen extends ConsumerStatefulWidget {
  const DriverLiveMapScreen({required this.tripId, super.key});

  final String tripId;

  @override
  ConsumerState<DriverLiveMapScreen> createState() =>
      _DriverLiveMapScreenState();
}

class _DriverLiveMapScreenState extends ConsumerState<DriverLiveMapScreen>
    with SingleTickerProviderStateMixin {
  late final MapController _mapController;
  late final AnimationController _moveController;
  var _followDriver = true;
  var _didFitCamera = false;
  LatLng? _fromPoint;
  LatLng? _toPoint;
  double _fromHeading = 0;
  double _toHeading = 0;
  double _animatedHeading = 0;
  LatLng? _animatedPoint;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _moveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..addListener(_onMoveTick);
  }

  @override
  void dispose() {
    _moveController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  void _onMoveTick() {
    final from = _fromPoint;
    final to = _toPoint;
    if (from == null || to == null) return;
    final t = Curves.easeOutCubic.transform(_moveController.value);
    setState(() {
      _animatedPoint = LatLng(
        from.latitude + (to.latitude - from.latitude) * t,
        from.longitude + (to.longitude - from.longitude) * t,
      );
      _animatedHeading = _fromHeading + (_toHeading - _fromHeading) * t;
    });
    if (_followDriver && _animatedPoint != null) {
      _mapController.move(_animatedPoint!, _mapController.camera.zoom);
    }
  }

  void _pushPosition(LatLng next, double heading) {
    final current = _animatedPoint ?? next;
    _fromPoint = current;
    _toPoint = next;
    _fromHeading = _animatedHeading;
    _toHeading = heading.isNaN ? _animatedHeading : heading;
    if (MediaQuery.disableAnimationsOf(context)) {
      setState(() {
        _animatedPoint = next;
        _animatedHeading = _toHeading;
      });
      if (_followDriver) {
        _mapController.move(next, _mapController.camera.zoom);
      }
      return;
    }
    _moveController.forward(from: 0);
  }

  Future<void> _fixPermission() async {
    await ref.read(locationTrackingControllerProvider.notifier).fixSharing();
  }

  void _fitDriverAndTarget({required LatLng? driver, required LatLng? target}) {
    if (_didFitCamera) return;
    if (driver == null && target == null) return;
    _didFitCamera = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (driver != null && target != null) {
        final bounds = LatLngBounds.fromPoints([driver, target]);
        _mapController.fitCamera(
          CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(72)),
        );
      } else {
        _mapController.move(driver ?? target!, 15);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final tripAsync = ref.watch(watchTripByIdProvider(widget.tripId));
    final tracking = ref.watch(locationTrackingControllerProvider);
    final nav = ref.watch(tripNavigationControllerProvider(widget.tripId));
    final actionState = ref.watch(driverTripLifecycleControllerProvider);

    ref.listen(locationTrackingControllerProvider, (previous, next) {
      final position = next.position;
      if (position == null) return;
      final point = LatLng(position.latitude, position.longitude);
      if (previous?.position?.latitude == position.latitude &&
          previous?.position?.longitude == position.longitude) {
        return;
      }
      _pushPosition(point, position.heading);
      ref
          .read(tripNavigationControllerProvider(widget.tripId).notifier)
          .onPosition(position);
    });

    ref.listen(watchTripByIdProvider(widget.tripId), (previous, next) {
      final trip = next.asData?.value;
      if (trip == null) return;
      if (previous?.asData?.value?.id == trip.id &&
          previous?.asData?.value?.status == trip.status) {
        if (previous?.asData?.value == null) {
          unawaitedBootstrap(trip, languageCode);
        }
        return;
      }
      unawaitedBootstrap(trip, languageCode);
    });

    tripAsync.whenData((trip) {
      if (trip != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          unawaitedBootstrap(trip, languageCode);
        });
      }
    });

    return AppScaffold(
      title: l10n.liveMapTitle,
      showBackButton: true,
      onLogoLongPress: kDebugMode
          ? () => showDevToolsSheet(
              context: context,
              ref: ref,
              tripId: widget.tripId,
            )
          : null,
      body: tripAsync.when(
        loading: () => Center(child: AppLoadingIndicator(label: l10n.loading)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              messageForError(error, l10n),
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (trip) {
          if (trip == null) {
            return Center(child: Text(l10n.errorNotFound));
          }
          return _buildMap(
            context,
            trip: trip,
            tracking: tracking,
            nav: nav,
            isActionLoading:
                actionState.isLoading && actionState.activeTripId == trip.id,
          );
        },
      ),
    );
  }

  void unawaitedBootstrap(Trip trip, String languageCode) {
    ref
        .read(tripNavigationControllerProvider(widget.tripId).notifier)
        .bootstrap(trip, languageCode: languageCode);
  }

  Widget _buildMap(
    BuildContext context, {
    required Trip trip,
    required LocationTrackingState tracking,
    required TripNavigationState nav,
    required bool isActionLoading,
  }) {
    final l10n = AppLocalizations.of(context);

    final driverPoint =
        _animatedPoint ??
        (tracking.position == null
            ? null
            : LatLng(
                tracking.position!.latitude,
                tracking.position!.longitude,
              ));
    final accuracy = tracking.position?.accuracy ?? 20;

    final toEndpoint = nav.endpoints?.to;
    final toLatLng = _toLatLng(toEndpoint?.point);

    _fitDriverAndTarget(driver: driverPoint, target: toLatLng);

    final route = nav.route;
    final progress = nav.progress;
    final plannedPoints = route == null
        ? const <LatLng>[]
        : route.points.map(_toLatLngRequired).toList();
    final travelledPoints = nav.travelledPoints.map(_toLatLngRequired).toList();
    final onReturnLeg = trip.status == TripStatus.returning || nav.isReturning;
    final plannedColor = onReturnLeg ? _returningRouteColor : _goingRouteColor;

    const phases = TripPhaseController();
    final phaseAction = phases.actionFor(trip.status);

    final distanceMeters =
        route?.distanceMeters ?? progress?.distanceRemainingMeters;
    final durationSeconds = route?.durationSeconds ?? progress?.etaSeconds;

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: driverPoint ?? toLatLng ?? MapDefaults.defaultCenter,
            initialZoom: 15,
            onPositionChanged: (position, hasGesture) {
              if (hasGesture && _followDriver) {
                setState(() => _followDriver = false);
              }
            },
          ),
          children: [
            ...osmBaseLayers(textDirection: Directionality.of(context)),
            if (travelledPoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: travelledPoints,
                    color: _travelledRouteColor.withValues(alpha: 0.85),
                    strokeWidth: 6,
                  ),
                ],
              ),
            if (plannedPoints.length >= 2)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: plannedPoints,
                    color: route != null && route.isApproximate
                        ? plannedColor.withValues(alpha: 0.7)
                        : plannedColor,
                    strokeWidth: route != null && route.isApproximate ? 3 : 5,
                    pattern: route != null && route.isApproximate
                        ? StrokePattern.dashed(segments: const [8, 6])
                        : const StrokePattern.solid(),
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (toLatLng != null)
                  Marker(
                    point: toLatLng,
                    width: 120,
                    height: 56,
                    child: _LabeledPin(
                      color: plannedColor,
                      icon: Icons.location_on,
                      label: toEndpoint?.name ?? '',
                    ),
                  ),
                if (driverPoint != null)
                  Marker(
                    point: driverPoint,
                    width: 56,
                    height: 56,
                    child: DriverPositionMarker(
                      headingDegrees: _animatedHeading,
                      accuracyMeters: accuracy,
                    ),
                  ),
              ],
            ),
          ],
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _PhaseChip(status: trip.status),
                    TrackingStatusChip(
                      status: tracking.status,
                      onFix: _fixPermission,
                    ),
                  ],
                ),
                if (nav.locatingPosition) ...[
                  const SizedBox(height: 8),
                  _BannerChip(
                    color: AppColors.midBlue,
                    text: l10n.locatingDriverPosition,
                    trailing: const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ],
                if (nav.positionTimedOut) ...[
                  const SizedBox(height: 8),
                  _BannerChip(
                    color: AppColors.warning,
                    text: l10n.locationFixTimedOut,
                    actionLabel: l10n.retryAction,
                    onAction: () => ref
                        .read(
                          tripNavigationControllerProvider(widget.tripId)
                              .notifier,
                        )
                        .retryLocatePosition(),
                  ),
                ],
                if (tracking.warningBanner) ...[
                  const SizedBox(height: 8),
                  Material(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Text(
                        locationSharingBannerText(l10n, tracking),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                ],
                if (nav.isApproximateRoute) ...[
                  const SizedBox(height: 8),
                  _BannerChip(
                    color: AppColors.midBlue,
                    text: l10n.routeUnavailableShowingDirectLine,
                    actionLabel: l10n.retryAction,
                    onAction: () => ref
                        .read(
                          tripNavigationControllerProvider(widget.tripId)
                              .notifier,
                        )
                        .recalculateRoute(),
                  ),
                ],
                if (toEndpoint != null && !toEndpoint.hasPoint) ...[
                  const SizedBox(height: 8),
                  _BannerChip(
                    color: AppColors.warning,
                    text: l10n.locationNotSetFor(toEndpoint.name),
                  ),
                ],
              ],
            ),
          ),
        ),
        PositionedDirectional(
          end: 16,
          bottom: 220,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'driver_recalculate',
                onPressed: nav.fetchingRoute
                    ? null
                    : () => ref
                          .read(
                            tripNavigationControllerProvider(widget.tripId)
                                .notifier,
                          )
                          .recalculateRoute(),
                tooltip: l10n.recalculateRoute,
                child: nav.fetchingRoute
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.alt_route),
              ),
              if (!_followDriver) ...[
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'driver_recenter',
                  onPressed: () {
                    setState(() => _followDriver = true);
                    if (driverPoint != null) {
                      _mapController.move(driverPoint, 15);
                    }
                  },
                  tooltip: l10n.recenterMap,
                  child: const Icon(Icons.my_location),
                ),
              ],
            ],
          ),
        ),
        Align(
          alignment: Alignment.bottomCenter,
          child: _TripBottomCard(
            requesters: trip.requesters,
            passengerCount: trip.passengerCount,
            destinationName: toEndpoint?.name ?? trip.destinationSummary,
            distanceMeters: distanceMeters,
            durationSeconds: durationSeconds,
            isApproximate: nav.isApproximateRoute,
            isReturning: onReturnLeg,
            phaseAction: phaseAction,
            isLoading: isActionLoading,
            onPhaseAction: phaseAction == null
                ? null
                : () => _confirmPhase(context, trip.id, phaseAction),
            onRecalculate: () => ref
                .read(tripNavigationControllerProvider(widget.tripId).notifier)
                .recalculateRoute(),
          ),
        ),
      ],
    );
  }

  LatLng? _toLatLng(RoutePoint? point) {
    if (point == null) return null;
    return LatLng(point.lat, point.lng);
  }

  LatLng _toLatLngRequired(RoutePoint point) => LatLng(point.lat, point.lng);

  Future<void> _confirmPhase(
    BuildContext context,
    String tripId,
    TripPhaseAction action,
  ) async {
    final l10n = AppLocalizations.of(context);
    final (title, message, confirmLabel, success) = switch (action) {
      TripPhaseAction.startTrip => (
        l10n.startTripConfirmTitle,
        l10n.startTripConfirmMessage,
        l10n.startTrip,
        l10n.tripStarted,
      ),
      TripPhaseAction.arriveAtDestination => (
        l10n.arrivedAtDestinationConfirmTitle,
        l10n.arrivedAtDestinationConfirmMessage,
        l10n.arrivedAtDestination,
        l10n.arrivedAtDestinationSuccess,
      ),
      TripPhaseAction.startReturn => (
        l10n.startReturnConfirmTitle,
        l10n.startReturnConfirmMessage,
        l10n.startReturn,
        l10n.startReturnSuccess,
      ),
      TripPhaseAction.endTrip => (
        l10n.endTripConfirmTitle,
        l10n.endTripConfirmMessage,
        l10n.endTrip,
        l10n.tripEnded,
      ),
    };

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final controller = ref.read(driverTripLifecycleControllerProvider.notifier);
    final ok = await switch (action) {
      TripPhaseAction.startTrip => controller.start(tripId),
      TripPhaseAction.arriveAtDestination => controller.arriveAtDestination(
        tripId,
      ),
      TripPhaseAction.startReturn => controller.startReturn(tripId),
      TripPhaseAction.endTrip => controller.end(tripId),
    };
    if (!context.mounted) return;
    if (!ok) {
      final failure = ref.read(driverTripLifecycleControllerProvider).failure;
      if (failure == null) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message(l10n))));
      return;
    }

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(success)));
    if (action == TripPhaseAction.startReturn) {
      await ref
          .read(tripNavigationControllerProvider(widget.tripId).notifier)
          .startReturnLeg();
    }
    if (action == TripPhaseAction.endTrip && context.mounted) {
      Navigator.of(context).maybePop();
    }
  }
}

class _PhaseChip extends StatelessWidget {
  const _PhaseChip({required this.status});

  final TripStatus status;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final label = switch (status) {
      TripStatus.going => l10n.tripStatusGoing,
      TripStatus.atDestination => l10n.liveMapPhaseArrived,
      TripStatus.returning => l10n.tripStatusReturning,
      _ => status.label(l10n),
    };
    final color = switch (status) {
      TripStatus.going => _goingRouteColor,
      TripStatus.atDestination => AppColors.success,
      TripStatus.returning => _returningRouteColor,
      _ => AppColors.midBlue,
    };

    return Material(
      color: color.withValues(alpha: 0.14),
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Text(
          label,
          style: Theme.of(context).textTheme.labelLarge
              ?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _BannerChip extends StatelessWidget {
  const _BannerChip({
    required this.color,
    required this.text,
    this.trailing,
    this.actionLabel,
    this.onAction,
  });

  final Color color;
  final String text;
  final Widget? trailing;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(text, style: Theme.of(context).textTheme.bodySmall),
            ),
            if (trailing != null) ...[const SizedBox(width: 8), trailing!],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabeledPin extends StatelessWidget {
  const _LabeledPin({
    required this.color,
    required this.icon,
    required this.label,
  });

  final Color color;
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 32),
        if (label.trim().isNotEmpty)
          Container(
            constraints: const BoxConstraints(maxWidth: 110),
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: color.withValues(alpha: 0.4)),
            ),
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
      ],
    );
  }
}

class _TripBottomCard extends StatelessWidget {
  const _TripBottomCard({
    required this.requesters,
    required this.passengerCount,
    required this.destinationName,
    required this.distanceMeters,
    required this.durationSeconds,
    required this.isApproximate,
    required this.isReturning,
    required this.phaseAction,
    required this.isLoading,
    required this.onPhaseAction,
    required this.onRecalculate,
  });

  final List<TripRequester> requesters;
  final int passengerCount;
  final String destinationName;
  final double? distanceMeters;
  final double? durationSeconds;
  final bool isApproximate;
  final bool isReturning;
  final TripPhaseAction? phaseAction;
  final bool isLoading;
  final VoidCallback? onPhaseAction;
  final VoidCallback onRecalculate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final distanceLabel = distanceMeters == null
        ? null
        : l10n.estimatedDistanceKm((distanceMeters! / 1000).toStringAsFixed(1));
    final etaLabel = durationSeconds == null
        ? null
        : l10n.estimatedEtaMinutes(
            ((durationSeconds! / 60).ceil()).clamp(1, 999),
          );

    final card = Material(
      elevation: 8,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      color: AppColors.white,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 16),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(context).height * 0.5,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.lightBlue,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          destinationName,
                          style: textTheme.titleMedium,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (isReturning)
                        Container(
                          margin: const EdgeInsetsDirectional.only(start: 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _returningRouteColor.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            l10n.tripStatusReturning,
                            style: textTheme.labelMedium?.copyWith(
                              color: _returningRouteColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TripRequestersSection(
                    requesters: requesters,
                    passengerCount: passengerCount,
                  ),
                  if (distanceLabel != null || etaLabel != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      [?distanceLabel, ?etaLabel].join(' · '),
                      style: textTheme.bodyMedium?.copyWith(
                        color: isApproximate
                            ? AppColors.midBlue
                            : AppColors.deepBlue,
                      ),
                    ),
                  ],
                  if (isApproximate) ...[
                    const SizedBox(height: 4),
                    Text(
                      l10n.routeUnavailableShowingDirectLine,
                      style: textTheme.bodySmall?.copyWith(
                        color: AppColors.midBlue,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: onRecalculate,
                          icon: const Icon(Icons.alt_route),
                          label: Text(l10n.recalculateRoute),
                        ),
                      ),
                      if (phaseAction != null) ...[
                        const SizedBox(width: 8),
                        Expanded(
                          child: AppButton(
                            label: switch (phaseAction!) {
                              TripPhaseAction.startTrip => l10n.startTrip,
                              TripPhaseAction.arriveAtDestination =>
                                l10n.arrivedAtDestination,
                              TripPhaseAction.startReturn => l10n.startReturn,
                              TripPhaseAction.endTrip => l10n.endTrip,
                            },
                            variant: phaseAction == TripPhaseAction.endTrip
                                ? AppButtonVariant.danger
                                : AppButtonVariant.filled,
                            isLoading: isLoading,
                            loadingLabel: l10n.loading,
                            onPressed: isLoading ? null : onPhaseAction,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    if (disableAnimations) return card;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 350),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) {
        return Transform.translate(
          offset: Offset(0, 24 * (1 - t)),
          child: Opacity(opacity: t, child: child),
        );
      },
      child: card,
    );
  }
}
