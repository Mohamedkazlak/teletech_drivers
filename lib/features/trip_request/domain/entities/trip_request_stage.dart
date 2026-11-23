/// `stage` query on `GET /trip-requests` for Drivers Admin.
enum TripRequestStage {
  needsDriver('needs_driver'),
  assigned('assigned');

  const TripRequestStage(this.apiValue);

  final String apiValue;
}
