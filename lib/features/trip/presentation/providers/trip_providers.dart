import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_bound_stream.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_recommendation.dart';
import 'package:teletech_drivers/features/trip/data/providers/trip_repository_provider.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_list_query.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_report.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/grouped_requests.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/one_request_per_trip.dart';
import 'package:teletech_drivers/features/trip/domain/strategies/trip_grouping_strategy.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/arrive_at_destination.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/assign_driver.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/cancel_trip.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/create_trips_from_requests.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/end_trip.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/get_driver_recommendations.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/get_trip_by_id.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/get_trip_report.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/reassign_driver.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/start_return.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/start_trip.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/watch_all_trips.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/watch_trips.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/watch_trip_by_id.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/watch_trips_by_driver.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/watch_trips_by_status.dart';

final createTripsFromRequestsUseCaseProvider =
    Provider<CreateTripsFromRequestsUseCase>((ref) {
      return CreateTripsFromRequestsUseCase(ref.watch(tripRepositoryProvider));
    });

final watchAllTripsUseCaseProvider = Provider<WatchAllTripsUseCase>((ref) {
  return WatchAllTripsUseCase(ref.watch(tripRepositoryProvider));
});

final watchTripsUseCaseProvider = Provider<WatchTripsUseCase>((ref) {
  return WatchTripsUseCase(ref.watch(tripRepositoryProvider));
});

final watchTripsByStatusUseCaseProvider = Provider<WatchTripsByStatusUseCase>((
  ref,
) {
  return WatchTripsByStatusUseCase(ref.watch(tripRepositoryProvider));
});

final getTripByIdUseCaseProvider = Provider<GetTripByIdUseCase>((ref) {
  return GetTripByIdUseCase(ref.watch(tripRepositoryProvider));
});

final watchTripByIdUseCaseProvider = Provider<WatchTripByIdUseCase>((ref) {
  return WatchTripByIdUseCase(ref.watch(tripRepositoryProvider));
});

final getTripReportUseCaseProvider = Provider<GetTripReportUseCase>((ref) {
  return GetTripReportUseCase(ref.watch(tripRepositoryProvider));
});

final getDriverRecommendationsUseCaseProvider =
    Provider<GetDriverRecommendationsUseCase>((ref) {
      return GetDriverRecommendationsUseCase(ref.watch(tripRepositoryProvider));
    });

final assignDriverUseCaseProvider = Provider<AssignDriverUseCase>((ref) {
  return AssignDriverUseCase(ref.watch(tripRepositoryProvider));
});

final reassignDriverUseCaseProvider = Provider<ReassignDriverUseCase>((ref) {
  return ReassignDriverUseCase(ref.watch(tripRepositoryProvider));
});

final cancelTripUseCaseProvider = Provider<CancelTripUseCase>((ref) {
  return CancelTripUseCase(ref.watch(tripRepositoryProvider));
});

final watchTripsByDriverUseCaseProvider = Provider<WatchTripsByDriverUseCase>((
  ref,
) {
  return WatchTripsByDriverUseCase(ref.watch(tripRepositoryProvider));
});

final startTripUseCaseProvider = Provider<StartTripUseCase>((ref) {
  return StartTripUseCase(ref.watch(tripRepositoryProvider));
});

final arriveAtDestinationUseCaseProvider = Provider<ArriveAtDestinationUseCase>(
  (ref) {
    return ArriveAtDestinationUseCase(ref.watch(tripRepositoryProvider));
  },
);

final startReturnUseCaseProvider = Provider<StartReturnUseCase>((ref) {
  return StartReturnUseCase(ref.watch(tripRepositoryProvider));
});

final endTripUseCaseProvider = Provider<EndTripUseCase>((ref) {
  return EndTripUseCase(ref.watch(tripRepositoryProvider));
});

/// Strategy: one trip document per selected request.
final oneRequestPerTripStrategyProvider = Provider<TripGroupingStrategy>((ref) {
  return const OneRequestPerTrip();
});

/// Strategy: all selected requests share one trip document.
final groupedRequestsStrategyProvider = Provider<TripGroupingStrategy>((ref) {
  return const GroupedRequests();
});

/// Observer: trips for one stage and branch. Dependency Injection: Riverpod.
final tripsQueryProvider = StreamProvider.autoDispose
    .family<List<Trip>, TripListQuery>((ref, query) {
      return authBoundStream(
        ref,
        whenSignedOut: const <Trip>[],
        create: (_) => ref.watch(watchTripsUseCaseProvider)(query),
      );
    }, retry: (_, _) => null);

/// Observer: all trips for company admin, newest first.
/// Dependency Injection: Riverpod.
final allTripsProvider = StreamProvider.autoDispose<List<Trip>>((ref) {
  return authBoundStream(
    ref,
    whenSignedOut: const <Trip>[],
    create: (_) => ref.watch(watchAllTripsUseCaseProvider)(),
  );
}, retry: (_, _) => null);

/// Loads a single trip for the details screen (one-shot).
final tripByIdProvider = FutureProvider.autoDispose.family<Trip?, String>((
  ref,
  tripId,
) {
  return ref.watch(getTripByIdUseCaseProvider)(tripId);
});

/// Observer: live trip document for in-progress report refresh.
final watchTripByIdProvider = StreamProvider.autoDispose.family<Trip?, String>((
  ref,
  tripId,
) {
  return authBoundStream(
    ref,
    whenSignedOut: null,
    create: (_) => ref.watch(watchTripByIdUseCaseProvider)(tripId),
  );
}, retry: (_, _) => null);

/// Server-built report (durations, distances, route geometry) for [tripId].
///
/// Refetches when the trip moves to another phase.
final tripReportProvider = FutureProvider.autoDispose.family<TripReport, String>((
  ref,
  tripId,
) {
  ref.watch(
    watchTripByIdProvider(tripId).select((trip) => trip.asData?.value?.status),
  );
  return ref.watch(getTripReportUseCaseProvider)(tripId);
});

/// Server-ranked driver candidates for assigning / reassigning [tripId].
final driverRecommendationsProvider = FutureProvider.autoDispose
    .family<List<DriverRecommendation>, String>((ref, tripId) {
      return ref.watch(getDriverRecommendationsUseCaseProvider)(tripId);
    });

/// Trips filtered by status for drivers-admin tabs.
///
/// Filters [allTripsProvider] client-side so the Unassigned / Assigned tabs
/// work from the already loaded trip list.
final tripsByStatusProvider = Provider.autoDispose
    .family<AsyncValue<List<Trip>>, TripStatus>((ref, status) {
      return ref
          .watch(allTripsProvider)
          .whenData(
            (trips) => [
              for (final trip in trips)
                if (trip.status == status) trip,
            ],
          );
    });

/// Observer: trips assigned to [driverId].
/// Dependency Injection: Riverpod.
final driverTripsProvider = StreamProvider.autoDispose
    .family<List<Trip>, String>((ref, driverId) {
      return authBoundStream(
        ref,
        whenSignedOut: const <Trip>[],
        create: (_) => ref.watch(watchTripsByDriverUseCaseProvider)(driverId),
      );
    }, retry: (_, _) => null);

/// In-progress trips across going / atDestination / returning.
final inProgressTripsProvider = Provider.autoDispose<AsyncValue<List<Trip>>>((
  ref,
) {
  return ref.watch(allTripsProvider).whenData((trips) {
    return [
      for (final trip in trips)
        if (trip.status.isInProgress) trip,
    ];
  });
});
