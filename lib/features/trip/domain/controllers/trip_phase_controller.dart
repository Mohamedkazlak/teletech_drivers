import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';

/// State: allowed trip phase transitions for the driver lifecycle.
///
/// Keeps transition rules in one place so UI, use cases, and data writers
/// cannot invent illegal jumps (e.g. returning before going has ended).
class TripPhaseController {
  const TripPhaseController();

  static const Map<TripStatus, Set<TripStatus>> _allowed = {
    TripStatus.unassigned: {TripStatus.assigned, TripStatus.cancelled},
    TripStatus.assigned: {TripStatus.going, TripStatus.cancelled},
    TripStatus.going: {TripStatus.atDestination},
    TripStatus.atDestination: {TripStatus.returning},
    TripStatus.returning: {TripStatus.completed},
    TripStatus.completed: {},
    TripStatus.cancelled: {},
  };

  bool canTransition(TripStatus from, TripStatus to) {
    return _allowed[from]?.contains(to) ?? false;
  }

  void ensureCanTransition(TripStatus from, TripStatus to) {
    if (!canTransition(from, to)) {
      throw const InvalidStateFailure();
    }
  }

  bool canAssign(TripStatus status) =>
      canTransition(status, TripStatus.assigned);

  /// Reassign keeps [TripStatus.assigned]; it is not a status transition.
  bool canReassign(TripStatus status) => status == TripStatus.assigned;

  bool canCancel(TripStatus status) =>
      canTransition(status, TripStatus.cancelled);

  bool canStartTrip(TripStatus status) =>
      canTransition(status, TripStatus.going);

  bool canArriveAtDestination(TripStatus status) =>
      canTransition(status, TripStatus.atDestination);

  bool canStartReturn(TripStatus status) =>
      canTransition(status, TripStatus.returning);

  bool canEndTrip(TripStatus status) =>
      canTransition(status, TripStatus.completed);

  /// Next driver action for [status], or null when none.
  TripPhaseAction? actionFor(TripStatus status) {
    return switch (status) {
      TripStatus.assigned => TripPhaseAction.startTrip,
      TripStatus.going => TripPhaseAction.arriveAtDestination,
      TripStatus.atDestination => TripPhaseAction.startReturn,
      TripStatus.returning => TripPhaseAction.endTrip,
      _ => null,
    };
  }
}

/// Driver-facing phase buttons driven by [TripPhaseController].
enum TripPhaseAction { startTrip, arriveAtDestination, startReturn, endTrip }
