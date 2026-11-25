// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'TeleCars';

  @override
  String get languageEnglish => 'English';

  @override
  String get languageArabic => 'Arabic';

  @override
  String get loginTitle => 'Sign in';

  @override
  String get loginSubtitle => 'Sign in with your company account.';

  @override
  String get registerTitle => 'Employee registration';

  @override
  String get registerSubtitle => 'New accounts are created as employees.';

  @override
  String get nameLabel => 'Name';

  @override
  String get emailLabel => 'Email';

  @override
  String get passwordLabel => 'Password';

  @override
  String get confirmPasswordLabel => 'Confirm password';

  @override
  String get signIn => 'Sign in';

  @override
  String get signOut => 'Sign out';

  @override
  String get createEmployeeAccount => 'Create an employee account';

  @override
  String get alreadyHaveAccount => 'Already have an account? Sign in';

  @override
  String get validationNameRequired => 'Enter your name.';

  @override
  String get validationEmailRequired => 'Enter your email.';

  @override
  String get validationEmailInvalid => 'Enter a valid email address.';

  @override
  String get validationPasswordRequired => 'Enter your password.';

  @override
  String get validationPasswordShort => 'Use at least 8 characters.';

  @override
  String get validationConfirmPasswordRequired => 'Confirm your password.';

  @override
  String get validationPasswordMismatch => 'The passwords do not match.';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get loading => 'Loading';

  @override
  String get tryAgain => 'Try again';

  @override
  String get couldNotContinue => 'Could not continue';

  @override
  String get companyAdminHomeTitle => 'Company admin';

  @override
  String get driversAdminHomeTitle => 'Drivers admin';

  @override
  String get driverHomeTitle => 'Driver';

  @override
  String get employeeHomeTitle => 'Employee';

  @override
  String roleHomeWelcome(String name) {
    return 'Welcome, $name';
  }

  @override
  String get companyAdminHomeSubtitle =>
      'Review trip requests and overall trip progress.';

  @override
  String get requestsTab => 'Requests';

  @override
  String get pendingRequestsTab => 'Pending requests';

  @override
  String get tripsTab => 'Trips';

  @override
  String get placesTab => 'Places';

  @override
  String get placesEmptyTitle => 'No places yet';

  @override
  String get placesEmptyMessage =>
      'Seed the company places list, or add a place manually. Active places appear for employees when they request a trip.';

  @override
  String get addPlace => 'Add place';

  @override
  String get addPlaceTitle => 'Add place';

  @override
  String get editPlace => 'Edit place';

  @override
  String get editPlaceTitle => 'Edit place';

  @override
  String get savePlace => 'Save';

  @override
  String get placeNameEnLabel => 'Name (English)';

  @override
  String get placeNameArLabel => 'Name (Arabic)';

  @override
  String get placeHeadquartersLabel => 'Company headquarters';

  @override
  String get placeHeadquartersHint =>
      'Only one place can be headquarters. Turning this on clears the flag on other places.';

  @override
  String get placeHeadquartersBadge => 'Headquarters';

  @override
  String get placeStatusActive => 'Active';

  @override
  String get placeStatusInactive => 'Inactive';

  @override
  String get placeCreated => 'Place added.';

  @override
  String get placeUpdated => 'Place updated.';

  @override
  String get deletePlace => 'Delete place';

  @override
  String get deletePlaceConfirmTitle => 'Delete this place?';

  @override
  String deletePlaceConfirmMessage(String name) {
    return '\"$name\" will be removed from the approved places list.';
  }

  @override
  String get placeDeleted => 'Place deleted.';

  @override
  String get seedDefaultPlaces => 'Seed default places';

  @override
  String get placesSeeded => 'Default places created.';

  @override
  String get validationPlaceNameEnRequired => 'Enter the English name.';

  @override
  String get validationPlaceNameArRequired => 'Enter the Arabic name.';

  @override
  String get validationPlaceNameDuplicate =>
      'A place with this name already exists.';

  @override
  String get errorConflict => 'That name is already in use.';

  @override
  String get pendingRequestsEmptyTitle => 'No pending requests';

  @override
  String get pendingRequestsEmptyMessage =>
      'New employee trip requests will show up here.';

  @override
  String get tripsEmptyTitle => 'No trips yet';

  @override
  String get tripsEmptyMessage =>
      'Trips created by the drivers admin will appear here.';

  @override
  String get approveTripRequest => 'Approve';

  @override
  String get approveTripRequestTitle => 'Approve this request?';

  @override
  String get approveTripRequestMessage =>
      'The request will move to approved so the drivers admin can create a trip.';

  @override
  String get confirmApproveTripRequest => 'Approve request';

  @override
  String get tripRequestApproved => 'Trip request approved.';

  @override
  String get rejectTripRequest => 'Reject';

  @override
  String get rejectTripRequestTitle => 'Reject this request?';

  @override
  String get rejectTripRequestMessage =>
      'The employee will see this request as rejected.';

  @override
  String get rejectionReasonLabel => 'Reason (optional)';

  @override
  String get rejectionReasonHint => 'Tell the employee why it was rejected';

  @override
  String get confirmRejectTripRequest => 'Reject request';

  @override
  String get dialogCancel => 'Cancel';

  @override
  String get tripRequestRejected => 'Trip request rejected.';

  @override
  String selectedRequestsCount(int count) {
    return '$count selected';
  }

  @override
  String get createOneTripPerRequest => 'Create one trip per request';

  @override
  String get groupIntoOneTrip => 'Group into one trip';

  @override
  String groupingSuggestionBanner(int count) {
    return '$count requests look groupable';
  }

  @override
  String get groupingSuggestionDismiss => 'Dismiss';

  @override
  String get groupingSuggestionsSheetTitle => 'Suggested groupings';

  @override
  String get groupingSuggestionsEmpty => 'No grouping suggestions left.';

  @override
  String groupingSuggestionTimeSpan(String span) {
    return 'Time: $span';
  }

  @override
  String groupingSuggestionRequestCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count requests',
      one: '1 request',
    );
    return '$_temp0';
  }

  @override
  String get groupingSuggestionRemoveRequest => 'Remove from group';

  @override
  String get groupingSuggestionApproveAsGroup => 'Approve as group';

  @override
  String get groupingSuggestionIgnore => 'Ignore';

  @override
  String get groupingSuggestionApproved => 'Requests approved as a group.';

  @override
  String suggestedGroupTitle(int count) {
    return 'Suggested group ($count)';
  }

  @override
  String suggestedGroupEmployees(String names) {
    return 'Employees: $names';
  }

  @override
  String get createGroupedTrip => 'Create grouped trip';

  @override
  String get splitSuggestedGroup => 'Split';

  @override
  String get tripsCreated => 'Trip(s) created.';

  @override
  String tripRequestDestinationValue(String destination) {
    return 'To: $destination';
  }

  @override
  String tripScheduledValue(String dateTime) {
    return 'Scheduled: $dateTime';
  }

  @override
  String tripPassengersCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count passengers',
      one: '1 passenger',
    );
    return '$_temp0';
  }

  @override
  String get tripDetailsTitle => 'Trip details';

  @override
  String get tripPassengersSection => 'Passengers';

  @override
  String get tripRequestsSection => 'Requests';

  @override
  String get tripStatusUnassigned => 'Unassigned';

  @override
  String get tripStatusAssigned => 'Assigned';

  @override
  String get tripStatusGoing => 'Going';

  @override
  String get tripStatusAtDestination => 'At destination';

  @override
  String get tripStatusReturning => 'Returning';

  @override
  String get tripStatusCompleted => 'Completed';

  @override
  String get tripStatusCancelled => 'Cancelled';

  @override
  String get arrivedAtDestination => 'Arrived at destination';

  @override
  String get arrivedAtDestinationConfirmTitle => 'Mark arrived at destination?';

  @override
  String get arrivedAtDestinationConfirmMessage =>
      'This ends the going phase and saves the route so far.';

  @override
  String get arrivedAtDestinationSuccess => 'Arrived at destination.';

  @override
  String get startReturn => 'Start return';

  @override
  String get startReturnConfirmTitle => 'Start the return leg?';

  @override
  String get startReturnConfirmMessage =>
      'Location tracking resumes for the trip back.';

  @override
  String get startReturnSuccess => 'Return started.';

  @override
  String get locationPermissionDeniedTitle => 'Location permission needed';

  @override
  String get locationPermissionDeniedMessage =>
      'Allow location while using the app so dispatch can follow your trip.';

  @override
  String get locationPermissionPermanentlyDeniedMessage =>
      'Location access is blocked. Open app settings to enable it.';

  @override
  String get locationServicesDisabledMessage =>
      'Turn on GPS / location services to share your trip position.';

  @override
  String get openAppSettings => 'Open app settings';

  @override
  String get enableLocationServices => 'Enable location services';

  @override
  String get driversAdminHomeSubtitle => 'Manage drivers and assign trips.';

  @override
  String get driversTab => 'Drivers';

  @override
  String get driversEmptyTitle => 'No drivers exist yet';

  @override
  String get driversEmptyMessage =>
      'Add a driver account to start assigning trips.';

  @override
  String get fixLegacyDrivers => 'Fix legacy drivers';

  @override
  String get fixLegacyDriversConfirmTitle => 'Fix legacy driver profiles?';

  @override
  String get fixLegacyDriversConfirmMessage =>
      'This writes missing defaults (active status and bilingual names from the old name) onto driver accounts that still use the previous format.';

  @override
  String get fixLegacyDriversConfirmAction => 'Fix now';

  @override
  String fixLegacyDriversSuccess(int count) {
    return '$count driver profiles updated.';
  }

  @override
  String get fixLegacyDriversNone =>
      'All driver profiles already look up to date.';

  @override
  String get addDriver => 'Add driver';

  @override
  String get addDriverTitle => 'Add driver';

  @override
  String get phoneLabelOptional => 'Phone (optional)';

  @override
  String get temporaryPasswordLabel => 'Temporary password';

  @override
  String get driverStatusActive => 'Active';

  @override
  String get driverStatusInactive => 'Inactive';

  @override
  String get driverCreated => 'Driver account created.';

  @override
  String get validationPhoneTooLong => 'Phone number is too long.';

  @override
  String get errorAccountInactive =>
      'This driver account is inactive. Contact an administrator.';

  @override
  String get errorOrphanedAccountCleanupFailed =>
      'The account was created but the profile could not be saved, and cleanup failed. Contact an administrator.';

  @override
  String get tripsUnassignedTab => 'Unassigned';

  @override
  String get tripsAssignedTab => 'Assigned';

  @override
  String get tripsAllTab => 'All';

  @override
  String get adminTripsEmptyTitle => 'No trips here';

  @override
  String get adminTripsUnassignedEmptyMessage =>
      'Unassigned trips from company admin will show up here.';

  @override
  String get adminTripsAssignedEmptyMessage =>
      'Assigned trips will show up here.';

  @override
  String get adminTripsAllEmptyMessage =>
      'Trips created by company admin will show up here.';

  @override
  String tripRouteSummary(String pickup, String destination) {
    return '$pickup → $destination';
  }

  @override
  String get assignDriver => 'Assign driver';

  @override
  String get reassignDriver => 'Reassign driver';

  @override
  String get cancelTrip => 'Cancel trip';

  @override
  String get cancelTripConfirmTitle => 'Cancel this trip?';

  @override
  String get cancelTripConfirmMessage =>
      'This trip has not started and will be marked cancelled.';

  @override
  String get confirmCancelTrip => 'Cancel trip';

  @override
  String get tripCancelled => 'Trip cancelled.';

  @override
  String get tripDriverAssigned => 'Driver assigned.';

  @override
  String get tripDriverReassigned => 'Driver reassigned.';

  @override
  String get selectDriverTitle => 'Select a driver';

  @override
  String get noActiveDriversMessage =>
      'No active drivers available. Activate a driver first.';

  @override
  String get driverScheduleConflictTitle => 'Schedule overlap';

  @override
  String get driverScheduleConflictMessage =>
      'This driver already has another trip within two hours of this time. You can still assign them.';

  @override
  String get driverScheduleConflictContinue => 'Assign anyway';

  @override
  String get driverHasNearbyTripHint => 'Has another trip within 2 hours';

  @override
  String tripAssignedDriverValue(String name) {
    return 'Driver: $name';
  }

  @override
  String get driverHomeSubtitle => 'View assigned, weekly, and past trips.';

  @override
  String get driverTripsAssignedTab => 'Assigned';

  @override
  String get driverTripsWeeklyTab => 'This week';

  @override
  String get driverTripsPastTab => 'Past';

  @override
  String get driverTripsEmptyTitle => 'No trips here';

  @override
  String get driverTripsAssignedEmptyMessage =>
      'Trips assigned to you will appear here.';

  @override
  String get driverTripsWeeklyEmptyMessage => 'No trips planned for this week.';

  @override
  String get driverTripsPastEmptyMessage =>
      'Completed and cancelled trips will appear here.';

  @override
  String get startTrip => 'Start trip';

  @override
  String get endTrip => 'End trip';

  @override
  String get startTripConfirmTitle => 'Start this trip?';

  @override
  String get startTripConfirmMessage =>
      'Passengers will see this trip as in progress.';

  @override
  String get endTripConfirmTitle => 'End this trip?';

  @override
  String get endTripConfirmMessage => 'This marks the trip as completed.';

  @override
  String get tripStarted => 'Trip started.';

  @override
  String get tripEnded => 'Trip completed.';

  @override
  String get employeeHomeSubtitle => 'Your trip requests will appear here.';

  @override
  String get homeEmpty => 'Nothing to show yet.';

  @override
  String get errorNetwork =>
      'Unable to connect. Check your internet and try again.';

  @override
  String get errorAuth => 'Authentication failed. Please sign in again.';

  @override
  String get errorPermission => 'You do not have permission to do that.';

  @override
  String get errorUnknown => 'Something went wrong. Please try again.';

  @override
  String get errorInvalidEmail => 'Enter a valid email address.';

  @override
  String get errorInvalidCredentials => 'The email or password is incorrect.';

  @override
  String get errorUserDisabled =>
      'This account is disabled. Contact an administrator.';

  @override
  String get errorEmailAlreadyInUse => 'This email is already registered.';

  @override
  String get errorWeakPassword =>
      'The password is too weak. Use at least 8 characters.';

  @override
  String get errorTooManyRequests =>
      'Too many attempts. Wait a moment and try again.';

  @override
  String get errorOperationNotAllowed => 'Email sign-in is not available.';

  @override
  String get errorMissingProfile =>
      'This account has no user profile. Contact an administrator or register again.';

  @override
  String get errorInvalidProfile =>
      'This account profile is invalid. Contact an administrator.';

  @override
  String get errorNotFound => 'That item could not be found.';

  @override
  String get errorInvalidState =>
      'That action is not available for the current status.';

  @override
  String get tripRequestsEmptyTitle => 'No trip requests yet';

  @override
  String get tripRequestsEmptyMessage => 'Tap + to request a company car trip.';

  @override
  String get newTripRequest => 'New trip request';

  @override
  String get newTripRequestTitle => 'New request';

  @override
  String get pickupLocationLabel => 'Pickup place';

  @override
  String get destinationLabel => 'Destination place';

  @override
  String get searchPlacesHint => 'Search places';

  @override
  String get otherPlaceOption => 'Other (not listed)';

  @override
  String get customPlaceLabel => 'Custom place';

  @override
  String get customPlaceHint => 'Type the place name';

  @override
  String get noPlacesForRequestTitle => 'No places available';

  @override
  String get noPlacesForRequestMessage =>
      'Contact your company admin to add approved places before requesting a trip.';

  @override
  String get requestedDateTimeLabel => 'Date and time';

  @override
  String get selectDate => 'Select date';

  @override
  String get selectTime => 'Select time';

  @override
  String get selectDateTime => 'Select date and time';

  @override
  String get notesLabel => 'Notes';

  @override
  String get notesHint =>
      'One fellow employee name per line (do not include phone numbers).';

  @override
  String get notesFellowEmployeesHint =>
      'Write one name per line. Their phone numbers are never shared.';

  @override
  String get addAnotherNameLine => 'Add another name';

  @override
  String get submitTripRequest => 'Submit request';

  @override
  String get cancelTripRequest => 'Cancel request';

  @override
  String get cancelTripRequestConfirmTitle => 'Cancel this request?';

  @override
  String get cancelTripRequestConfirmMessage =>
      'This pending request will be cancelled. You can create a new one later.';

  @override
  String get confirmCancelTripRequest => 'Cancel request';

  @override
  String get dialogDismiss => 'Keep request';

  @override
  String get tripRequestStatusPending => 'Pending';

  @override
  String get tripRequestStatusApproved => 'Approved';

  @override
  String get tripRequestStatusRejected => 'Rejected';

  @override
  String get tripRequestStatusCancelled => 'Cancelled';

  @override
  String tripRequestPickupValue(String pickup) {
    return 'From: $pickup';
  }

  @override
  String tripRequestWhenValue(String dateTime) {
    return 'When: $dateTime';
  }

  @override
  String tripRequestNotesValue(String notes) {
    return 'Notes: $notes';
  }

  @override
  String get validationPickupPlaceRequired => 'Select a pickup place.';

  @override
  String get validationDestinationPlaceRequired =>
      'Select a destination place.';

  @override
  String get validationCustomPlaceRequired => 'Enter the custom place name.';

  @override
  String get validationPickupDestinationSame =>
      'Pickup and destination must be different places.';

  @override
  String get validationDateTimeRequired => 'Select a date and time.';

  @override
  String get validationDateTimeFuture =>
      'Choose a date and time in the future.';

  @override
  String get tripRequestCreated => 'Trip request submitted.';

  @override
  String get requestATrip => 'Request a trip';

  @override
  String get adminRequestChip => 'Admin request';

  @override
  String get tripRequestCancelled => 'Trip request cancelled.';

  @override
  String get phoneLabel => 'Phone';

  @override
  String get validationPhoneRequired => 'Enter your phone number.';

  @override
  String get branchLabel => 'Branch';

  @override
  String get validationBranchRequired => 'Select your branch.';

  @override
  String get branchCompanyHeadquarters => 'Company Headquarters';

  @override
  String get branchNewHeadquarters => 'New Headquarters';

  @override
  String get branchFilterAll => 'All';

  @override
  String get branchLockedHint => 'Contact the admin to change your branch.';

  @override
  String get approvalFilterLabel => 'Approval';

  @override
  String get tripStatusFilterLabel => 'Trip status';

  @override
  String get tripStatusUpcoming => 'Upcoming';

  @override
  String get tripStatusFilterInProgress => 'In progress';

  @override
  String get driversAdminTripUnassigned =>
      'Your trip is unassigned. Open it here to choose a driver.';

  @override
  String get completeProfileTitle => 'Complete your profile';

  @override
  String get completeProfileSubtitle =>
      'Add your branch and phone number to continue.';

  @override
  String get completeProfileSubmit => 'Save and continue';

  @override
  String get completeProfileSaved => 'Profile updated.';

  @override
  String callEmployeePhone(String phone) {
    return 'Call $phone';
  }

  @override
  String get requesterSection => 'Requester';

  @override
  String get requestersSection => 'Requesters';

  @override
  String passengersCountLabel(int count) {
    return 'Passengers: $count';
  }

  @override
  String get requestDetailsTitle => 'Request details';

  @override
  String tripDriverNameValue(String name) {
    return 'Driver: $name';
  }

  @override
  String get tripDriverUnassigned => 'Driver: Unassigned';

  @override
  String tripStartedValue(String dateTime) {
    return 'Started: $dateTime';
  }

  @override
  String tripEndedValue(String dateTime) {
    return 'Ended: $dateTime';
  }

  @override
  String get tripNotStartedYet => 'Not started yet';

  @override
  String get tripNotEndedYet => 'Not ended yet';

  @override
  String get approvedRequestsTab => 'Approved requests';

  @override
  String get approvedRequestsEmptyTitle => 'No approved requests';

  @override
  String get approvedRequestsEmptyMessage =>
      'Approved requests that are not yet in a trip will show up here.';

  @override
  String get tripsInProgressTab => 'In progress';

  @override
  String get tripsCompletedTab => 'Completed';

  @override
  String get adminTripsInProgressEmptyMessage => 'No trips in progress.';

  @override
  String get adminTripsCompletedEmptyMessage => 'No completed trips yet.';

  @override
  String get liveMapTab => 'Live map';

  @override
  String get liveMapTitle => 'Live map';

  @override
  String get sharingLocation => 'Sharing location';

  @override
  String get locationSharingOff => 'Location off';

  @override
  String get locationUpdateKeptLast =>
      'Couldn\'t send a new position. Dispatch still has your last known location.';

  @override
  String get locationSharingWarning =>
      'Trip started, but location sharing is off. Tap Location off to enable GPS for dispatch.';

  @override
  String get destinationLocationNotSet => 'Destination location not set';

  @override
  String get recenterMap => 'Recenter';

  @override
  String distanceRemainingKm(String km) {
    return '$km km remaining';
  }

  @override
  String get passengersFromNotes => 'Passengers (from notes)';

  @override
  String get openLiveMap => 'Open live map';

  @override
  String get noActiveTripsRightNow => 'No active trips right now';

  @override
  String get noActiveTripsRightNowMessage =>
      'A started trip appears here only after the driver app is sharing GPS (Location allowed + a GPS fix). Check the driver device if this stays empty.';

  @override
  String get fitAllDrivers => 'Fit all';

  @override
  String lastSeenMinutesAgo(int minutes) {
    return 'Last seen $minutes min ago';
  }

  @override
  String speedKmh(String speed) {
    return 'Speed: $speed km/h';
  }

  @override
  String lastUpdateValue(String time) {
    return 'Last update: $time';
  }

  @override
  String get openTripDetails => 'Open trip details';

  @override
  String get placeCoordinatesLabel => 'Location on map';

  @override
  String get useMyCurrentLocation => 'Use my current location';

  @override
  String get latitudeLabel => 'Latitude';

  @override
  String get longitudeLabel => 'Longitude';

  @override
  String get validationLatitudeInvalid => 'Enter a valid latitude (-90 to 90).';

  @override
  String get validationLongitudeInvalid =>
      'Enter a valid longitude (-180 to 180).';

  @override
  String get validationPlaceLocationRequired =>
      'Pick a location on the map before saving.';

  @override
  String get placeAddressLabel => 'Address';

  @override
  String get validationPlaceAddressRequired => 'Enter the address.';

  @override
  String get validationPlaceCoordinatePair =>
      'Enter both latitude and longitude, or leave both empty.';

  @override
  String get placeLocationOptionalHint =>
      'Location is optional. Tap the map or enter latitude and longitude.';

  @override
  String get clearPlaceLocation => 'Clear location';

  @override
  String get placeHasCoordinates => 'Coordinates set';

  @override
  String get placeMissingCoordinates => 'No coordinates';

  @override
  String get tapMapToSetLocation => 'Tap the map to set the location';

  @override
  String get placeCannotSelectWithoutLocation =>
      'This place has no location and cannot be used for a trip. Ask an admin to add coordinates.';

  @override
  String get noLocationBadge => 'No location';

  @override
  String get locationServicesDisabled =>
      'Turn on location services to continue.';

  @override
  String get locationPermissionDenied =>
      'Location permission is required to share with dispatch.';

  @override
  String get locationUnavailable => 'Location is unavailable.';

  @override
  String get pickLocationTitle => 'Pick a location';

  @override
  String get myLocationButton => 'My location';

  @override
  String get locationSearchHint => 'Search place or address';

  @override
  String get locationSearchAction => 'Search';

  @override
  String get locationSearchNoResults => 'No places found for that search.';

  @override
  String get locationSearchFailed =>
      'Search failed. Check your connection and try again.';

  @override
  String get resolvingAddress => 'Resolving address…';

  @override
  String get addressNotAvailable => 'Address not available';

  @override
  String get confirmLocation => 'Confirm location';

  @override
  String get openSettingsAction => 'Open settings';

  @override
  String get chooseOnMap => 'Choose on map';

  @override
  String get nameMapPlaceTitle => 'Name this location';

  @override
  String get placeNameArOptionalLabel => 'Name (Arabic, optional)';

  @override
  String get useLocationForTripOnly => 'Use for this trip only';

  @override
  String get saveLocationAsPlace => 'Save as a new place';

  @override
  String get customLocationChip => 'Custom location';

  @override
  String get pickLocationOnMap => 'Pick on map';

  @override
  String get editLocationOnMap => 'Edit on map';

  @override
  String get enterCoordinatesManually => 'Enter coordinates manually';

  @override
  String get noMapLocationBadge => 'No location';

  @override
  String get addLocationAction => 'Add location';

  @override
  String get editDriver => 'Edit driver';

  @override
  String get editDriverTitle => 'Edit driver';

  @override
  String get driverUpdated => 'Driver updated.';

  @override
  String get saveDriver => 'Save';

  @override
  String get tripEventsSection => 'Trip events';

  @override
  String get tripEventTripStarted => 'Trip started';

  @override
  String get tripEventArrivedAtDestination => 'Arrived at destination';

  @override
  String get tripEventStartedReturning => 'Started returning';

  @override
  String get tripEventTripEnded => 'Trip ended';

  @override
  String get tripNotArrivedYet => 'Not arrived yet';

  @override
  String get tripNotReturningYet => 'Not returning yet';

  @override
  String handledByValue(String name) {
    return 'Handled by: $name';
  }

  @override
  String handledAtValue(String dateTime) {
    return 'Handled at: $dateTime';
  }

  @override
  String get filterPending => 'Pending';

  @override
  String get filterApproved => 'Approved';

  @override
  String get filterRejected => 'Rejected';

  @override
  String get requestsEmptyTitle => 'No requests';

  @override
  String get requestsEmptyMessage => 'No trip requests match this filter.';

  @override
  String get driverNameEnLabel => 'Name (English)';

  @override
  String get driverNameArLabel => 'Name (Arabic)';

  @override
  String get nationalIdLabel => 'National ID';

  @override
  String get carLicenseLabel => 'Car plate';

  @override
  String get carPlateLettersLabel => 'Letters';

  @override
  String get carPlateNumbersLabel => 'Numbers';

  @override
  String get personalLicenseLabel => 'Personal license';

  @override
  String get driverDetailsTitle => 'Driver details';

  @override
  String nationalIdMaskedValue(String masked) {
    return 'National ID: $masked';
  }

  @override
  String get nationalIdNotSet => 'National ID: not set';

  @override
  String carLicenseValue(String license) {
    return 'Car plate: $license';
  }

  @override
  String get carLicenseNotSet => 'Car plate: not set';

  @override
  String get validationDriverNameEnRequired => 'Enter the English name.';

  @override
  String get validationDriverNameArRequired => 'Enter the Arabic name.';

  @override
  String get validationPhoneInvalid => 'Enter a valid phone number.';

  @override
  String get validationNationalIdRequired => 'Enter the national ID.';

  @override
  String get validationNationalIdInvalid =>
      'Enter a valid 14-digit Egyptian national ID.';

  @override
  String get validationCarLicenseRequired => 'Enter the car plate.';

  @override
  String get validationCarPlateInvalid =>
      'Enter 1–3 Arabic letters and 1–4 numbers, like ط ع ب 9295.';

  @override
  String get validationPersonalLicenseRequired => 'Enter the personal license.';

  @override
  String get registerSectionDetails => 'Your details';

  @override
  String get registerSectionSecurity => 'Security';

  @override
  String get roleLabelEmployee => 'Employee';

  @override
  String get roleLabelDriver => 'Driver';

  @override
  String get roleLabelCompanyAdmin => 'Company admin';

  @override
  String get roleLabelDriversAdmin => 'Drivers admin';

  @override
  String get bootstrapGettingLocation => 'Getting your location';

  @override
  String get bootstrapLoadingLocations => 'Loading trip locations';

  @override
  String get bootstrapPreparingRoute => 'Preparing route';

  @override
  String get bootstrapSharingLocation => 'Sharing location with dispatch';

  @override
  String get waitingForGpsSignal => 'Waiting for GPS signal';

  @override
  String get locationOffTapToFix => 'Location off, tap to fix';

  @override
  String get approximateRoute => 'Route unavailable, showing direct line';

  @override
  String get approximateLocation => 'Approximate location';

  @override
  String locationNotSetFor(String name) {
    return 'Location not set for $name';
  }

  @override
  String get youHaveArrived => 'You have arrived';

  @override
  String get arrivedStartReturn => 'Arrived / Start return';

  @override
  String get navigateButton => 'Navigate';

  @override
  String tripProgressPercent(int percent) {
    return '$percent% complete';
  }

  @override
  String distanceCoveredRemaining(String covered, String remaining) {
    return '$covered km covered · $remaining km remaining';
  }

  @override
  String etaApproximateMinutes(int minutes) {
    return 'ETA ~$minutes min (approximate)';
  }

  @override
  String get devToolsTitle => 'Dev tools';

  @override
  String get devSimulateMovement => 'Simulate movement';

  @override
  String devSimulateSpeed(int speed) {
    return 'Speed: $speed km/h';
  }

  @override
  String get devPauseSimulation => 'Pause';

  @override
  String get devResumeSimulation => 'Resume';

  @override
  String get devJumpToNinety => 'Jump to 90%';

  @override
  String adminTripProgress(int percent, String remaining) {
    return '$percent% · $remaining km remaining';
  }

  @override
  String get routeUnavailableShowingDirectLine =>
      'Route unavailable, showing direct line';

  @override
  String get recalculateRoute => 'Recalculate route';

  @override
  String get retryAction => 'Retry';

  @override
  String get locatingDriverPosition => 'Getting your location…';

  @override
  String get locationFixTimedOut =>
      'Could not get your location. Check GPS and try again.';

  @override
  String get liveMapPhaseArrived => 'Arrived';

  @override
  String estimatedDistanceKm(String km) {
    return '$km km';
  }

  @override
  String estimatedEtaMinutes(int minutes) {
    return 'ETA $minutes min';
  }

  @override
  String get tripReportTitle => 'Trip report';

  @override
  String get tripReportInProgress => 'Report in progress';

  @override
  String get tripReportStartedAt => 'Started at';

  @override
  String get tripReportFinishedAt => 'Finished at';

  @override
  String get tripReportTotalDuration => 'Total duration';

  @override
  String get tripReportGoingDuration => 'Going duration';

  @override
  String get tripReportWaitingDuration => 'Waiting at destination';

  @override
  String get tripReportReturnDuration => 'Return duration';

  @override
  String get tripReportDistanceGoing => 'Distance going';

  @override
  String get tripReportDistanceReturn => 'Distance back';

  @override
  String get tripReportDistanceTotal => 'Total distance';

  @override
  String tripReportDistanceKmValue(String km) {
    return '$km km';
  }

  @override
  String tripReportDurationHoursMinutesSeconds(
    int hours,
    int minutes,
    int seconds,
  ) {
    return '${hours}h ${minutes}m ${seconds}s';
  }

  @override
  String tripReportDurationMinutesSeconds(int minutes, int seconds) {
    return '${minutes}m ${seconds}s';
  }

  @override
  String tripReportDurationSeconds(int seconds) {
    return '${seconds}s';
  }

  @override
  String get tripReportRouteSection => 'Route';

  @override
  String get tripReportGoingRouteLegend => 'Going';

  @override
  String get tripReportReturnRouteLegend => 'Returning';

  @override
  String get viewTripDetails => 'Trip details';

  @override
  String get noAvailableDriversTitle => 'No available drivers';

  @override
  String get noAvailableDriversMessage =>
      'Approve an availability request first, or wait for a driver to become free.';

  @override
  String get relativeTimeJustNow => 'Just now';

  @override
  String relativeTimeMinutesAgo(int minutes) {
    return '$minutes min ago';
  }

  @override
  String relativeTimeHoursAgo(int hours) {
    return '$hours hr ago';
  }

  @override
  String relativeTimeDaysAgo(int days) {
    return '$days d ago';
  }

  @override
  String get favoritePlacesLabel => 'Favorite places';

  @override
  String get favoritePlacesSearchHint => 'Search places to add';

  @override
  String get favoritePlaceRemove => 'Remove favorite place';

  @override
  String get recommendedDriversSection => 'Recommended';

  @override
  String get otherDriversSection => 'Other drivers';

  @override
  String get driverReasonFavoritePlace => 'Favorite place';

  @override
  String get driverReasonAvailable => 'Available';

  @override
  String get driverReasonUnavailable => 'Unavailable';

  @override
  String get driverReasonOnActiveTrip => 'On active trip';

  @override
  String get driverReasonScheduleConflict => 'Schedule conflict';

  @override
  String get assignDriverWarningTitle => 'Assign this driver?';

  @override
  String get assignDriverWarningMessage =>
      'This driver is not fully available for this trip. You can still assign them.';

  @override
  String get assignDriverWarningContinue => 'Assign anyway';

  @override
  String get driverFavoritePlacesEmpty => 'None';

  @override
  String get myRequestsTab => 'My requests';

  @override
  String get myRequestsFilterAll => 'All';

  @override
  String get myRequestsFilterActive => 'Active';

  @override
  String get myRequestsFilterCompleted => 'Completed';

  @override
  String get myRequestsFilterCancelledRejected => 'Cancelled / Rejected';

  @override
  String get myRequestsEmptyTitle => 'No requests yet';

  @override
  String get myRequestsEmptyMessage =>
      'Trip requests you create for yourself will appear here.';

  @override
  String get myRequestsFilteredEmptyMessage => 'No requests match this filter.';

  @override
  String get myRequestProgressTitle => 'Request progress';

  @override
  String get requestProgressStepRequested => 'Requested';

  @override
  String get requestProgressStepApproved => 'Approved';

  @override
  String get requestProgressStepDriverAssigned => 'Driver assigned';

  @override
  String get requestProgressStepGoing => 'Going';

  @override
  String get requestProgressStepArrived => 'Arrived';

  @override
  String get requestProgressStepReturning => 'Returning';

  @override
  String get requestProgressStepCompleted => 'Completed';

  @override
  String requestProgressCurrentStep(String step) {
    return 'Current: $step';
  }

  @override
  String requestProgressFailedStep(String step) {
    return 'Failed: $step';
  }

  @override
  String get assignedDriverSection => 'Assigned driver';

  @override
  String assignedDriverPhoneValue(String phone) {
    return 'Phone: $phone';
  }

  @override
  String get assignedDriverPending => 'No driver assigned yet.';

  @override
  String get roleLabelAdmin => 'System admin';

  @override
  String get adminDashboardTitle => 'Admin dashboard';

  @override
  String get adminDashboardSubtitle =>
      'Manage drivers, places, and employees. Request trips for yourself.';

  @override
  String get adminDriversSection => 'Drivers';

  @override
  String get adminDriversSectionHint => 'Add, edit, or deactivate drivers';

  @override
  String get adminPlacesSection => 'Places';

  @override
  String get adminPlacesSectionHint => 'Manage locations and map pins';

  @override
  String get adminEmployeesSection => 'Employees';

  @override
  String get adminEmployeesSectionHint => 'Add, edit, or deactivate employees';

  @override
  String get adminUsersSection => 'Users';

  @override
  String get adminUsersSectionHint =>
      'Set a temporary password for any account';

  @override
  String get adminUsersSearchHint => 'Search by name, email, or phone';

  @override
  String get adminFilterAllRoles => 'All roles';

  @override
  String get adminUsersEmptyTitle => 'No users';

  @override
  String get adminUsersEmptyMessage => 'No accounts match this search.';

  @override
  String get adminResetPasswordAction => 'Reset password';

  @override
  String get adminResetPasswordTitle => 'Reset password';

  @override
  String adminResetPasswordMessage(String name) {
    return '$name must change this password the next time they sign in.';
  }

  @override
  String get adminResetPasswordNote =>
      'Share this password with the user. They must change it when they sign in.';

  @override
  String get adminResetPasswordSuccess => 'Temporary password saved.';

  @override
  String get adminTemporaryPasswordBadge => 'Temporary password';

  @override
  String get adminMyTripsSection => 'My trips';

  @override
  String get adminMyTripsSectionHint => 'Follow progress of your requests';

  @override
  String get adminRequestTripSection => 'Request trip';

  @override
  String get adminRequestTripSectionHint =>
      'Auto-accepted and sent for driver assignment';

  @override
  String get adminSearchHint => 'Search by name, email, or phone';

  @override
  String get adminFilterAll => 'All';

  @override
  String get adminFilterActive => 'Active';

  @override
  String get adminFilterInactive => 'Inactive';

  @override
  String get adminFilterAllBranches => 'All branches';

  @override
  String get adminDriversEmptyTitle => 'No drivers found';

  @override
  String get adminDriversEmptyMessage =>
      'Add a driver or clear filters to see results.';

  @override
  String get adminEmployeesEmptyTitle => 'No employees found';

  @override
  String get adminEmployeesEmptyMessage =>
      'Add an employee or clear filters to see results.';

  @override
  String get adminAddEmployeeTitle => 'Add employee';

  @override
  String get adminEditEmployeeTitle => 'Edit employee';

  @override
  String get adminAddEmployee => 'Add employee';

  @override
  String get adminSaveEmployee => 'Save employee';

  @override
  String get adminEmployeeCreated => 'Employee created';

  @override
  String get adminEmployeeUpdated => 'Employee updated';

  @override
  String get adminSoftDeleteConfirmTitle => 'Deactivate account?';

  @override
  String adminSoftDeleteDriverMessage(String name) {
    return '$name will be deactivated and cannot sign in. Auth account is kept.';
  }

  @override
  String adminSoftDeleteEmployeeMessage(String name) {
    return '$name will be deactivated and cannot sign in. Auth account is kept.';
  }

  @override
  String get adminSoftDeleteAction => 'Deactivate';

  @override
  String get adminSoftDeleteSuccess => 'Account deactivated';

  @override
  String get adminReactivateAction => 'Reactivate';

  @override
  String get adminSeedDebugTitle => 'Seed admin profile (debug)';

  @override
  String get adminSeedDebugMessage =>
      'Writes an admin profile for a user id that already exists.';

  @override
  String get adminSeedUidLabel => 'Auth UID';

  @override
  String get adminSeedDebugAction => 'Write profile';

  @override
  String get adminSeedDebugSuccess => 'Admin profile written';

  @override
  String get navMyTrips => 'My trips';

  @override
  String get navTrips => 'Trips';

  @override
  String get navRequests => 'Requests';

  @override
  String get navPlaces => 'Places';

  @override
  String get navMyRequests => 'My requests';

  @override
  String get navDrivers => 'Drivers';

  @override
  String get navLiveMap => 'Live map';

  @override
  String get navDashboard => 'Dashboard';

  @override
  String get navEmployees => 'Employees';

  @override
  String get navUsers => 'Users';

  @override
  String get navRequestedTrips => 'Requested trips';

  @override
  String get navAssignedTrips => 'Assigned trips';

  @override
  String get navCompletedTrips => 'Completed trips';

  @override
  String get navStats => 'Stats';

  @override
  String get comingSoon => 'Coming soon';

  @override
  String get forcedChangePasswordTitle => 'Change your password';

  @override
  String get forcedChangePasswordMessage =>
      'You must change your password before continuing.';

  @override
  String get navProfile => 'Profile';

  @override
  String get navSettings => 'Settings';

  @override
  String get navMore => 'More';

  @override
  String get profileTitle => 'Profile';

  @override
  String get profileSaved => 'Profile saved';

  @override
  String get profileSave => 'Save profile';

  @override
  String get roleFieldLabel => 'Role';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get languageSection => 'Language';

  @override
  String get changePasswordTitle => 'Change password';

  @override
  String get currentPasswordLabel => 'Current password';

  @override
  String get newPasswordLabel => 'New password';

  @override
  String get changePasswordAction => 'Update password';

  @override
  String get changePasswordSuccess => 'Password updated';

  @override
  String get changePasswordRateLimited =>
      'Too many attempts. Try again in a minute.';

  @override
  String get logoutConfirmTitle => 'Sign out?';

  @override
  String get logoutConfirmMessage =>
      'You will need to sign in again to continue.';

  @override
  String get logoutActiveTripWarning =>
      'You have a trip in progress. Signing out stops live tracking.';

  @override
  String get logoutConfirmAction => 'Sign out';

  @override
  String liveMapScheduledAt(String time) {
    return 'Scheduled $time';
  }

  @override
  String get myTripsTabAll => 'All';

  @override
  String get myTripsTabActive => 'Active';

  @override
  String get myTripsTabCompleted => 'Completed';

  @override
  String get myTripsTabCancelled => 'Cancelled';

  @override
  String myTripsNeedReport(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count trips need your report',
      one: '1 trip needs your report',
    );
    return '$_temp0';
  }

  @override
  String get myTripsEmptyTitle => 'No trips here';

  @override
  String get myTripsEmptyMessage =>
      'Trip requests in this tab will show up here.';

  @override
  String myTripsDriverName(String name) {
    return 'Driver: $name';
  }

  @override
  String get tripRequestDetailsTitle => 'Trip details';

  @override
  String get detailPickup => 'Pickup';

  @override
  String get detailDestination => 'Destination';

  @override
  String get detailAddress => 'Address';

  @override
  String get detailRequestedAt => 'Requested';

  @override
  String get detailNotes => 'Notes';

  @override
  String get detailPhone => 'Phone';

  @override
  String get detailBranch => 'Branch';

  @override
  String get detailEmployee => 'Employee';

  @override
  String get detailRejectionReason => 'Rejection reason';

  @override
  String get detailHandledAt => 'Handled';

  @override
  String get detailNoNotes => 'No notes';

  @override
  String get tripBlockTitle => 'Assigned trip';

  @override
  String get tripBlockNoDriver => 'No driver assigned yet';

  @override
  String get confirmationUnconfirmed => 'Not confirmed (auto-closed after 24h)';

  @override
  String get confirmationConfirmed => 'Confirmed';

  @override
  String get confirmationPending => 'Waiting for your report';

  @override
  String get driverShowedUpYes => 'Driver showed up';

  @override
  String get driverShowedUpNo => 'Driver did not show up';

  @override
  String get confirmTripQuestion => 'Did the driver show up?';

  @override
  String get confirmTripYes => 'Driver showed up';

  @override
  String get confirmTripNo => 'Did not show up';

  @override
  String get confirmTripNoteHint => 'Optional';

  @override
  String get confirmTripSubmit => 'Submit report';

  @override
  String get confirmTripSuccess => 'Trip report submitted.';

  @override
  String get confirmTripAlreadyClosed =>
      'This trip was already confirmed or closed';

  @override
  String get confirmTripChooseAnswer => 'Choose whether the driver showed up.';

  @override
  String get confirmTripNoteTooLong => 'Note must be 500 characters or fewer.';

  @override
  String get periodWeek => 'Week';

  @override
  String get periodMonth => 'Month';

  @override
  String get periodYear => 'Year';

  @override
  String get periodAll => 'All';

  @override
  String get periodAllTime => 'All time';

  @override
  String get periodPrevious => 'Previous period';

  @override
  String get periodNext => 'Next period';

  @override
  String get assignedTripsEmptyMessage => 'No assigned trips in this period.';

  @override
  String get completedTripsEmptyMessage => 'No completed trips in this period.';

  @override
  String tripDistanceValue(String distance) {
    return 'Distance $distance km';
  }

  @override
  String tripDurationValue(String duration) {
    return 'Duration $duration';
  }

  @override
  String get statsTrips => 'Trips';

  @override
  String get statsTime => 'Time';

  @override
  String get statsDistance => 'Distance';

  @override
  String statsKmValue(String distance) {
    return '$distance km';
  }

  @override
  String get statsChartEmpty => 'No trips in this period.';

  @override
  String get myTripsTabCancelledRejected => 'Cancelled/Rejected';

  @override
  String tripStatusLine(String status) {
    return 'Trip status: $status';
  }

  @override
  String confirmationStatusValue(String status) {
    return 'Confirmation: $status';
  }

  @override
  String get driverDidNotShow => 'Driver did not show';

  @override
  String get tripsAwaitingReportTab => 'Awaiting report';

  @override
  String liveProgressLastSeen(String time) {
    return 'Last seen $time';
  }

  @override
  String get liveMapStateOnTrip => 'On a trip';

  @override
  String get liveMapStateAvailable => 'Available';

  @override
  String get liveMapStateUnavailable => 'Unavailable';

  @override
  String get liveMapNoLocationTitle => 'No location yet';

  @override
  String get driverMustChangePasswordNote =>
      'The driver must change this password on first login.';

  @override
  String get favoritePlacesLimit => 'Choose up to 5 favorite places.';

  @override
  String recommendationTier(int tier) {
    return 'Tier $tier';
  }

  @override
  String recommendationTripsThisWeek(int count) {
    return '$count trips this week';
  }

  @override
  String get cannotDeleteHeadquartersPlace =>
      'The headquarters place cannot be deleted.';

  @override
  String get loadMore => 'Load more';

  @override
  String get createdByMeEmptyTitle => 'No trips in this tab';

  @override
  String get createdByMeEmptyMessage => 'Trips you create will show up here.';

  @override
  String get adminTripsAwaitingReportEmptyMessage =>
      'No trips are waiting for a passenger report.';

  @override
  String get liveMapNoDrivers => 'No drivers match this filter.';

  @override
  String get realtimeConnected => 'Live';

  @override
  String get realtimeConnecting => 'Connecting';

  @override
  String get realtimeDisconnected => 'Offline';

  @override
  String get trackingPendingApproval => 'Pending approval';

  @override
  String get trackingApprovedQuestion => 'Approved?';

  @override
  String trackingApprovedAt(String time) {
    return 'Approved $time';
  }

  @override
  String get trackingNotYet => 'Not yet';

  @override
  String get trackingDriverQuestion => 'Driver assigned?';

  @override
  String trackingDriverLine(String name, String phone) {
    return '$name · $phone';
  }

  @override
  String get trackingNowQuestion => 'Where is it now?';

  @override
  String get trackingStageSubmitted => 'Submitted';

  @override
  String get trackingStageApproved => 'Approved';

  @override
  String get trackingStageRejected => 'Rejected';

  @override
  String get trackingStageDriverAssigned => 'Driver assigned';

  @override
  String get trackingStageInProgress => 'In progress';

  @override
  String get trackingStageFinished => 'Trip finished';

  @override
  String get trackingStageAwaitingConfirmation => 'Awaiting confirmation';

  @override
  String get trackingStageConfirmed => 'Confirmed';

  @override
  String get trackingStageUnconfirmed => 'Unconfirmed';

  @override
  String get trackingStageCancelled => 'Cancelled';

  @override
  String get trackingChipDriverAssigned => 'Driver assigned';

  @override
  String get trackingRejectionTitle => 'Rejection reason';

  @override
  String trackingScheduled(String time) {
    return 'Scheduled $time';
  }

  @override
  String trackingVehicle(String license) {
    return 'Car plate $license';
  }

  @override
  String get trackingNoPhone => 'No phone';

  @override
  String get useThisTime => 'Use this time';

  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get notificationsEmpty => 'No notifications yet.';

  @override
  String get notificationsMarkAll => 'Mark all as read';

  @override
  String get notificationsUnread => 'Unread';

  @override
  String get notificationUnknown => 'Notification';

  @override
  String get notificationRequestSubmittedTitle => 'New trip request';

  @override
  String notificationRequestSubmittedBody(
    String requester,
    String pickup,
    String destination,
  ) {
    return '$requester requested a trip from $pickup to $destination.';
  }

  @override
  String get notificationTripReadyTitle => 'Trip ready to assign';

  @override
  String notificationTripReadyBody(
    String requester,
    String pickup,
    String destination,
  ) {
    return '$requester is waiting for a driver on the trip from $pickup to $destination.';
  }

  @override
  String get notificationTripAssignedTitle => 'Driver assigned';

  @override
  String notificationTripAssignedBody(
    String driver,
    String pickup,
    String destination,
  ) {
    return '$driver is assigned to the trip from $pickup to $destination.';
  }

  @override
  String get notificationOwnTripAssignedTitle => 'Driver assigned to your trip';

  @override
  String notificationOwnTripAssignedBody(
    String driver,
    String pickup,
    String destination,
  ) {
    return '$driver is assigned to your trip from $pickup to $destination.';
  }

  @override
  String get notificationTripEndedTitle => 'Trip ended';

  @override
  String notificationTripEndedBody(String pickup, String destination) {
    return 'Your trip from $pickup to $destination has ended. Please submit the report.';
  }

  @override
  String get notificationChannelTrips => 'Trips';

  @override
  String get notificationChannelTripsDescription =>
      'Trip assignments and request updates';

  @override
  String get navAttendance => 'Attendance';

  @override
  String get attendanceCardTitle => 'Attendance';

  @override
  String get attendanceNotCheckedIn => 'Not checked in';

  @override
  String attendanceCheckedInAt(String time) {
    return 'Checked in at $time';
  }

  @override
  String attendanceCheckedOutAt(String time) {
    return 'Checked out at $time';
  }

  @override
  String get attendanceScanCheckIn => 'Scan QR to check in';

  @override
  String get attendanceScanCheckOut => 'Scan QR to check out';

  @override
  String get attendanceScanTitle => 'Scan QR';

  @override
  String get attendanceScanCancelled => 'Scan cancelled.';

  @override
  String get attendanceScanUnsupported =>
      'QR scanning runs on the Android or iOS app. Stop the app completely, then open it again on a phone or emulator. Hot reload does not load the camera.';

  @override
  String get attendanceCheckedInSuccess => 'Checked in.';

  @override
  String get attendanceCheckedOutSuccess => 'Checked out.';

  @override
  String get attendanceHistoryEmpty => 'No attendance in this period.';

  @override
  String attendanceTotals(int present, int absent, String hours) {
    return 'Present $present, absent $absent, on-site $hours h';
  }

  @override
  String get attendanceAbsent => 'Absent';

  @override
  String get attendanceNoCheckOut => 'No check-out';

  @override
  String attendanceDayLine(String checkIn, String checkOut, String hours) {
    return 'In $checkIn · Out $checkOut · $hours h';
  }

  @override
  String get attendanceStatusCheckedIn => 'Checked in';

  @override
  String get attendanceStatusCheckedOut => 'Checked out';

  @override
  String get attendanceInvalidQr => 'This QR code is not valid.';

  @override
  String get attendanceMockLocation =>
      'A mocked location cannot be used to check in.';

  @override
  String get attendanceLowAccuracy => 'The GPS reading is not accurate enough.';

  @override
  String attendanceOutsideRadius(int distance, int radius) {
    return 'You are $distance m from headquarters. The allowed radius is $radius m.';
  }

  @override
  String get attendanceAlreadyCheckedIn => 'You already checked in today.';

  @override
  String get attendanceNotCheckedInError => 'Check in before checking out.';

  @override
  String get attendanceAlreadyCheckedOut => 'You already checked out today.';

  @override
  String get attendanceActiveTrip =>
      'Finish the active trip before checking out.';

  @override
  String get attendanceFilterAll => 'All';

  @override
  String get attendanceFilterCheckedIn => 'Checked in today';

  @override
  String get attendanceFilterNotCheckedIn => 'Not checked in';

  @override
  String get attendanceFilterEmpty =>
      'No drivers match this attendance filter.';

  @override
  String get attendanceOnTrip => 'On trip';

  @override
  String get attendanceAdjustTitle => 'Adjust attendance';

  @override
  String get attendanceWorkDate => 'Work date';

  @override
  String get attendanceCheckInTime => 'Check-in time';

  @override
  String get attendanceCheckOutTime => 'Check-out time';

  @override
  String get attendanceReasonLabel => 'Reason';

  @override
  String get attendanceReasonRequired => 'Enter a reason.';

  @override
  String get attendanceAdjustSave => 'Save';

  @override
  String get attendanceCancel => 'Cancel';

  @override
  String get attendanceQrTitle => 'Attendance QR';

  @override
  String get attendanceOffDay => 'Today is a weekly day off.';

  @override
  String get locationPreciseRequired => 'Precise location is required.';

  @override
  String get locationInaccurate =>
      'The location reading is not accurate enough.';

  @override
  String get locationMocked => 'Mock locations are not allowed.';

  @override
  String get slideToCheckIn => 'Slide to check in';

  @override
  String get slideToCheckOut => 'Slide to check out';

  @override
  String get formSectionPersonal => 'Personal details';

  @override
  String get formSectionContact => 'Contact';

  @override
  String get formSectionVehicle => 'Vehicle & license';

  @override
  String get formSectionAccess => 'Sign-in';

  @override
  String get formSectionWork => 'Work';

  @override
  String get formSectionLocation => 'Location';

  @override
  String get formSectionPlace => 'Place details';

  @override
  String get formFixErrors => 'Check the highlighted fields.';

  @override
  String get passwordStrengthWeak => 'Weak';

  @override
  String get passwordStrengthFair => 'Fair';

  @override
  String get passwordStrengthGood => 'Good';

  @override
  String get passwordStrengthStrong => 'Strong';

  @override
  String get clearSearch => 'Clear search';

  @override
  String get adminTripsWeekTitle => 'Trips this week';

  @override
  String get adminTripsWeekSubtitle => 'Scheduled per day, last 7 days';
}
