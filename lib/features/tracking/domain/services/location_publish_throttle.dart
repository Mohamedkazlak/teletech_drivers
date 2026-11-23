import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';

/// Decides when the next live-location sample may be sent.
///
/// The first sample (and an explicit force) is immediate. Later samples wait
/// for [interval], or send early after [MapDefaults.publishDistanceMeters]
/// once [MapDefaults.publishMinGap] has passed. A recorded attempt — including
/// a skipped or rate-limited one — holds the next send until then.
class LocationPublishThrottle {
  LocationPublishThrottle({this.interval = MapDefaults.publishThrottle});

  final Duration interval;

  DateTime? _lastAttempt;
  var _publishedOnce = false;

  bool get hasPublishedOnce => _publishedOnce;

  bool shouldSend(
    DateTime now, {
    required bool force,
    double movedMeters = 0,
  }) {
    if (force || !_publishedOnce || _lastAttempt == null) return true;
    final elapsed = now.difference(_lastAttempt!);
    if (elapsed >= interval) return true;
    return movedMeters >= MapDefaults.publishDistanceMeters &&
        elapsed >= MapDefaults.publishMinGap;
  }

  void recordAttempt(DateTime now) {
    _lastAttempt = now;
    _publishedOnce = true;
  }

  void reset() {
    _lastAttempt = null;
    _publishedOnce = false;
  }
}
