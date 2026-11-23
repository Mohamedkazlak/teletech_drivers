import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/tracking/presentation/state/location_tracking_state.dart';

/// One sentence for the driver when live GPS cannot be shared or sent.
String locationSharingBannerText(
  AppLocalizations l10n,
  LocationTrackingState tracking,
) {
  return switch (tracking.status) {
    LocationTrackingStatus.permissionDenied =>
      l10n.locationPermissionDeniedMessage,
    LocationTrackingStatus.permissionPermanentlyDenied =>
      l10n.locationPermissionPermanentlyDeniedMessage,
    LocationTrackingStatus.servicesDisabled =>
      l10n.locationServicesDisabledMessage,
    _ when tracking.position != null && tracking.failure != null =>
      l10n.locationUpdateKeptLast,
    _ => l10n.locationSharingWarning,
  };
}
