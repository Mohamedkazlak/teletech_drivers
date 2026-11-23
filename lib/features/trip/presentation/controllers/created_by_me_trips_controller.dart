import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/constants/polling_intervals.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/trip/data/providers/trip_repository_provider.dart';
import 'package:teletech_drivers/features/trip/domain/entities/created_trip_bucket.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/use_cases/list_created_by_me_trips.dart';

/// Accumulated pages for one created-by-me bucket.
class CreatedByMeList {
  const CreatedByMeList({
    required this.trips,
    required this.page,
    required this.hasMore,
    this.loadingMore = false,
  });

  final List<Trip> trips;
  final int page;
  final bool hasMore;
  final bool loadingMore;
}

final listCreatedByMeTripsUseCaseProvider =
    Provider<ListCreatedByMeTripsUseCase>((ref) {
      return ListCreatedByMeTripsUseCase(ref.watch(tripRepositoryProvider));
    });

final createdByMeTripsProvider = AsyncNotifierProvider.autoDispose
    .family<CreatedByMeTripsController, CreatedByMeList, CreatedTripBucket>(
      CreatedByMeTripsController.new,
    );

class CreatedByMeTripsController extends AsyncNotifier<CreatedByMeList> {
  CreatedByMeTripsController(this.bucket);

  final CreatedTripBucket bucket;

  @override
  Future<CreatedByMeList> build() {
    final timer = Timer.periodic(PollingIntervals.tripLists, (_) {
      if (state.asData?.value.loadingMore == true) return;
      ref.invalidateSelf();
    });
    final lifecycle = AppLifecycleListener(
      onResume: () {
        if (state.asData?.value.loadingMore == true) return;
        ref.invalidateSelf();
      },
    );
    ref.onDispose(() {
      timer.cancel();
      lifecycle.dispose();
    });
    return _load(page: 1, existing: const []);
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null || !current.hasMore || current.loadingMore) return;
    state = AsyncData(
      CreatedByMeList(
        trips: current.trips,
        page: current.page,
        hasMore: current.hasMore,
        loadingMore: true,
      ),
    );
    state = await AsyncValue.guard(
      () => _load(page: current.page + 1, existing: current.trips),
    );
  }

  Future<CreatedByMeList> _load({
    required int page,
    required List<Trip> existing,
  }) async {
    try {
      final result = await ref.read(listCreatedByMeTripsUseCaseProvider)(
        bucket: bucket,
        page: page,
      );
      return CreatedByMeList(
        trips: [...existing, ...result.trips],
        page: result.currentPage,
        hasMore: result.hasMore,
      );
    } on Failure {
      rethrow;
    }
  }
}
