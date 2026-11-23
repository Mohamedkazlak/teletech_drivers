import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';

/// Animated status chip with brand status colors.
class StatusChip extends StatelessWidget {
  const StatusChip({required this.label, required this.color, super.key});

  final String label;
  final Color color;

  factory StatusChip.forTripRequest({
    required TripRequestStatus status,
    required String label,
  }) {
    return StatusChip(label: label, color: colorForTripRequest(status));
  }

  factory StatusChip.forTrip({
    required TripStatus status,
    required String label,
  }) {
    return StatusChip(label: label, color: colorForTrip(status));
  }

  static Color colorForTripRequest(TripRequestStatus status) {
    return switch (status) {
      TripRequestStatus.pending => AppColors.statusPending,
      TripRequestStatus.approved => AppColors.statusApproved,
      TripRequestStatus.rejected => AppColors.statusRejected,
      TripRequestStatus.cancelled => AppColors.navy.withValues(alpha: 0.45),
    };
  }

  static Color colorForTrip(TripStatus status) {
    return switch (status) {
      TripStatus.unassigned => AppColors.statusPending,
      TripStatus.assigned => AppColors.statusAssigned,
      TripStatus.going => AppColors.statusInProgress,
      TripStatus.atDestination => AppColors.statusApproved,
      TripStatus.returning => AppColors.statusInProgress,
      TripStatus.completed => AppColors.statusCompleted,
      TripStatus.cancelled => AppColors.statusRejected,
    };
  }

  @override
  Widget build(BuildContext context) {
    final duration = AppAnimations.duration(
      context,
      const Duration(milliseconds: 220),
    );

    return AnimatedSwitcher(
      duration: duration,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: Chip(
        key: ValueKey('$label-${color.toARGB32()}'),
        label: Text(label),
        backgroundColor: color.withValues(alpha: 0.14),
        side: BorderSide.none,
        labelStyle: Theme.of(context).textTheme.labelLarge
            ?.copyWith(color: color, fontWeight: FontWeight.w700),
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
    );
  }
}
