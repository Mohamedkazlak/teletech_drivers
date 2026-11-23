import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_bound_stream.dart';
import 'package:teletech_drivers/features/trip_request/data/providers/trip_request_repository_provider.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/group_suggestion.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_query.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_stage.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_status.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/approve_pending_trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/approve_pending_trip_requests_as_group.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/cancel_pending_trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/create_trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/get_grouping_suggestions.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/get_trip_requests_by_ids.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/reject_pending_trip_request.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/watch_all_trip_requests.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/watch_trip_requests.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/watch_approved_awaiting_trip_requests.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_request_list_bucket.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/confirm_trip.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/watch_awaiting_confirmation.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/watch_employee_trip_requests.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/watch_my_trip_requests.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/watch_pending_trip_requests.dart';
import 'package:teletech_drivers/features/trip_request/domain/use_cases/watch_trip_request_by_id.dart';

final createTripRequestUseCaseProvider = Provider<CreateTripRequestUseCase>((
  ref,
) {
  return CreateTripRequestUseCase(ref.watch(tripRequestRepositoryProvider));
});

final watchEmployeeTripRequestsUseCaseProvider =
    Provider<WatchEmployeeTripRequestsUseCase>((ref) {
      return WatchEmployeeTripRequestsUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final watchMyTripRequestsUseCaseProvider = Provider<WatchMyTripRequestsUseCase>(
  (ref) {
    return WatchMyTripRequestsUseCase(
      ref.watch(tripRequestRepositoryProvider),
    );
  },
);

final watchAwaitingConfirmationUseCaseProvider =
    Provider<WatchAwaitingConfirmationUseCase>((ref) {
      return WatchAwaitingConfirmationUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final confirmTripUseCaseProvider = Provider<ConfirmTripUseCase>((ref) {
  return ConfirmTripUseCase(ref.watch(tripRequestRepositoryProvider));
});

final watchTripRequestByIdUseCaseProvider =
    Provider<WatchTripRequestByIdUseCase>((ref) {
      return WatchTripRequestByIdUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final watchPendingTripRequestsUseCaseProvider =
    Provider<WatchPendingTripRequestsUseCase>((ref) {
      return WatchPendingTripRequestsUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final watchApprovedAwaitingTripRequestsUseCaseProvider =
    Provider<WatchApprovedAwaitingTripRequestsUseCase>((ref) {
      return WatchApprovedAwaitingTripRequestsUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final watchAllTripRequestsUseCaseProvider =
    Provider<WatchAllTripRequestsUseCase>((ref) {
      return WatchAllTripRequestsUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final watchTripRequestsUseCaseProvider = Provider<WatchTripRequestsUseCase>((
  ref,
) {
  return WatchTripRequestsUseCase(ref.watch(tripRequestRepositoryProvider));
});

final cancelPendingTripRequestUseCaseProvider =
    Provider<CancelPendingTripRequestUseCase>((ref) {
      return CancelPendingTripRequestUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final approvePendingTripRequestUseCaseProvider =
    Provider<ApprovePendingTripRequestUseCase>((ref) {
      return ApprovePendingTripRequestUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final approvePendingTripRequestsAsGroupUseCaseProvider =
    Provider<ApprovePendingTripRequestsAsGroupUseCase>((ref) {
      return ApprovePendingTripRequestsAsGroupUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final rejectPendingTripRequestUseCaseProvider =
    Provider<RejectPendingTripRequestUseCase>((ref) {
      return RejectPendingTripRequestUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final getGroupingSuggestionsUseCaseProvider =
    Provider<GetGroupingSuggestionsUseCase>((ref) {
      return GetGroupingSuggestionsUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

final getTripRequestsByIdsUseCaseProvider =
    Provider<GetTripRequestsByIdsUseCase>((ref) {
      return GetTripRequestsByIdsUseCase(
        ref.watch(tripRequestRepositoryProvider),
      );
    });

/// Observer: own requests for one My Trips tab. Null is every request.
/// Dependency Injection: Riverpod.
final myTripRequestsProvider = StreamProvider.autoDispose
    .family<List<TripRequest>, TripRequestListBucket?>((ref, bucket) {
      return authBoundStream(
        ref,
        whenSignedOut: const <TripRequest>[],
        create: (_) => ref.watch(watchMyTripRequestsUseCaseProvider)(bucket),
      );
    }, retry: (_, _) => null);

/// Observer: completed trips still waiting for the employee's report.
final awaitingConfirmationProvider =
    StreamProvider.autoDispose<List<TripRequest>>((ref) {
      return authBoundStream(
        ref,
        whenSignedOut: const <TripRequest>[],
        create: (_) => ref.watch(watchAwaitingConfirmationUseCaseProvider)(),
      );
    }, retry: (_, _) => null);

/// Observer: the signed-in employee's trip requests, newest first.
/// Dependency Injection: Riverpod.
final employeeTripRequestsProvider =
    StreamProvider.autoDispose<List<TripRequest>>((ref) {
      return authBoundStream(
        ref,
        whenSignedOut: const <TripRequest>[],
        create: (user) =>
            ref.watch(watchEmployeeTripRequestsUseCaseProvider)(user.id),
      );
    }, retry: (_, _) => null);

/// Observer: pending requests for company admin, earliest requested time first.
/// Dependency Injection: Riverpod.
final pendingTripRequestsProvider =
    StreamProvider.autoDispose<List<TripRequest>>((ref) {
      return authBoundStream(
        ref,
        whenSignedOut: const <TripRequest>[],
        create: (_) => ref.watch(watchPendingTripRequestsUseCaseProvider)(),
      );
    }, retry: (_, _) => null);

/// Observer: one admin queue. Status, stage, and branch are server filters.
final adminTripRequestsProvider = StreamProvider.autoDispose
    .family<List<TripRequest>, TripRequestListQuery>((ref, query) {
      return authBoundStream(
        ref,
        whenSignedOut: const <TripRequest>[],
        create: (_) => ref.watch(watchTripRequestsUseCaseProvider)(query),
      );
    }, retry: (_, _) => null);

/// Observer: all requests for company admin status filters.
final allTripRequestsProvider = StreamProvider.autoDispose<List<TripRequest>>((
  ref,
) {
  return authBoundStream(
    ref,
    whenSignedOut: const <TripRequest>[],
    create: (_) => ref.watch(watchAllTripRequestsUseCaseProvider)(),
  );
}, retry: (_, _) => null);

/// Observer: approved requests not yet in a trip (Drivers Admin).
final approvedAwaitingTripRequestsProvider =
    StreamProvider.autoDispose<List<TripRequest>>((ref) {
      return authBoundStream(
        ref,
        whenSignedOut: const <TripRequest>[],
        create: (_) =>
            ref.watch(watchApprovedAwaitingTripRequestsUseCaseProvider)(),
      );
    }, retry: (_, _) => null);

/// Server clusters of pending requests (Company Admin), optionally limited to
/// requests of one [Branch].
final pendingGroupingSuggestionsProvider = FutureProvider.autoDispose
    .family<List<GroupSuggestion>, Branch?>((ref, branch) async {
      final requests = await ref.watch(
        adminTripRequestsProvider(
          TripRequestListQuery(
            status: TripRequestStatus.pending,
            branch: branch,
          ),
        ).future,
      );
      return _suggestGroups(ref, requests, branch);
    });

/// Server clusters of approved requests awaiting a trip (Drivers Admin),
/// optionally limited to requests of one [Branch].
final approvedGroupingSuggestionsProvider = FutureProvider.autoDispose
    .family<List<GroupSuggestion>, Branch?>((ref, branch) async {
      final requests = await ref.watch(
        adminTripRequestsProvider(
          TripRequestListQuery(
            stage: TripRequestStage.needsDriver,
            branch: branch,
          ),
        ).future,
      );
      return _suggestGroups(ref, requests, null);
    });

Future<List<GroupSuggestion>> _suggestGroups(
  Ref ref,
  List<TripRequest> requests,
  Branch? branch,
) async {
  final known = [
    for (final request in requests)
      if (branch == null || request.employeeBranch == branch) request,
  ];
  // Fewer than two requests can never form a cluster; skip the round trip.
  if (known.length < 2) return const [];
  return ref.read(getGroupingSuggestionsUseCaseProvider)(known);
}

/// Loads the trip requests linked to a trip details screen.
/// [joinedIds] is a comma-separated list of request document ids.
final tripRequestsByIdsProvider = FutureProvider.autoDispose
    .family<List<TripRequest>, String>((ref, joinedIds) {
      final requestIds = joinedIds.isEmpty
          ? const <String>[]
          : joinedIds.split(',');
      return ref.watch(getTripRequestsByIdsUseCaseProvider)(requestIds);
    });

/// Single request by id (from the all-requests stream or a one-off fetch).
final tripRequestByIdProvider = FutureProvider.autoDispose
    .family<TripRequest?, String>((ref, requestId) async {
      if (requestId.isEmpty) return null;
      final results = await ref.watch(getTripRequestsByIdsUseCaseProvider)([
        requestId,
      ]);
      return results.where((item) => item.id == requestId).firstOrNull;
    });

/// Observer: live single trip request (details / progress screens).
/// Dependency Injection: Riverpod. autoDispose cancels the snapshot on leave.
final watchTripRequestByIdProvider = StreamProvider.autoDispose
    .family<TripRequest?, String>((ref, requestId) {
      return authBoundStream(
        ref,
        whenSignedOut: null,
        create: (_) =>
            ref.watch(watchTripRequestByIdUseCaseProvider)(requestId),
      );
    }, retry: (_, _) => null);
