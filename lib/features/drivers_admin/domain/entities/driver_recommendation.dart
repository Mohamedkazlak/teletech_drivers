import 'package:equatable/equatable.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';

/// Why a driver appears in recommendation chips / ranking explanation.
enum DriverRecommendationReason {
  favoritePlace,
  available,
  scheduleConflict,
  onActiveTrip,
  unavailable,
}

/// Ranked driver candidate for assign / reassign (Strategy: recommendation).
class DriverRecommendation extends Equatable {
  const DriverRecommendation({
    required this.driver,
    required this.tier,
    required this.isAvailable,
    required this.hasScheduleConflict,
    required this.isOnActiveTrip,
    required this.favoriteMatch,
    required this.tripsThisWeek,
    required this.reasons,
    required this.isRecommended,
  });

  final DriverProfile driver;

  /// Server rank. 0 is the best match.
  final int tier;

  /// Official availability is available and the driver is active.
  final bool isAvailable;

  /// Another trip within the schedule-conflict window.
  final bool hasScheduleConflict;

  /// Driver currently has an in-progress trip.
  final bool isOnActiveTrip;

  /// Trip pickup/destination place id is in the driver's favorites.
  final bool favoriteMatch;

  /// Non-cancelled trips scheduled in the current week for this driver.
  final int tripsThisWeek;

  /// Display tags explaining ranking / warnings.
  final List<DriverRecommendationReason> reasons;

  /// True when available, not on an active trip, and no schedule conflict.
  final bool isRecommended;

  /// Soft warning that should confirm before assign.
  bool get needsConfirmation =>
      !isAvailable || isOnActiveTrip || hasScheduleConflict;

  @override
  List<Object?> get props => [
    driver,
    tier,
    isAvailable,
    hasScheduleConflict,
    isOnActiveTrip,
    favoriteMatch,
    tripsThisWeek,
    reasons,
    isRecommended,
  ];
}
