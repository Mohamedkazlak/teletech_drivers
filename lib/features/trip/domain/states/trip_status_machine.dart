import 'package:teletech_drivers/features/trip/domain/controllers/trip_phase_controller.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

/// State: thin facade over [TripPhaseController] for existing call sites.
abstract final class TripStatusMachine {
  static const TripPhaseController _phases = TripPhaseController();

  static bool canTransition(TripStatus from, TripStatus to) =>
      _phases.canTransition(from, to);

  static void ensureCanTransition(TripStatus from, TripStatus to) =>
      _phases.ensureCanTransition(from, to);

  static bool canAssign(TripStatus status) => _phases.canAssign(status);

  static bool canReassign(TripStatus status) => _phases.canReassign(status);

  static bool canCancel(TripStatus status) => _phases.canCancel(status);

  static bool canStart(TripStatus status) => _phases.canStartTrip(status);

  static bool canArriveAtDestination(TripStatus status) =>
      _phases.canArriveAtDestination(status);

  static bool canStartReturn(TripStatus status) =>
      _phases.canStartReturn(status);

  static bool canComplete(TripStatus status) => _phases.canEndTrip(status);
}
