/// State: lifecycle of a company trip.
enum TripStatus {
  unassigned,
  assigned,
  going,
  atDestination,
  returning,
  completed,
  cancelled;

  /// Driver is between Start trip and End trip (includes waiting at destination).
  bool get isInProgress =>
      this == going || this == atDestination || this == returning;

  /// GPS tracking should run for these statuses.
  bool get isActivelyTracking => this == going || this == returning;
}
