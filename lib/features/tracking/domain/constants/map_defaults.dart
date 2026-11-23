import 'package:latlong2/latlong.dart';

/// Editable map defaults for driver and admin live maps.
abstract final class MapDefaults {
  /// Fallback center when no active drivers are available (Riyadh).
  static const LatLng defaultCenter = LatLng(24.7136, 46.6753);

  static const double defaultZoom = 12;

  /// Soft-disable OSRM route polylines without removing the integration.
  static const bool enableOsrmRouting = true;

  /// Heartbeat for live location publishes while a trip is active.
  ///
  /// A fix is also sent sooner when the driver has moved
  /// [publishDistanceMeters], but not faster than [publishMinGap]
  /// (the API allows 12 publishes per minute).
  static const Duration publishThrottle = Duration(seconds: 8);

  /// Soonest a second publish may follow the previous one.
  static const Duration publishMinGap = Duration(seconds: 6);

  /// Movement that publishes early, without waiting for [publishThrottle].
  static const double publishDistanceMeters = 20;

  /// Native GPS interval. Distance filter stays 0 so a stopped car still
  /// produces this heartbeat; Dart decides what is worth sending.
  static const Duration streamInterval = Duration(seconds: 5);

  static const double maxAcceptedAccuracyMeters = 50;

  /// Foreground-service notification (no BuildContext — keep bilingual).
  static const String fgsNotificationTitle =
      'TeleTech · Trip in progress / رحلة جارية';

  static const String fgsNotificationText =
      'Sharing location with dispatch · جارٍ مشاركة الموقع مع المرسل';

  /// Legacy cache key threshold used by older OSRM callers.
  static const double osrmRerouteDistanceMeters = 100;

  /// Off-route distance that may trigger a throttled reroute.
  static const double offRouteThresholdMeters = 150;

  /// Max frequency for automatic OSRM re-fetches when off-route.
  static const Duration rerouteCooldown = Duration(seconds: 30);

  static const Duration osrmTimeout = Duration(seconds: 10);

  /// One-shot GPS fix timeout on live-map open (~15 s) with retry UI.
  static const Duration currentPositionTimeout = Duration(seconds: 15);

  static const double arrivalRadiusMeters = 100;

  static const int streamDistanceFilterMeters = 0;

  static const String osmTileUrl =
      'https://tile.openstreetmap.org/{z}/{x}/{y}.png';

  static const String userAgentPackageName = 'com.teletech.teletech_drivers';

  static const String osrmUserAgent =
      'TeleTechDrivers/1.0 (com.teletech.teletech_drivers)';
}
