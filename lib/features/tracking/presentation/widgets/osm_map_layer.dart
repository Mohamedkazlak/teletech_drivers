import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:teletech_drivers/core/widgets/map_pins.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';

/// Shared OSM tile layer + attribution used by driver and admin maps.
///
/// Pass [textDirection] so attribution sits on the start edge in RTL/Arabic.
List<Widget> osmBaseLayers({TextDirection? textDirection}) {
  final rtl = textDirection == TextDirection.rtl;
  return [
    const OsmTileLayer(),
    RichAttributionWidget(
      alignment: rtl
          ? AttributionAlignment.bottomRight
          : AttributionAlignment.bottomLeft,
      attributions: [
        TextSourceAttribution('© OpenStreetMap contributors', onTap: () {}),
      ],
    ),
  ];
}

/// OSM raster tiles. One [NetworkTileProvider] is kept for the layer's life.
class OsmTileLayer extends StatefulWidget {
  const OsmTileLayer({super.key});

  @override
  State<OsmTileLayer> createState() => _OsmTileLayerState();
}

class _OsmTileLayerState extends State<OsmTileLayer> {
  late final NetworkTileProvider _tiles = NetworkTileProvider();

  @override
  Widget build(BuildContext context) {
    return TileLayer(
      urlTemplate: MapDefaults.osmTileUrl,
      userAgentPackageName: MapDefaults.userAgentPackageName,
      tileProvider: _tiles,
      tileBuilder: brandTileBuilder,
    );
  }
}
