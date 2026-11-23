import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/domain/entities/route_point.dart';
import 'package:teletech_drivers/features/tracking/presentation/widgets/osm_map_layer.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_report.dart';

/// Going leg polyline color (TeleTech deep blue).
const Color tripReportGoingRouteColor = AppColors.deepBlue;

/// Return leg polyline color (warm accent, distinct from going).
const Color tripReportReturnRouteColor = Color(0xFFC45C26);

/// Read-only map of going + return polylines fitted to route bounds.
class TripReportRouteMap extends StatefulWidget {
  const TripReportRouteMap({
    required this.report,
    this.height = 220,
    super.key,
  });

  final TripReport report;
  final double height;

  @override
  State<TripReportRouteMap> createState() => _TripReportRouteMapState();
}

class _TripReportRouteMapState extends State<TripReportRouteMap> {
  final MapController _mapController = MapController();

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final going = _toLatLngs(widget.report.goingPoints);
    final returning = _toLatLngs(widget.report.returnPoints);
    final start = _toLatLng(widget.report.startMarker);
    final destination = _toLatLng(widget.report.destinationMarker);
    final fitPoints = <LatLng>[...going, ...returning, ?start, ?destination];

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppTheme.controlRadius),
      child: SizedBox(
        height: widget.height,
        width: double.infinity,
        child: fitPoints.isEmpty
            ? ColoredBox(
                color: AppColors.paleBlue,
                child: Center(
                  child: Icon(
                    Icons.map_outlined,
                    color: AppColors.midBlue.withValues(alpha: 0.7),
                    size: 36,
                  ),
                ),
              )
            : FlutterMap(
                mapController: _mapController,
                options: MapOptions(
                  initialCenter: fitPoints.first,
                  initialZoom: MapDefaults.defaultZoom,
                  interactionOptions: const InteractionOptions(
                    flags:
                        InteractiveFlag.pinchZoom |
                        InteractiveFlag.drag |
                        InteractiveFlag.doubleTapZoom,
                  ),
                  onMapReady: () => _fitBounds(fitPoints),
                ),
                children: [
                  ...osmBaseLayers(textDirection: Directionality.of(context)),
                  if (going.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: going,
                          color: tripReportGoingRouteColor,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  if (returning.length >= 2)
                    PolylineLayer(
                      polylines: [
                        Polyline(
                          points: returning,
                          color: tripReportReturnRouteColor,
                          strokeWidth: 4,
                        ),
                      ],
                    ),
                  MarkerLayer(
                    markers: [
                      if (start != null)
                        Marker(
                          point: start,
                          width: 36,
                          height: 36,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.trip_origin,
                            color: AppColors.success,
                            size: 28,
                          ),
                        ),
                      if (destination != null)
                        Marker(
                          point: destination,
                          width: 40,
                          height: 40,
                          alignment: Alignment.topCenter,
                          child: const Icon(
                            Icons.location_on,
                            color: AppColors.error,
                            size: 36,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }

  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    if (points.length == 1) {
      _mapController.move(points.first, 14);
      return;
    }
    final bounds = LatLngBounds.fromPoints(points);
    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: bounds,
        padding: const EdgeInsets.all(36),
        maxZoom: 16,
      ),
    );
  }

  List<LatLng> _toLatLngs(List<RoutePoint> points) {
    return [for (final point in points) LatLng(point.lat, point.lng)];
  }

  LatLng? _toLatLng(RoutePoint? point) {
    if (point == null) return null;
    return LatLng(point.lat, point.lng);
  }
}
