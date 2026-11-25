import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
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
      TripRequestStatus.cancelled => AppColors.inkMuted,
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
    final duration = AppAnimations.duration(context, AppMotion.quick);
    final ink = AppColors.inkOn(color);

    return AnimatedSwitcher(
      duration: duration,
      reverseDuration: AppAnimations.duration(context, AppMotion.exit),
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      transitionBuilder: (child, animation) {
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.92, end: 1).animate(animation),
            child: child,
          ),
        );
      },
      child: Semantics(
        key: ValueKey('$label-${color.toARGB32()}'),
        label: label,
        excludeSemantics: true,
        child: Container(
          padding: const EdgeInsetsDirectional.fromSTEB(8, 4, 10, 4),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
