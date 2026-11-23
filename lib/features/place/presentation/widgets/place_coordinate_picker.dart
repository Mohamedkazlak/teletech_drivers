import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/place/domain/entities/picked_location.dart';
import 'package:teletech_drivers/features/place/presentation/validation/place_validators.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/presentation/widgets/osm_map_layer.dart';

/// Inline "Pick on map" control: tap or drag the marker, or use GPS.
class PlaceCoordinatePicker extends StatefulWidget {
  const PlaceCoordinatePicker({
    required this.latitude,
    required this.longitude,
    required this.onChanged,
    this.address,
    this.enabled = true,
    this.mapHeight = 200,
    super.key,
  });

  final double? latitude;
  final double? longitude;
  final String? address;
  final ValueChanged<PickedLocation> onChanged;
  final bool enabled;
  final double mapHeight;

  @override
  State<PlaceCoordinatePicker> createState() => _PlaceCoordinatePickerState();
}

class _PlaceCoordinatePickerState extends State<PlaceCoordinatePicker> {
  final _mapController = MapController();
  var _locating = false;
  String? _locateMessage;
  late LatLng _viewCenter;
  LatLng? _marker;
  var _dragging = false;

  bool get _hasLocation => _marker != null;

  @override
  void initState() {
    super.initState();
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat != null && lng != null) {
      _marker = LatLng(lat, lng);
      _viewCenter = _marker!;
    } else {
      _viewCenter = MapDefaults.defaultCenter;
    }
  }

  @override
  void didUpdateWidget(covariant PlaceCoordinatePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    final lat = widget.latitude;
    final lng = widget.longitude;
    if (lat == null || lng == null) {
      if (_marker != null && !_dragging) {
        setState(() => _marker = null);
      }
      return;
    }
    final next = LatLng(lat, lng);
    if (_marker?.latitude == next.latitude &&
        _marker?.longitude == next.longitude) {
      return;
    }
    if (_dragging) return;
    setState(() {
      _marker = next;
      _viewCenter = next;
    });
    _mapController.move(next, _mapController.camera.zoom);
  }

  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _emit(LatLng point) {
    widget.onChanged(
      PickedLocation(
        lat: point.latitude,
        lng: point.longitude,
        address: widget.address,
      ),
    );
  }

  void _setMarker(LatLng point, {required bool moveCamera}) {
    if (!widget.enabled) return;
    if (!PlaceValidators.isValidLatitude(point.latitude) ||
        !PlaceValidators.isValidLongitude(point.longitude)) {
      return;
    }
    setState(() {
      _marker = point;
      _viewCenter = point;
      _locateMessage = null;
    });
    if (moveCamera) {
      _mapController.move(point, 15);
    }
    _emit(point);
  }

  Future<void> _useMyLocation() async {
    if (!widget.enabled || _locating) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _locating = true;
      _locateMessage = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() => _locateMessage = l10n.locationServicesDisabled);
        await _showLocationHelp(
          message: l10n.locationServicesDisabled,
          openSettings: Geolocator.openLocationSettings,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locateMessage = l10n.locationPermissionDenied);
        await _showLocationHelp(
          message: l10n.locationPermissionDenied,
          openSettings: ph.openAppSettings,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      _setMarker(
        LatLng(position.latitude, position.longitude),
        moveCamera: true,
      );
    } on Object {
      if (!mounted) return;
      setState(() => _locateMessage = l10n.locationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _showLocationHelp({
    required String message,
    required Future<bool> Function() openSettings,
  }) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openSettings();
              },
              child: Text(l10n.openSettingsAction),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final marker = _marker;
    final coords = marker == null
        ? null
        : '${marker.latitude.toStringAsFixed(5)}, '
              '${marker.longitude.toStringAsFixed(5)}';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.pickLocationOnMap,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: widget.mapHeight,
            width: double.infinity,
            child: Stack(
              children: [
                FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _viewCenter,
                    initialZoom: marker != null ? 15 : MapDefaults.defaultZoom,
                    interactionOptions: InteractionOptions(
                      flags: widget.enabled
                          ? InteractiveFlag.all
                          : InteractiveFlag.none,
                    ),
                    onTap: widget.enabled
                        ? (_, point) => _setMarker(point, moveCamera: false)
                        : null,
                  ),
                  children: [
                    ...osmBaseLayers(textDirection: Directionality.of(context)),
                    if (marker != null)
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: marker,
                            width: 48,
                            height: 48,
                            alignment: Alignment.topCenter,
                            child: GestureDetector(
                              onPanStart: widget.enabled
                                  ? (_) => _dragging = true
                                  : null,
                              onPanUpdate: widget.enabled
                                  ? (details) {
                                      final camera = _mapController.camera;
                                      final projected = camera
                                          .latLngToScreenOffset(marker);
                                      final nextOffset =
                                          projected + details.delta;
                                      final next = camera.screenOffsetToLatLng(
                                        nextOffset,
                                      );
                                      setState(() {
                                        _marker = next;
                                        _viewCenter = next;
                                      });
                                    }
                                  : null,
                              onPanEnd: widget.enabled
                                  ? (_) {
                                      _dragging = false;
                                      final point = _marker;
                                      if (point != null) _emit(point);
                                    }
                                  : null,
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.deepBlue,
                                size: 44,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
                if (!_hasLocation)
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 8,
                    child: Center(
                      child: Material(
                        color: Theme.of(context).colorScheme.surface
                            .withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            l10n.tapMapToSetLocation,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 8),
        if (coords != null)
          Text(
            coords,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).hintColor),
          )
        else
          Text(
            l10n.placeMissingCoordinates,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: Theme.of(context).hintColor),
          ),
        if (_locateMessage != null) ...[
          const SizedBox(height: 4),
          Text(
            _locateMessage!,
            style: Theme.of(context).textTheme.bodySmall
                ?.copyWith(color: AppColors.error),
          ),
        ],
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: widget.enabled && !_locating ? _useMyLocation : null,
          icon: _locating
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.my_location),
          label: Text(l10n.useMyCurrentLocation),
        ),
      ],
    );
  }
}
