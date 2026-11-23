/// Which screens a broadcast should refresh.
enum RealtimeScope { tripRequests, trips, attendance, liveMap }

/// Maps a broadcast name to the providers that must reload.
Set<RealtimeScope> scopesForRealtimeEvent(String name) {
  if (name.startsWith('trip-request.')) {
    return {RealtimeScope.tripRequests, RealtimeScope.trips};
  }
  if (name.startsWith('trip.')) {
    return {RealtimeScope.trips, RealtimeScope.tripRequests};
  }
  if (name.startsWith('attendance.')) {
    return {RealtimeScope.attendance};
  }
  if (name == 'driver-location.updated') {
    return {RealtimeScope.liveMap};
  }
  return const {};
}
