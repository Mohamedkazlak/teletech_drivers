import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/presentation/fleet_period_controller.dart';
import 'package:teletech_drivers/core/time/fleet_period.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_bound_stream.dart';
import 'package:teletech_drivers/features/trip/data/providers/trip_repository_provider.dart';
import 'package:teletech_drivers/features/trip/domain/entities/mine_trips_filter.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/watch_my_trips.dart';

/// Dependency Injection: Riverpod.
final watchMyTripsUseCaseProvider = Provider<WatchMyTripsUseCase>((ref) {
  return WatchMyTripsUseCase(ref.watch(tripRepositoryProvider));
});

/// Assigned trips: week or month.
final assignedTripsPeriodProvider =
    NotifierProvider<FleetPeriodController, FleetPeriodAnchor>(
      () => FleetPeriodController(
        allowed: const [FleetPeriodKind.week, FleetPeriodKind.month],
      ),
    );

/// Completed trips: week, month, or year.
final completedTripsPeriodProvider =
    NotifierProvider<FleetPeriodController, FleetPeriodAnchor>(
      () => FleetPeriodController(
        allowed: const [
          FleetPeriodKind.week,
          FleetPeriodKind.month,
          FleetPeriodKind.year,
        ],
      ),
    );

/// Observer: `/trips/mine` for one status and fleet period.
final driverMineTripsProvider = StreamProvider.autoDispose
    .family<List<Trip>, MineTripsFilter>((ref, filter) {
      return authBoundStream(
        ref,
        whenSignedOut: const <Trip>[],
        create: (_) => ref.watch(watchMyTripsUseCaseProvider)(filter),
      );
    }, retry: (_, _) => null);
