import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/navigation/nav_label_key.dart';

/// Maps a [NavLabelKey] to the current locale. No raw strings in widgets.
String navLabel(AppLocalizations l10n, NavLabelKey key) {
  return switch (key) {
    NavLabelKey.myTrips => l10n.navMyTrips,
    NavLabelKey.trips => l10n.navTrips,
    NavLabelKey.requests => l10n.navRequests,
    NavLabelKey.requestedTrips => l10n.navRequestedTrips,
    NavLabelKey.attendance => l10n.navAttendance,
    NavLabelKey.assignedTrips => l10n.navAssignedTrips,
    NavLabelKey.completedTrips => l10n.navCompletedTrips,
    NavLabelKey.stats => l10n.navStats,
    NavLabelKey.places => l10n.navPlaces,
    NavLabelKey.myRequests => l10n.navMyRequests,
    NavLabelKey.drivers => l10n.navDrivers,
    NavLabelKey.liveMap => l10n.navLiveMap,
    NavLabelKey.dashboard => l10n.navDashboard,
    NavLabelKey.employees => l10n.navEmployees,
    NavLabelKey.users => l10n.navUsers,
    NavLabelKey.attendanceBoard => l10n.navAttendance,
    NavLabelKey.profile => l10n.navProfile,
    NavLabelKey.settings => l10n.navSettings,
    NavLabelKey.more => l10n.navMore,
  };
}
