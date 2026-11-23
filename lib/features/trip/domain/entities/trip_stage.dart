/// `stage` query on `GET /trips`.
enum TripStage {
  unassigned('unassigned'),
  assigned('assigned'),
  inProgress('in_progress'),
  completed('completed'),
  awaitingReport('awaiting_report');

  const TripStage(this.apiValue);

  final String apiValue;
}
