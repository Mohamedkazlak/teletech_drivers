/// Ordered steps for following a trip request through to completion.
enum RequestProgressStepId {
  requested,
  approved,
  driverAssigned,
  going,
  arrived,
  returning,
  completed,
}
