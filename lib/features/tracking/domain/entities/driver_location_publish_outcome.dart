/// Result of one live-location publish.
enum DriverLocationPublishOutcome {
  /// The sample was stored.
  published,

  /// 422 accuracy (or invalid sample): skip without an error banner.
  skipped,

  /// 429: wait for the next throttle tick.
  backedOff,
}
