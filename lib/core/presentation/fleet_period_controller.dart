import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/time/fleet_period.dart';

/// State: the fleet period currently shown on a driver screen.
class FleetPeriodController extends Notifier<FleetPeriodAnchor> {
  FleetPeriodController({required this.allowed});

  final List<FleetPeriodKind> allowed;

  @override
  FleetPeriodAnchor build() {
    final now = DateTime.now();
    return FleetPeriodAnchor(
      kind: allowed.first,
      day: FleetPeriodAnchor.dateOnly(now),
    );
  }

  void select(FleetPeriodKind kind) {
    if (!allowed.contains(kind) || kind == state.kind) return;
    state = FleetPeriodAnchor(kind: kind, day: state.day);
  }

  void previous() {
    if (!state.canShift) return;
    state = state.shift(-1);
  }

  void next() {
    if (!state.canGoForward(DateTime.now())) return;
    state = state.shift(1);
  }
}
