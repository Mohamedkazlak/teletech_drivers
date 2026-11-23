import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/config/app_config.dart';
import 'package:teletech_drivers/core/network/network_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/attendance/presentation/providers/attendance_providers.dart';
import 'package:teletech_drivers/features/driver/presentation/providers/driver_period_providers.dart';
import 'package:teletech_drivers/features/realtime/data/clients/disabled_realtime_client.dart';
import 'package:teletech_drivers/features/realtime/data/clients/pusher_realtime_client.dart';
import 'package:teletech_drivers/features/realtime/domain/entities/realtime_connection.dart';
import 'package:teletech_drivers/features/realtime/domain/entities/realtime_event.dart';
import 'package:teletech_drivers/features/realtime/domain/repositories/realtime_client.dart';
import 'package:teletech_drivers/features/realtime/domain/services/realtime_channels.dart';
import 'package:teletech_drivers/features/realtime/domain/services/realtime_refresh_plan.dart';
import 'package:teletech_drivers/features/tracking/presentation/providers/tracking_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/controllers/created_by_me_trips_controller.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

/// Dependency Injection: Riverpod. Tests keep the disabled client.
final realtimeClientProvider = Provider<RealtimeClient>((ref) {
  return const DisabledRealtimeClient();
});

/// The live client used by [main]. Empty key keeps the socket off.
RealtimeClient buildPusherRealtimeClient(Ref ref) {
  if (AppConfig.reverbAppKey.isEmpty) {
    return const DisabledRealtimeClient();
  }
  final client = PusherRealtimeClient(
    api: ref.watch(apiClientProvider),
    host: AppConfig.reverbHost,
    port: AppConfig.reverbPort,
    appKey: AppConfig.reverbAppKey,
    useTls: AppConfig.reverbUseTls,
  );
  ref.onDispose(() {
    unawaited(client.disconnect());
  });
  return client;
}

/// Observer: socket lifecycle for the signed-in user. Reconnects when the app resumes.
final realtimeSessionProvider =
    NotifierProvider<RealtimeSession, RealtimeConnection>(RealtimeSession.new);

class RealtimeSession extends Notifier<RealtimeConnection> {
  StreamSubscription<RealtimeConnection>? _connectionSub;
  StreamSubscription<RealtimeEvent>? _eventSub;
  AppLifecycleListener? _lifecycle;
  RealtimeClient? _client;

  @override
  RealtimeConnection build() {
    ref.onDispose(_stop);
    _lifecycle = AppLifecycleListener(
      onResume: () {
        final client = _client;
        if (client == null || !client.isEnabled) return;
        unawaited(client.reconnect());
      },
    );
    final user = ref.watch(currentUserProvider).asData?.value;
    if (user == null) return RealtimeConnection.disabled;

    final client = ref.watch(realtimeClientProvider);
    if (!client.isEnabled) return RealtimeConnection.disabled;

    _client = client;
    _connectionSub = client.connection.listen((next) {
      state = next;
    });
    _eventSub = client.events.listen(_onEvent);
    unawaited(client.connect(channels: channelsForUser(user)));
    return RealtimeConnection.connecting;
  }

  void _onEvent(RealtimeEvent event) {
    final scopes = scopesForRealtimeEvent(event.name);
    if (scopes.contains(RealtimeScope.tripRequests)) {
      _refreshTripRequests();
    }
    if (scopes.contains(RealtimeScope.trips)) {
      _refreshTrips();
    }
    if (scopes.contains(RealtimeScope.attendance)) {
      _refreshAttendance();
    }
    if (scopes.contains(RealtimeScope.liveMap)) {
      ref.invalidate(adminLiveMapLocationsProvider);
    }
  }

  void _refreshTripRequests() {
    ref.invalidate(myTripRequestsProvider);
    ref.invalidate(awaitingConfirmationProvider);
    ref.invalidate(employeeTripRequestsProvider);
    ref.invalidate(pendingTripRequestsProvider);
    ref.invalidate(adminTripRequestsProvider);
    ref.invalidate(allTripRequestsProvider);
    ref.invalidate(approvedAwaitingTripRequestsProvider);
    ref.invalidate(pendingGroupingSuggestionsProvider);
    ref.invalidate(approvedGroupingSuggestionsProvider);
    ref.invalidate(tripRequestsByIdsProvider);
    ref.invalidate(tripRequestByIdProvider);
    ref.invalidate(watchTripRequestByIdProvider);
  }

  void _refreshTrips() {
    ref.invalidate(tripsQueryProvider);
    ref.invalidate(allTripsProvider);
    ref.invalidate(tripByIdProvider);
    ref.invalidate(watchTripByIdProvider);
    ref.invalidate(tripReportProvider);
    ref.invalidate(driverRecommendationsProvider);
    ref.invalidate(driverTripsProvider);
    ref.invalidate(driverMineTripsProvider);
    ref.invalidate(createdByMeTripsProvider);
  }

  void _refreshAttendance() {
    ref.invalidate(attendanceTodayProvider);
    ref.invalidate(myAttendanceProvider);
    ref.invalidate(driverAttendanceProvider);
    ref.invalidate(attendanceSummaryProvider);
  }

  void _stop() {
    _lifecycle?.dispose();
    _lifecycle = null;
    unawaited(_connectionSub?.cancel());
    unawaited(_eventSub?.cancel());
    _connectionSub = null;
    _eventSub = null;
    final client = _client;
    _client = null;
    if (client != null && client.isEnabled) {
      unawaited(client.disconnect());
    }
  }
}

/// Keeps the socket alive for the signed-in session. Call from the app root.
void watchRealtimeSession(WidgetRef ref) {
  ref.watch(realtimeSessionProvider);
}
