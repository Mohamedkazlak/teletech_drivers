/// Company-admin trip list filter. Matches the API `lifecycle` query.
enum TripLifecycle {
  upcoming('upcoming'),
  inProgress('in_progress'),
  completed('completed'),
  cancelled('cancelled');

  const TripLifecycle(this.apiValue);

  final String apiValue;
}
