import 'package:flutter/material.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_preview_map.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/custom_location_chip.dart';

/// Place label row with an optional "Custom location" chip and map preview.
class TripPlaceLine extends StatelessWidget {
  const TripPlaceLine({
    required this.text,
    this.showCustomChip = false,
    this.address,
    this.latitude,
    this.longitude,
    this.style,
    this.previewHeight = 110,
    super.key,
  });

  final String text;
  final bool showCustomChip;
  final String? address;
  final double? latitude;
  final double? longitude;
  final TextStyle? style;
  final double previewHeight;

  @override
  Widget build(BuildContext context) {
    final addressText = address?.trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(text, style: style),
            ),
            if (showCustomChip) ...[
              const SizedBox(width: 8),
              const CustomLocationChip(),
            ],
          ],
        ),
        if (addressText != null && addressText.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            addressText,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        OptionalPlacePreviewMap(
          latitude: latitude,
          longitude: longitude,
          height: previewHeight,
        ),
      ],
    );
  }
}
