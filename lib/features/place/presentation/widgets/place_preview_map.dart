import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/features/tracking/presentation/widgets/osm_map_layer.dart';

/// Compact read-only OSM preview with a single marker.
class PlacePreviewMap extends StatelessWidget {
  const PlacePreviewMap({
    required this.latitude,
    required this.longitude,
    this.height = 140,
    this.zoom = 15,
    super.key,
  });

  final double latitude;
  final double longitude;
  final double height;
  final double zoom;

  @override
  Widget build(BuildContext context) {
    final point = LatLng(latitude, longitude);

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: height,
        width: double.infinity,
        child: IgnorePointer(
          child: FlutterMap(
            options: MapOptions(
              initialCenter: point,
              initialZoom: zoom,
              interactionOptions: const InteractionOptions(
                flags: InteractiveFlag.none,
              ),
            ),
            children: [
              ...osmBaseLayers(
                textDirection: Directionality.of(context),
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: point,
                    width: 40,
                    height: 40,
                    alignment: Alignment.topCenter,
                    child: const Icon(
                      Icons.location_on,
                      color: AppColors.deepBlue,
                      size: 36,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows [PlacePreviewMap] only when both coordinates are present.
class OptionalPlacePreviewMap extends StatelessWidget {
  const OptionalPlacePreviewMap({
    required this.latitude,
    required this.longitude,
    this.height = 140,
    this.topSpacing = 8,
    super.key,
  });

  final double? latitude;
  final double? longitude;
  final double height;
  final double topSpacing;

  @override
  Widget build(BuildContext context) {
    final lat = latitude;
    final lng = longitude;
    if (lat == null || lng == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(height: topSpacing),
        PlacePreviewMap(latitude: lat, longitude: lng, height: height),
      ],
    );
  }
}
