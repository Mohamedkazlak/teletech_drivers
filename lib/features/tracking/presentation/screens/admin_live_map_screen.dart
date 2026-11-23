import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:latlong2/latlong.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/utils/phone_dialer.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_driver.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/live_map_state.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/domain/services/trip_progress_calculator.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:teletech_drivers/features/tracking/presentation/widgets/osm_map_layer.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

/// Drivers Admin read-only live map of drivers on active trips.
class AdminLiveMapScreen extends ConsumerStatefulWidget {
  const AdminLiveMapScreen({
    this.focusDriverId,
    this.showAppBar = true,
    this.showBackButton,
    super.key,
  });

  /// When set, centers on this driver's marker after first load.
  final String? focusDriverId;

  /// False on the live-map shell tab, where there is nothing to pop.
  final bool? showBackButton;

  /// False when embedded as a home tab (outer scaffold already shows the logo).
  final bool showAppBar;

  @override
  ConsumerState<AdminLiveMapScreen> createState() => _AdminLiveMapScreenState();
}

class _AdminLiveMapScreenState extends ConsumerState<AdminLiveMapScreen> {
  late final MapController _mapController;
  var _didFocus = false;
  final Map<String, LatLng> _displayPoints = {};
  LiveMapState? _stateFilter;
  AsyncValue<List<LiveMapDriver>>? _locations;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _fitAll(List<LiveMapDriver> locations) {
    if (locations.isEmpty) {
      _mapController.move(MapDefaults.defaultCenter, MapDefaults.defaultZoom);
      return;
    }
    if (locations.length == 1) {
      final only = locations.first;
      _mapController.move(LatLng(only.lat!, only.lng!), 14);
      return;
    }
    final bounds = LatLngBounds.fromPoints([
      for (final location in locations) LatLng(location.lat!, location.lng!),
    ]);
    _mapController.fitCamera(
      CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(48)),
    );
  }

  void _centerOn(LiveMapDriver location) {
    _mapController.move(LatLng(location.lat!, location.lng!), 15);
  }

  Future<void> _openDriverSheet({
    required LiveMapDriver location,
    required DriverProfile? profile,
    required Trip? trip,
  }) async {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final locale = Localizations.localeOf(context).toString();
    final timeFormat = DateFormat.Hm(locale);
    final dateFormat = DateFormat.yMMMd(locale).add_jm();
    final resolver = ref.read(placeNameResolverProvider);
    final pickupSummary = trip?.pickupSummary ?? location.trip?.pickupSummary;
    final destinationSummary =
        trip?.destinationSummary ?? location.trip?.destinationSummary;
    final pickupName = pickupSummary == null
        ? null
        : resolver.resolveSummary(
            summary: pickupSummary,
            languageCode: languageCode,
          );
    final destinationName = destinationSummary == null
        ? null
        : resolver.resolveSummary(
            summary: destinationSummary,
            languageCode: languageCode,
          );

    TripRequestSnapshot? requester;
    if (trip != null && trip.requestIds.isNotEmpty) {
      final requests = await ref.read(
        tripRequestsByIdsProvider(trip.requestIds.join(',')).future,
      );
      if (requests.isNotEmpty) {
        final first = requests.first;
        requester = TripRequestSnapshot(
          name: first.employeeName,
          phone: first.employeePhone,
          branchLabel: first.employeeBranch == null
              ? null
              : branchLabel(first.employeeBranch!, l10n),
        );
      }
    }

    String? progressLabel;
    if (trip != null) {
      final places = await ref.read(tripMapPlacesProvider(trip).future);
      final destination = places.destinationPoint;
      final pickup = places.pickupPoint;
      if (destination != null) {
        final driverPoint = RoutePoint(location.lat!, location.lng!);
        final target = RoutePoint(destination.latitude, destination.longitude);
        final origin = pickup == null
            ? driverPoint
            : RoutePoint(pickup.latitude, pickup.longitude);
        final osrm = ref.read(osrmRouteServiceProvider);
        final cacheKey =
            '${trip.id}:going:${origin.lat.toStringAsFixed(4)},${origin.lng.toStringAsFixed(4)}>'
            '${target.lat.toStringAsFixed(4)},${target.lng.toStringAsFixed(4)}';
        final route = osrm.cached(cacheKey);
        final calculator = TripProgressCalculator(
          arrivalRadiusMeters: MapDefaults.arrivalRadiusMeters,
        );
        final progress = calculator.calculate(
          polyline: route?.points ?? [origin, target],
          position: driverPoint,
          target: target,
          routeDurationSeconds: route?.durationSeconds,
          straightLineFallback: route == null || route.isApproximate,
        );
        progressLabel = l10n.adminTripProgress(
          (progress.percentComplete * 100).round(),
          (progress.distanceRemainingMeters / 1000).toStringAsFixed(1),
        );
      }
    }

    if (!mounted) return;

    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (sheetContext) {
        final name =
            profile?.localizedName(languageCode) ??
            location.driver.localizedName(languageCode);
        final phone = profile?.phone;
        final car = profile?.carLicense;
        final updatedAt = location.updatedAt;
        final staleLabel = location.isStale
            ? l10n.lastSeenMinutesAgo(_minutesSince(updatedAt))
            : null;

        return Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(20, 0, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(name, style: Theme.of(sheetContext).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(_liveMapStateLabel(location.state, l10n)),
              if (location.lastSeenAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.liveProgressLastSeen(
                    timeFormat.format(location.lastSeenAt!.toLocal()),
                  ),
                ),
              ],
              if (car != null && car.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(l10n.carLicenseValue(car)),
              ],
              if (staleLabel != null) ...[
                const SizedBox(height: 4),
                Text(staleLabel, style: TextStyle(color: AppColors.warning)),
              ],
              if (phone != null && phone.isNotEmpty)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.phone_outlined),
                  title: Text(phone),
                  trailing: IconButton(
                    tooltip: l10n.callEmployeePhone(phone),
                    icon: const Icon(Icons.call_outlined),
                    onPressed: () => PhoneDialer.dial(phone),
                  ),
                ),
              if (trip != null &&
                  pickupName != null &&
                  destinationName != null) ...[
                const SizedBox(height: 8),
                Text(
                  l10n.tripRouteSummary(pickupName, destinationName),
                  style: Theme.of(sheetContext).textTheme.titleSmall,
                ),
              ],
              if (location.trip?.scheduledAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  l10n.liveMapScheduledAt(
                    dateFormat.format(location.trip!.scheduledAt!.toLocal()),
                  ),
                ),
              ],
              if (progressLabel != null) ...[
                const SizedBox(height: 4),
                Text(
                  progressLabel,
                  style: Theme.of(sheetContext).textTheme.bodyMedium?.copyWith(
                    color: AppColors.deepBlue,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
              if (requester != null) ...[
                const SizedBox(height: 8),
                Text(l10n.requesterSection),
                Text(requester.name),
                if (requester.branchLabel != null) Text(requester.branchLabel!),
              ],
              const SizedBox(height: 8),
              Text(
                trip?.startedAt == null
                    ? l10n.tripNotStartedYet
                    : l10n.tripStartedValue(
                        dateFormat.format(trip!.startedAt!.toLocal()),
                      ),
              ),
              Text(
                l10n.speedKmh(
                  ((location.speed ?? 0) * 3.6).clamp(0, 999).toStringAsFixed(0),
                ),
              ),
              if (updatedAt != null)
                Text(
                  l10n.lastUpdateValue(
                    timeFormat.format(updatedAt.toLocal()),
                  ),
                ),
              if (trip != null || location.trip != null) ...[
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    Navigator.of(sheetContext).pop();
                    context.push(
                      AppRoutes.driversAdminTripDetailsPath(
                        trip?.id ?? location.trip!.id,
                      ),
                    );
                  },
                  child: Text(l10n.openTripDetails),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locationsAsync = _locations ?? const AsyncLoading<List<LiveMapDriver>>();
    final profilesAsync = ref.watch(allDriverProfilesProvider);
    final tripsAsync = ref.watch(allTripsProvider);

    final body = locationsAsync.when(
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
      data: (locations) {
        final filtered = [
          for (final item in locations)
            if (_matchesStateFilter(item, _stateFilter)) item,
        ];
        final located = [
          for (final item in filtered)
            if (item.hasFix) item,
        ];
        final missing = [
          for (final item in filtered)
            if (!item.hasFix) item,
        ];

        final profiles = {
          for (final profile
              in profilesAsync.asData?.value ?? <DriverProfile>[])
            profile.id: profile,
        };
        final tripsById = {
          for (final trip in tripsAsync.asData?.value ?? <Trip>[])
            trip.id: trip,
        };

        for (final location in located) {
          _displayPoints.putIfAbsent(
            location.driver.id,
            () => LatLng(location.lat!, location.lng!),
          );
          _displayPoints[location.driver.id] = LatLng(
            location.lat!,
            location.lng!,
          );
        }

        if (!_didFocus) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _didFocus = true;
            final focusId = widget.focusDriverId;
            if (focusId != null) {
              final focused = located
                  .where((item) => item.driver.id == focusId)
                  .firstOrNull;
              if (focused != null) {
                _centerOn(focused);
                return;
              }
            }
            _fitAll(located);
          });
        }

        final languageCode = Localizations.localeOf(context).languageCode;

        return Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
              child: Row(
                children: [
                  FilterChip(
                    label: Text(l10n.branchFilterAll),
                    selected: _stateFilter == null,
                    onSelected: (_) => setState(() => _stateFilter = null),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(l10n.liveMapStateAvailable),
                    selected: _stateFilter == LiveMapState.available,
                    onSelected: (_) => setState(
                      () => _stateFilter = LiveMapState.available,
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(l10n.liveMapStateUnavailable),
                    selected: _stateFilter == LiveMapState.unavailable,
                    onSelected: (_) => setState(
                      () => _stateFilter = LiveMapState.unavailable,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Stack(
          children: [
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: MapDefaults.defaultCenter,
                initialZoom: MapDefaults.defaultZoom,
              ),
              children: [
                ...osmBaseLayers(
                  textDirection: Directionality.of(context),
                ),
                PolylineLayer(
                  polylines: [
                    for (final location in located)
                      if (location.trip != null &&
                          tripsById[location.trip!.id] != null)
                        ..._destinationDashedLine(
                          location: location,
                          trip: tripsById[location.trip!.id]!,
                        ),
                  ],
                ),
                MarkerLayer(
                  markers: [
                    for (final location in located)
                      Marker(
                        point:
                            _displayPoints[location.driver.id] ??
                            LatLng(location.lat!, location.lng!),
                        width: 120,
                        height: 64,
                        child: _AdminDriverMarker(
                          label:
                              profiles[location.driver.id]?.localizedName(
                                languageCode,
                              ) ??
                              location.driver.localizedName(languageCode),
                          stale: location.isStale,
                          color: _markerColor(location),
                          lastSeenMinutes: _minutesSince(location.lastSeenAt),
                          onTap: () => _openDriverSheet(
                            location: location,
                            profile: profiles[location.driver.id],
                            trip: location.trip == null
                                ? null
                                : tripsById[location.trip!.id],
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            SafeArea(
              child: Column(
                children: [
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
                    child: Row(
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.zoom_out_map, size: 18),
                          label: Text(l10n.fitAllDrivers),
                          onPressed: () => _fitAll(located),
                        ),
                        const SizedBox(width: 8),
                        for (final location in located) ...[
                          ActionChip(
                            label: Text(
                              profiles[location.driver.id]?.localizedName(
                                    languageCode,
                                  ) ??
                                  location.driver.localizedName(languageCode),
                            ),
                            onPressed: () => _centerOn(location),
                          ),
                          const SizedBox(width: 8),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (filtered.isEmpty)
              Center(
                child: Text(
                  l10n.liveMapNoDrivers,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
          ],
        ),
            ),
            if (missing.isNotEmpty)
              _NoLocationList(
                title: l10n.liveMapNoLocationTitle,
                names: [
                  for (final item in missing)
                    profiles[item.driver.id]?.localizedName(languageCode) ??
                        item.driver.localizedName(languageCode),
                ],
              ),
          ],
        );
      },
    );

    return AppScaffold(
      showAppBar: widget.showAppBar,
      title: widget.showAppBar ? l10n.liveMapTitle : null,
      showBackButton: widget.showBackButton ?? widget.showAppBar,
      body: Stack(
        children: [
          body,
          if (TickerMode.valuesOf(context).enabled)
            _LiveMapSubscription(
              driverId: widget.focusDriverId,
              onValue: (value) {
                if (!mounted || _locations == value) return;
                setState(() => _locations = value);
              },
            ),
        ],
      ),
    );
  }

  List<Polyline> _destinationDashedLine({
    required LiveMapDriver location,
    required Trip trip,
  }) {
    // Prefer a cached OSRM route (filled by the driver app); otherwise dashed.
    final places = ref.read(tripMapPlacesProvider(trip)).asData?.value;
    final destination = places?.destinationPoint;
    final pickup = places?.pickupPoint;
    if (destination == null) return const [];

    if (pickup != null) {
      final cacheKey =
          '${trip.id}:going:${pickup.latitude.toStringAsFixed(4)},${pickup.longitude.toStringAsFixed(4)}>'
          '${destination.latitude.toStringAsFixed(4)},${destination.longitude.toStringAsFixed(4)}';
      final cached = ref.read(osrmRouteServiceProvider).cached(cacheKey);
      if (cached != null && cached.points.length >= 2) {
        final points = [for (final p in cached.points) LatLng(p.lat, p.lng)];
        return [
          Polyline(
            points: points,
            color: AppColors.deepBlue.withValues(alpha: 0.75),
            strokeWidth: 3,
          ),
        ];
      }
    }

    return [
      Polyline(
        points: [LatLng(location.lat!, location.lng!), destination],
        color: AppColors.lightBlue,
        strokeWidth: 2,
        pattern: StrokePattern.dashed(segments: const [6, 6]),
      ),
    ];
  }
}

int _minutesSince(DateTime? updatedAt) {
  if (updatedAt == null) return 1;
  return DateTime.now()
      .toUtc()
      .difference(updatedAt.toUtc())
      .inMinutes
      .clamp(1, 999);
}

class TripRequestSnapshot {
  const TripRequestSnapshot({required this.name, this.phone, this.branchLabel});

  final String name;
  final String? phone;
  final String? branchLabel;
}

bool _matchesStateFilter(LiveMapDriver driver, LiveMapState? filter) {
  if (filter == null) return true;
  return driver.state == filter;
}

Color _markerColor(LiveMapDriver driver) {
  if (driver.isStale) return Colors.grey;
  return switch (driver.state) {
    LiveMapState.onTrip => AppColors.deepBlue,
    LiveMapState.available => AppColors.success,
    LiveMapState.unavailable => AppColors.error,
  };
}

String _liveMapStateLabel(LiveMapState state, AppLocalizations l10n) {
  return switch (state) {
    LiveMapState.onTrip => l10n.liveMapStateOnTrip,
    LiveMapState.available => l10n.liveMapStateAvailable,
    LiveMapState.unavailable => l10n.liveMapStateUnavailable,
  };
}

class _NoLocationList extends StatelessWidget {
  const _NoLocationList({required this.title, required this.names});

  final String title;
  final List<String> names;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 160),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 12),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            for (final name in names) Text(name),
          ],
        ),
      ),
    );
  }
}

class _LiveMapSubscription extends ConsumerWidget {
  const _LiveMapSubscription({required this.driverId, required this.onValue});

  final String? driverId;
  final ValueChanged<AsyncValue<List<LiveMapDriver>>> onValue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(adminLiveMapLocationsProvider(driverId), (_, next) {
      onValue(next);
    });
    final current = ref.watch(adminLiveMapLocationsProvider(driverId));
    WidgetsBinding.instance.addPostFrameCallback((_) => onValue(current));
    return const SizedBox.shrink();
  }
}

class _AdminDriverMarker extends StatelessWidget {
  const _AdminDriverMarker({
    required this.label,
    required this.stale,
    required this.color,
    required this.lastSeenMinutes,
    required this.onTap,
  });

  final String label;
  final bool stale;
  final Color color;
  final int lastSeenMinutes;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final marker = GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            stale ? Icons.directions_car_outlined : Icons.directions_car,
            color: color,
            size: 28,
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: color,
                width: stale ? 1.5 : 1,
              ),
            ),
            child: Text(
              stale ? l10n.lastSeenMinutesAgo(lastSeenMinutes) : label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (disableAnimations) return marker;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 400),
      builder: (context, t, child) => Opacity(opacity: t, child: child),
      child: marker,
    );
  }
}
