import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/trip_request/presentation/models/place_selection.dart';

/// Form validators for creating a trip request.
abstract final class TripRequestValidators {
  static String? pickupPlace(PlaceSelection? value, AppLocalizations l10n) {
    if (value == null) {
      return l10n.validationPickupPlaceRequired;
    }
    if (value is ApprovedPlaceSelection && !value.place.hasCoordinates) {
      return l10n.placeCannotSelectWithoutLocation;
    }
    if (value is CustomPlaceSelection && !value.hasName) {
      return l10n.validationCustomPlaceRequired;
    }
    return null;
  }

  static String? destinationPlace(
    PlaceSelection? value,
    AppLocalizations l10n, {
    PlaceSelection? pickup,
  }) {
    if (value == null) {
      return l10n.validationDestinationPlaceRequired;
    }
    if (value is ApprovedPlaceSelection && !value.place.hasCoordinates) {
      return l10n.placeCannotSelectWithoutLocation;
    }
    if (value is CustomPlaceSelection && !value.hasName) {
      return l10n.validationCustomPlaceRequired;
    }
    if (PlaceSelection.isSame(pickup, value)) {
      return l10n.validationPickupDestinationSame;
    }
    return null;
  }

  static String? requestedDateTime(
    DateTime? value,
    AppLocalizations l10n, {
    DateTime? now,
  }) {
    if (value == null) {
      return l10n.validationDateTimeRequired;
    }
    final current = (now ?? DateTime.now()).toUtc();
    if (!value.toUtc().isAfter(current)) {
      return l10n.validationDateTimeFuture;
    }
    return null;
  }
}
