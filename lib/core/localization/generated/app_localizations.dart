import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'generated/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application title shown in the app bar and task switcher
  ///
  /// In en, this message translates to:
  /// **'TeleCars'**
  String get appTitle;

  /// Label for switching to English
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get languageEnglish;

  /// Label for switching to Arabic
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get languageArabic;

  /// Title of the sign-in screen
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get loginTitle;

  /// Supporting text on the sign-in screen
  ///
  /// In en, this message translates to:
  /// **'Sign in with your company account.'**
  String get loginSubtitle;

  /// Title of the employee registration screen
  ///
  /// In en, this message translates to:
  /// **'Employee registration'**
  String get registerTitle;

  /// Supporting text explaining that registration creates an employee
  ///
  /// In en, this message translates to:
  /// **'New accounts are created as employees.'**
  String get registerSubtitle;

  /// Label for the name field
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get nameLabel;

  /// Label for the email field
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get emailLabel;

  /// Label for the password field
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get passwordLabel;

  /// Label for the confirm-password field
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPasswordLabel;

  /// Button that submits the sign-in form
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get signIn;

  /// Button that signs the current user out
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get signOut;

  /// Action that opens employee registration or submits it
  ///
  /// In en, this message translates to:
  /// **'Create an employee account'**
  String get createEmployeeAccount;

  /// Action that returns from registration to sign-in
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get alreadyHaveAccount;

  /// Validation message when the name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get validationNameRequired;

  /// Validation message when the email is empty
  ///
  /// In en, this message translates to:
  /// **'Enter your email.'**
  String get validationEmailRequired;

  /// Validation message when the email format is invalid
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get validationEmailInvalid;

  /// Validation message when the password is empty
  ///
  /// In en, this message translates to:
  /// **'Enter your password.'**
  String get validationPasswordRequired;

  /// Validation message when the password is shorter than 8 characters
  ///
  /// In en, this message translates to:
  /// **'Use at least 8 characters.'**
  String get validationPasswordShort;

  /// Validation message when password confirmation is empty
  ///
  /// In en, this message translates to:
  /// **'Confirm your password.'**
  String get validationConfirmPasswordRequired;

  /// Validation message when the passwords differ
  ///
  /// In en, this message translates to:
  /// **'The passwords do not match.'**
  String get validationPasswordMismatch;

  /// Tooltip for revealing a password
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// Tooltip for hiding a password
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// Semantics label for a progress indicator
  ///
  /// In en, this message translates to:
  /// **'Loading'**
  String get loading;

  /// Button that retries loading the signed-in user
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get tryAgain;

  /// Title shown when auth state cannot be resolved
  ///
  /// In en, this message translates to:
  /// **'Could not continue'**
  String get couldNotContinue;

  /// Title of the company admin home screen
  ///
  /// In en, this message translates to:
  /// **'Company admin'**
  String get companyAdminHomeTitle;

  /// Title of the drivers admin home screen
  ///
  /// In en, this message translates to:
  /// **'Drivers admin'**
  String get driversAdminHomeTitle;

  /// Title of the driver home screen
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get driverHomeTitle;

  /// Title of the employee home screen
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get employeeHomeTitle;

  /// Greeting on a role home screen
  ///
  /// In en, this message translates to:
  /// **'Welcome, {name}'**
  String roleHomeWelcome(String name);

  /// Supporting text on the company admin home screen
  ///
  /// In en, this message translates to:
  /// **'Review trip requests and overall trip progress.'**
  String get companyAdminHomeSubtitle;

  /// Tab label for the trip requests list
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get requestsTab;

  /// Tab label for the pending trip requests queue
  ///
  /// In en, this message translates to:
  /// **'Pending requests'**
  String get pendingRequestsTab;

  /// Tab label for the trips list
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get tripsTab;

  /// Tab label for the approved places list
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get placesTab;

  /// Title when there are no approved places
  ///
  /// In en, this message translates to:
  /// **'No places yet'**
  String get placesEmptyTitle;

  /// Supporting text when there are no approved places
  ///
  /// In en, this message translates to:
  /// **'Seed the company places list, or add a place manually. Active places appear for employees when they request a trip.'**
  String get placesEmptyMessage;

  /// Button that opens the add-place form
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get addPlace;

  /// Title of the add-place dialog
  ///
  /// In en, this message translates to:
  /// **'Add place'**
  String get addPlaceTitle;

  /// Tooltip for editing a place
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get editPlace;

  /// Title of the edit-place dialog
  ///
  /// In en, this message translates to:
  /// **'Edit place'**
  String get editPlaceTitle;

  /// Button that saves place edits
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get savePlace;

  /// Label for the English place name field
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get placeNameEnLabel;

  /// Label for the Arabic place name field
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get placeNameArLabel;

  /// Switch label marking a place as the company HQ
  ///
  /// In en, this message translates to:
  /// **'Company headquarters'**
  String get placeHeadquartersLabel;

  /// Hint under the headquarters switch in the place form
  ///
  /// In en, this message translates to:
  /// **'Only one place can be headquarters. Turning this on clears the flag on other places.'**
  String get placeHeadquartersHint;

  /// Badge shown on the places list for the HQ place
  ///
  /// In en, this message translates to:
  /// **'Headquarters'**
  String get placeHeadquartersBadge;

  /// Subtitle when a place is active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get placeStatusActive;

  /// Subtitle when a place is inactive
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get placeStatusInactive;

  /// SnackBar after a place is created
  ///
  /// In en, this message translates to:
  /// **'Place added.'**
  String get placeCreated;

  /// SnackBar after a place is edited
  ///
  /// In en, this message translates to:
  /// **'Place updated.'**
  String get placeUpdated;

  /// Tooltip and confirm action for deleting a place
  ///
  /// In en, this message translates to:
  /// **'Delete place'**
  String get deletePlace;

  /// Title of the delete-place confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Delete this place?'**
  String get deletePlaceConfirmTitle;

  /// Body of the delete-place confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'\"{name}\" will be removed from the approved places list.'**
  String deletePlaceConfirmMessage(String name);

  /// SnackBar after a place is deleted
  ///
  /// In en, this message translates to:
  /// **'Place deleted.'**
  String get placeDeleted;

  /// One-time action that creates company default places when the list is empty
  ///
  /// In en, this message translates to:
  /// **'Seed default places'**
  String get seedDefaultPlaces;

  /// SnackBar after default places are seeded
  ///
  /// In en, this message translates to:
  /// **'Default places created.'**
  String get placesSeeded;

  /// Validation when the English place name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the English name.'**
  String get validationPlaceNameEnRequired;

  /// Validation when the Arabic place name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the Arabic name.'**
  String get validationPlaceNameArRequired;

  /// Validation when a place name duplicates an existing one
  ///
  /// In en, this message translates to:
  /// **'A place with this name already exists.'**
  String get validationPlaceNameDuplicate;

  /// Friendly message for ConflictFailure
  ///
  /// In en, this message translates to:
  /// **'That name is already in use.'**
  String get errorConflict;

  /// Title when the pending requests queue is empty
  ///
  /// In en, this message translates to:
  /// **'No pending requests'**
  String get pendingRequestsEmptyTitle;

  /// Supporting text when there are no pending requests
  ///
  /// In en, this message translates to:
  /// **'New employee trip requests will show up here.'**
  String get pendingRequestsEmptyMessage;

  /// Title when there are no trips
  ///
  /// In en, this message translates to:
  /// **'No trips yet'**
  String get tripsEmptyTitle;

  /// Supporting text when there are no trips
  ///
  /// In en, this message translates to:
  /// **'Trips created by the drivers admin will appear here.'**
  String get tripsEmptyMessage;

  /// Button that approves a pending trip request
  ///
  /// In en, this message translates to:
  /// **'Approve'**
  String get approveTripRequest;

  /// Title of the approve confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Approve this request?'**
  String get approveTripRequestTitle;

  /// Body of the approve confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'The request will move to approved so the drivers admin can create a trip.'**
  String get approveTripRequestMessage;

  /// Confirm action in the approve dialog
  ///
  /// In en, this message translates to:
  /// **'Approve request'**
  String get confirmApproveTripRequest;

  /// SnackBar after a trip request is approved
  ///
  /// In en, this message translates to:
  /// **'Trip request approved.'**
  String get tripRequestApproved;

  /// Button that opens the reject-request dialog
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get rejectTripRequest;

  /// Title of the reject confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Reject this request?'**
  String get rejectTripRequestTitle;

  /// Body of the reject confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'The employee will see this request as rejected.'**
  String get rejectTripRequestMessage;

  /// Label for the optional rejection reason field
  ///
  /// In en, this message translates to:
  /// **'Reason (optional)'**
  String get rejectionReasonLabel;

  /// Hint for the optional rejection reason field
  ///
  /// In en, this message translates to:
  /// **'Tell the employee why it was rejected'**
  String get rejectionReasonHint;

  /// Confirm action in the reject dialog
  ///
  /// In en, this message translates to:
  /// **'Reject request'**
  String get confirmRejectTripRequest;

  /// Generic cancel action that closes a dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get dialogCancel;

  /// SnackBar after a trip request is rejected
  ///
  /// In en, this message translates to:
  /// **'Trip request rejected.'**
  String get tripRequestRejected;

  /// How many pending requests are selected
  ///
  /// In en, this message translates to:
  /// **'{count} selected'**
  String selectedRequestsCount(int count);

  /// Action that uses the OneRequestPerTrip strategy
  ///
  /// In en, this message translates to:
  /// **'Create one trip per request'**
  String get createOneTripPerRequest;

  /// Action that uses the GroupedRequests strategy
  ///
  /// In en, this message translates to:
  /// **'Group into one trip'**
  String get groupIntoOneTrip;

  /// Dismissible banner above the pending requests list
  ///
  /// In en, this message translates to:
  /// **'{count} requests look groupable'**
  String groupingSuggestionBanner(int count);

  /// Tooltip for closing the grouping suggestion banner
  ///
  /// In en, this message translates to:
  /// **'Dismiss'**
  String get groupingSuggestionDismiss;

  /// Title of the bottom sheet listing suggested request clusters
  ///
  /// In en, this message translates to:
  /// **'Suggested groupings'**
  String get groupingSuggestionsSheetTitle;

  /// Empty state when all suggestions were ignored or approved
  ///
  /// In en, this message translates to:
  /// **'No grouping suggestions left.'**
  String get groupingSuggestionsEmpty;

  /// Time span line on a suggested cluster card
  ///
  /// In en, this message translates to:
  /// **'Time: {span}'**
  String groupingSuggestionTimeSpan(String span);

  /// How many requests are in a suggested cluster
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 request} other{{count} requests}}'**
  String groupingSuggestionRequestCount(int count);

  /// Tooltip to remove one request from a suggested cluster
  ///
  /// In en, this message translates to:
  /// **'Remove from group'**
  String get groupingSuggestionRemoveRequest;

  /// Approves all requests in the cluster with a shared suggestedGroupId
  ///
  /// In en, this message translates to:
  /// **'Approve as group'**
  String get groupingSuggestionApproveAsGroup;

  /// Dismisses one suggested cluster without approving
  ///
  /// In en, this message translates to:
  /// **'Ignore'**
  String get groupingSuggestionIgnore;

  /// SnackBar after approving a suggested cluster
  ///
  /// In en, this message translates to:
  /// **'Requests approved as a group.'**
  String get groupingSuggestionApproved;

  /// Drivers Admin card title for requests sharing suggestedGroupId
  ///
  /// In en, this message translates to:
  /// **'Suggested group ({count})'**
  String suggestedGroupTitle(int count);

  /// Employee names on a suggested group card
  ///
  /// In en, this message translates to:
  /// **'Employees: {names}'**
  String suggestedGroupEmployees(String names);

  /// Drivers Admin action using GroupedRequests for a suggested group
  ///
  /// In en, this message translates to:
  /// **'Create grouped trip'**
  String get createGroupedTrip;

  /// Breaks a suggested group so requests can be handled individually
  ///
  /// In en, this message translates to:
  /// **'Split'**
  String get splitSuggestedGroup;

  /// SnackBar after trips are created from requests
  ///
  /// In en, this message translates to:
  /// **'Trip(s) created.'**
  String get tripsCreated;

  /// Destination line on a request card
  ///
  /// In en, this message translates to:
  /// **'To: {destination}'**
  String tripRequestDestinationValue(String destination);

  /// Scheduled time line on a trip card
  ///
  /// In en, this message translates to:
  /// **'Scheduled: {dateTime}'**
  String tripScheduledValue(String dateTime);

  /// Passenger count on a trip summary card
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 passenger} other{{count} passengers}}'**
  String tripPassengersCount(int count);

  /// Title of the trip details screen
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripDetailsTitle;

  /// Section heading for passengers on trip details
  ///
  /// In en, this message translates to:
  /// **'Passengers'**
  String get tripPassengersSection;

  /// Section heading for linked requests on trip details
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get tripRequestsSection;

  /// Status chip for an unassigned trip
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get tripStatusUnassigned;

  /// Status chip for an assigned trip
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get tripStatusAssigned;

  /// Status chip for a trip en route to destination
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get tripStatusGoing;

  /// Status chip while the driver is at the destination
  ///
  /// In en, this message translates to:
  /// **'At destination'**
  String get tripStatusAtDestination;

  /// Status chip for the return leg of a trip
  ///
  /// In en, this message translates to:
  /// **'Returning'**
  String get tripStatusReturning;

  /// Status chip for a completed trip
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripStatusCompleted;

  /// Status chip for a cancelled trip
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripStatusCancelled;

  /// Driver action to mark arrival at destination
  ///
  /// In en, this message translates to:
  /// **'Arrived at destination'**
  String get arrivedAtDestination;

  /// Confirm dialog title for arrive action
  ///
  /// In en, this message translates to:
  /// **'Mark arrived at destination?'**
  String get arrivedAtDestinationConfirmTitle;

  /// Confirm dialog body for arrive action
  ///
  /// In en, this message translates to:
  /// **'This ends the going phase and saves the route so far.'**
  String get arrivedAtDestinationConfirmMessage;

  /// SnackBar after arrive action succeeds
  ///
  /// In en, this message translates to:
  /// **'Arrived at destination.'**
  String get arrivedAtDestinationSuccess;

  /// Driver action to begin the return leg
  ///
  /// In en, this message translates to:
  /// **'Start return'**
  String get startReturn;

  /// Confirm dialog title for start return
  ///
  /// In en, this message translates to:
  /// **'Start the return leg?'**
  String get startReturnConfirmTitle;

  /// Confirm dialog body for start return
  ///
  /// In en, this message translates to:
  /// **'Location tracking resumes for the trip back.'**
  String get startReturnConfirmMessage;

  /// SnackBar after start return succeeds
  ///
  /// In en, this message translates to:
  /// **'Return started.'**
  String get startReturnSuccess;

  /// Title when when-in-use location was denied
  ///
  /// In en, this message translates to:
  /// **'Location permission needed'**
  String get locationPermissionDeniedTitle;

  /// Body when location permission was denied
  ///
  /// In en, this message translates to:
  /// **'Allow location while using the app so dispatch can follow your trip.'**
  String get locationPermissionDeniedMessage;

  /// Body when location permission is permanently denied
  ///
  /// In en, this message translates to:
  /// **'Location access is blocked. Open app settings to enable it.'**
  String get locationPermissionPermanentlyDeniedMessage;

  /// Body when device location services are off
  ///
  /// In en, this message translates to:
  /// **'Turn on GPS / location services to share your trip position.'**
  String get locationServicesDisabledMessage;

  /// Button that opens the system app settings page
  ///
  /// In en, this message translates to:
  /// **'Open app settings'**
  String get openAppSettings;

  /// Button that opens system location settings
  ///
  /// In en, this message translates to:
  /// **'Enable location services'**
  String get enableLocationServices;

  /// Supporting text on the drivers admin home screen
  ///
  /// In en, this message translates to:
  /// **'Manage drivers and assign trips.'**
  String get driversAdminHomeSubtitle;

  /// Tab label for the drivers list
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get driversTab;

  /// Title when there are no drivers
  ///
  /// In en, this message translates to:
  /// **'No drivers exist yet'**
  String get driversEmptyTitle;

  /// Supporting text when there are no drivers
  ///
  /// In en, this message translates to:
  /// **'Add a driver account to start assigning trips.'**
  String get driversEmptyMessage;

  /// Admin action that backfills missing fields on old driver documents
  ///
  /// In en, this message translates to:
  /// **'Fix legacy drivers'**
  String get fixLegacyDrivers;

  /// Title of the confirmation dialog for legacy driver backfill
  ///
  /// In en, this message translates to:
  /// **'Fix legacy driver profiles?'**
  String get fixLegacyDriversConfirmTitle;

  /// Body of the confirmation dialog for legacy driver backfill
  ///
  /// In en, this message translates to:
  /// **'This writes missing defaults (active status and bilingual names from the old name) onto driver accounts that still use the previous format.'**
  String get fixLegacyDriversConfirmMessage;

  /// Confirm button for legacy driver backfill
  ///
  /// In en, this message translates to:
  /// **'Fix now'**
  String get fixLegacyDriversConfirmAction;

  /// SnackBar after legacy driver documents were patched
  ///
  /// In en, this message translates to:
  /// **'{count} driver profiles updated.'**
  String fixLegacyDriversSuccess(int count);

  /// SnackBar when no legacy driver documents needed a patch
  ///
  /// In en, this message translates to:
  /// **'All driver profiles already look up to date.'**
  String get fixLegacyDriversNone;

  /// Button that opens the add-driver form
  ///
  /// In en, this message translates to:
  /// **'Add driver'**
  String get addDriver;

  /// Title of the add-driver dialog
  ///
  /// In en, this message translates to:
  /// **'Add driver'**
  String get addDriverTitle;

  /// Label for the optional phone field
  ///
  /// In en, this message translates to:
  /// **'Phone (optional)'**
  String get phoneLabelOptional;

  /// Label for the temporary password field when creating a driver
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get temporaryPasswordLabel;

  /// Subtitle when a driver is active
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get driverStatusActive;

  /// Subtitle when a driver is inactive
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get driverStatusInactive;

  /// SnackBar after a driver is created
  ///
  /// In en, this message translates to:
  /// **'Driver account created.'**
  String get driverCreated;

  /// Validation when the phone number exceeds the max length
  ///
  /// In en, this message translates to:
  /// **'Phone number is too long.'**
  String get validationPhoneTooLong;

  /// Friendly message when an inactive driver tries to sign in
  ///
  /// In en, this message translates to:
  /// **'This driver account is inactive. Contact an administrator.'**
  String get errorAccountInactive;

  /// Friendly message when the account was created but the profile could not be saved and cleanup failed
  ///
  /// In en, this message translates to:
  /// **'The account was created but the profile could not be saved, and cleanup failed. Contact an administrator.'**
  String get errorOrphanedAccountCleanupFailed;

  /// Tab for trips with no driver
  ///
  /// In en, this message translates to:
  /// **'Unassigned'**
  String get tripsUnassignedTab;

  /// Tab for trips that have a driver
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get tripsAssignedTab;

  /// Tab for every trip
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get tripsAllTab;

  /// Title when a drivers-admin trips filter is empty
  ///
  /// In en, this message translates to:
  /// **'No trips here'**
  String get adminTripsEmptyTitle;

  /// Empty message for the unassigned trips tab
  ///
  /// In en, this message translates to:
  /// **'Unassigned trips from company admin will show up here.'**
  String get adminTripsUnassignedEmptyMessage;

  /// Empty message for the assigned trips tab
  ///
  /// In en, this message translates to:
  /// **'Assigned trips will show up here.'**
  String get adminTripsAssignedEmptyMessage;

  /// Empty message for the all-trips tab
  ///
  /// In en, this message translates to:
  /// **'Trips created by company admin will show up here.'**
  String get adminTripsAllEmptyMessage;

  /// Short pickup to destination route on a trip card
  ///
  /// In en, this message translates to:
  /// **'{pickup} → {destination}'**
  String tripRouteSummary(String pickup, String destination);

  /// Button that opens the driver picker for an unassigned trip
  ///
  /// In en, this message translates to:
  /// **'Assign driver'**
  String get assignDriver;

  /// Button that opens the driver picker to change the assigned driver
  ///
  /// In en, this message translates to:
  /// **'Reassign driver'**
  String get reassignDriver;

  /// Button that cancels a trip that has not started
  ///
  /// In en, this message translates to:
  /// **'Cancel trip'**
  String get cancelTrip;

  /// Title of the cancel-trip confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel this trip?'**
  String get cancelTripConfirmTitle;

  /// Body of the cancel-trip confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This trip has not started and will be marked cancelled.'**
  String get cancelTripConfirmMessage;

  /// Confirm action in the cancel-trip dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel trip'**
  String get confirmCancelTrip;

  /// SnackBar after a trip is cancelled
  ///
  /// In en, this message translates to:
  /// **'Trip cancelled.'**
  String get tripCancelled;

  /// SnackBar after a driver is assigned to a trip
  ///
  /// In en, this message translates to:
  /// **'Driver assigned.'**
  String get tripDriverAssigned;

  /// SnackBar after a trip driver is changed
  ///
  /// In en, this message translates to:
  /// **'Driver reassigned.'**
  String get tripDriverReassigned;

  /// Title of the active-driver picker sheet
  ///
  /// In en, this message translates to:
  /// **'Select a driver'**
  String get selectDriverTitle;

  /// Message when the assignment picker has no active drivers
  ///
  /// In en, this message translates to:
  /// **'No active drivers available. Activate a driver first.'**
  String get noActiveDriversMessage;

  /// Title of the warning when a driver has another nearby trip
  ///
  /// In en, this message translates to:
  /// **'Schedule overlap'**
  String get driverScheduleConflictTitle;

  /// Body of the schedule-overlap warning (warning, not a block)
  ///
  /// In en, this message translates to:
  /// **'This driver already has another trip within two hours of this time. You can still assign them.'**
  String get driverScheduleConflictMessage;

  /// Confirm action that continues despite a schedule overlap warning
  ///
  /// In en, this message translates to:
  /// **'Assign anyway'**
  String get driverScheduleConflictContinue;

  /// Hint under a driver name when they have a nearby trip
  ///
  /// In en, this message translates to:
  /// **'Has another trip within 2 hours'**
  String get driverHasNearbyTripHint;

  /// Assigned driver line on trip details
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String tripAssignedDriverValue(String name);

  /// Supporting text describing the driver home trips view
  ///
  /// In en, this message translates to:
  /// **'View assigned, weekly, and past trips.'**
  String get driverHomeSubtitle;

  /// Tab for the driver's active assigned and in-progress trips
  ///
  /// In en, this message translates to:
  /// **'Assigned'**
  String get driverTripsAssignedTab;

  /// Tab for trips scheduled in the current week
  ///
  /// In en, this message translates to:
  /// **'This week'**
  String get driverTripsWeeklyTab;

  /// Tab for completed and cancelled trips
  ///
  /// In en, this message translates to:
  /// **'Past'**
  String get driverTripsPastTab;

  /// Title when a driver trips tab has no items
  ///
  /// In en, this message translates to:
  /// **'No trips here'**
  String get driverTripsEmptyTitle;

  /// Empty message for the driver's assigned trips tab
  ///
  /// In en, this message translates to:
  /// **'Trips assigned to you will appear here.'**
  String get driverTripsAssignedEmptyMessage;

  /// Empty message for the driver's weekly trips tab
  ///
  /// In en, this message translates to:
  /// **'No trips planned for this week.'**
  String get driverTripsWeeklyEmptyMessage;

  /// Empty message for the driver's past trips tab
  ///
  /// In en, this message translates to:
  /// **'Completed and cancelled trips will appear here.'**
  String get driverTripsPastEmptyMessage;

  /// Button that starts an assigned trip
  ///
  /// In en, this message translates to:
  /// **'Start trip'**
  String get startTrip;

  /// Button that ends an in-progress trip
  ///
  /// In en, this message translates to:
  /// **'End trip'**
  String get endTrip;

  /// Title of the start-trip confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Start this trip?'**
  String get startTripConfirmTitle;

  /// Body of the start-trip confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Passengers will see this trip as in progress.'**
  String get startTripConfirmMessage;

  /// Title of the end-trip confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'End this trip?'**
  String get endTripConfirmTitle;

  /// Body of the end-trip confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This marks the trip as completed.'**
  String get endTripConfirmMessage;

  /// SnackBar after a driver starts a trip
  ///
  /// In en, this message translates to:
  /// **'Trip started.'**
  String get tripStarted;

  /// SnackBar after a driver ends a trip
  ///
  /// In en, this message translates to:
  /// **'Trip completed.'**
  String get tripEnded;

  /// Placeholder text on the employee home screen
  ///
  /// In en, this message translates to:
  /// **'Your trip requests will appear here.'**
  String get employeeHomeSubtitle;

  /// Empty state on a role home screen
  ///
  /// In en, this message translates to:
  /// **'Nothing to show yet.'**
  String get homeEmpty;

  /// Friendly message for NetworkFailure
  ///
  /// In en, this message translates to:
  /// **'Unable to connect. Check your internet and try again.'**
  String get errorNetwork;

  /// Friendly message for a generic AuthFailure
  ///
  /// In en, this message translates to:
  /// **'Authentication failed. Please sign in again.'**
  String get errorAuth;

  /// Friendly message for PermissionFailure
  ///
  /// In en, this message translates to:
  /// **'You do not have permission to do that.'**
  String get errorPermission;

  /// Friendly message for UnknownFailure
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errorUnknown;

  /// Friendly message when the email is rejected
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get errorInvalidEmail;

  /// Friendly message for a failed sign-in
  ///
  /// In en, this message translates to:
  /// **'The email or password is incorrect.'**
  String get errorInvalidCredentials;

  /// Friendly message when the account is disabled
  ///
  /// In en, this message translates to:
  /// **'This account is disabled. Contact an administrator.'**
  String get errorUserDisabled;

  /// Friendly message when registration uses an existing email
  ///
  /// In en, this message translates to:
  /// **'This email is already registered.'**
  String get errorEmailAlreadyInUse;

  /// Friendly message when the password is rejected as weak
  ///
  /// In en, this message translates to:
  /// **'The password is too weak. Use at least 8 characters.'**
  String get errorWeakPassword;

  /// Friendly message when sign-in is rate limited
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Wait a moment and try again.'**
  String get errorTooManyRequests;

  /// Friendly message when email auth is disabled
  ///
  /// In en, this message translates to:
  /// **'Email sign-in is not available.'**
  String get errorOperationNotAllowed;

  /// Friendly message when the signed-in account has no profile
  ///
  /// In en, this message translates to:
  /// **'This account has no user profile. Contact an administrator or register again.'**
  String get errorMissingProfile;

  /// Friendly message when the stored profile cannot be read
  ///
  /// In en, this message translates to:
  /// **'This account profile is invalid. Contact an administrator.'**
  String get errorInvalidProfile;

  /// Friendly message for NotFoundFailure
  ///
  /// In en, this message translates to:
  /// **'That item could not be found.'**
  String get errorNotFound;

  /// Friendly message for InvalidStateFailure
  ///
  /// In en, this message translates to:
  /// **'That action is not available for the current status.'**
  String get errorInvalidState;

  /// Title shown when the employee has no trip requests
  ///
  /// In en, this message translates to:
  /// **'No trip requests yet'**
  String get tripRequestsEmptyTitle;

  /// Supporting text for the empty trip requests state
  ///
  /// In en, this message translates to:
  /// **'Tap + to request a company car trip.'**
  String get tripRequestsEmptyMessage;

  /// Tooltip and action label for creating a trip request
  ///
  /// In en, this message translates to:
  /// **'New trip request'**
  String get newTripRequest;

  /// Title of the new trip request form
  ///
  /// In en, this message translates to:
  /// **'New request'**
  String get newTripRequestTitle;

  /// Label for the pickup place dropdown
  ///
  /// In en, this message translates to:
  /// **'Pickup place'**
  String get pickupLocationLabel;

  /// Label for the destination place dropdown
  ///
  /// In en, this message translates to:
  /// **'Destination place'**
  String get destinationLabel;

  /// Hint inside the searchable place dropdown
  ///
  /// In en, this message translates to:
  /// **'Search places'**
  String get searchPlacesHint;

  /// Dropdown option for a place not in the approved list
  ///
  /// In en, this message translates to:
  /// **'Other (not listed)'**
  String get otherPlaceOption;

  /// Label for the free-text custom place field
  ///
  /// In en, this message translates to:
  /// **'Custom place'**
  String get customPlaceLabel;

  /// Hint for the free-text custom place field
  ///
  /// In en, this message translates to:
  /// **'Type the place name'**
  String get customPlaceHint;

  /// Title when the employee cannot pick places yet
  ///
  /// In en, this message translates to:
  /// **'No places available'**
  String get noPlacesForRequestTitle;

  /// Supporting text when no approved places exist for trip requests
  ///
  /// In en, this message translates to:
  /// **'Contact your company admin to add approved places before requesting a trip.'**
  String get noPlacesForRequestMessage;

  /// Label for the requested date and time field
  ///
  /// In en, this message translates to:
  /// **'Date and time'**
  String get requestedDateTimeLabel;

  /// Help text for the date picker
  ///
  /// In en, this message translates to:
  /// **'Select date'**
  String get selectDate;

  /// Help text for the time picker
  ///
  /// In en, this message translates to:
  /// **'Select time'**
  String get selectTime;

  /// Placeholder when no date/time is chosen yet
  ///
  /// In en, this message translates to:
  /// **'Select date and time'**
  String get selectDateTime;

  /// Label for optional trip request notes
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get notesLabel;

  /// Hint under notes telling employees to list fellow riders by name only
  ///
  /// In en, this message translates to:
  /// **'One fellow employee name per line (do not include phone numbers).'**
  String get notesHint;

  /// Extra helper text under the notes field on the new-request form
  ///
  /// In en, this message translates to:
  /// **'Write one name per line. Their phone numbers are never shared.'**
  String get notesFellowEmployeesHint;

  /// Button that inserts a new line in notes for another fellow employee name
  ///
  /// In en, this message translates to:
  /// **'Add another name'**
  String get addAnotherNameLine;

  /// Button that creates a trip request
  ///
  /// In en, this message translates to:
  /// **'Submit request'**
  String get submitTripRequest;

  /// Button that cancels a pending trip request
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get cancelTripRequest;

  /// Title of the cancel confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel this request?'**
  String get cancelTripRequestConfirmTitle;

  /// Body of the cancel confirmation dialog
  ///
  /// In en, this message translates to:
  /// **'This pending request will be cancelled. You can create a new one later.'**
  String get cancelTripRequestConfirmMessage;

  /// Confirm action in the cancel dialog
  ///
  /// In en, this message translates to:
  /// **'Cancel request'**
  String get confirmCancelTripRequest;

  /// Dismiss action that keeps the pending request
  ///
  /// In en, this message translates to:
  /// **'Keep request'**
  String get dialogDismiss;

  /// Status chip for a pending trip request
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get tripRequestStatusPending;

  /// Status chip for an approved trip request
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get tripRequestStatusApproved;

  /// Status chip for a rejected trip request
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get tripRequestStatusRejected;

  /// Status chip for a cancelled trip request
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get tripRequestStatusCancelled;

  /// Pickup line on a trip request card
  ///
  /// In en, this message translates to:
  /// **'From: {pickup}'**
  String tripRequestPickupValue(String pickup);

  /// Requested date/time line on a trip request card
  ///
  /// In en, this message translates to:
  /// **'When: {dateTime}'**
  String tripRequestWhenValue(String dateTime);

  /// Notes line on a trip request card
  ///
  /// In en, this message translates to:
  /// **'Notes: {notes}'**
  String tripRequestNotesValue(String notes);

  /// Validation when pickup place is missing
  ///
  /// In en, this message translates to:
  /// **'Select a pickup place.'**
  String get validationPickupPlaceRequired;

  /// Validation when destination place is missing
  ///
  /// In en, this message translates to:
  /// **'Select a destination place.'**
  String get validationDestinationPlaceRequired;

  /// Validation when Other is selected but the custom name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the custom place name.'**
  String get validationCustomPlaceRequired;

  /// Validation when pickup and destination are the same place
  ///
  /// In en, this message translates to:
  /// **'Pickup and destination must be different places.'**
  String get validationPickupDestinationSame;

  /// Validation when date/time is missing
  ///
  /// In en, this message translates to:
  /// **'Select a date and time.'**
  String get validationDateTimeRequired;

  /// Validation when date/time is not in the future
  ///
  /// In en, this message translates to:
  /// **'Choose a date and time in the future.'**
  String get validationDateTimeFuture;

  /// SnackBar after a trip request is created
  ///
  /// In en, this message translates to:
  /// **'Trip request submitted.'**
  String get tripRequestCreated;

  /// FAB / action for company and drivers admins to request a trip for themselves
  ///
  /// In en, this message translates to:
  /// **'Request a trip'**
  String get requestATrip;

  /// Chip on auto-approved admin self-requests in admin queues
  ///
  /// In en, this message translates to:
  /// **'Admin request'**
  String get adminRequestChip;

  /// SnackBar after a trip request is cancelled
  ///
  /// In en, this message translates to:
  /// **'Trip request cancelled.'**
  String get tripRequestCancelled;

  /// Label for the phone number field
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phoneLabel;

  /// Validation when phone is empty
  ///
  /// In en, this message translates to:
  /// **'Enter your phone number.'**
  String get validationPhoneRequired;

  /// Label for the branch dropdown
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get branchLabel;

  /// Validation when branch is not selected
  ///
  /// In en, this message translates to:
  /// **'Select your branch.'**
  String get validationBranchRequired;

  /// Branch option: company headquarters
  ///
  /// In en, this message translates to:
  /// **'Company Headquarters'**
  String get branchCompanyHeadquarters;

  /// Branch option: new headquarters
  ///
  /// In en, this message translates to:
  /// **'New Headquarters'**
  String get branchNewHeadquarters;

  /// Branch filter chip that shows every branch
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get branchFilterAll;

  /// Shown under the read-only branch on non-admin profiles
  ///
  /// In en, this message translates to:
  /// **'Contact the admin to change your branch.'**
  String get branchLockedHint;

  /// Company admin requested-trips filter for pending, approved, or rejected
  ///
  /// In en, this message translates to:
  /// **'Approval'**
  String get approvalFilterLabel;

  /// Company admin trips filter for the trip lifecycle
  ///
  /// In en, this message translates to:
  /// **'Trip status'**
  String get tripStatusFilterLabel;

  /// Trip status filter value for unassigned and assigned trips
  ///
  /// In en, this message translates to:
  /// **'Upcoming'**
  String get tripStatusUpcoming;

  /// Trip status filter value for a trip that has started
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tripStatusFilterInProgress;

  /// Shown after a drivers admin creates a trip for themselves
  ///
  /// In en, this message translates to:
  /// **'Your trip is unassigned. Open it here to choose a driver.'**
  String get driversAdminTripUnassigned;

  /// Title of the complete-profile screen
  ///
  /// In en, this message translates to:
  /// **'Complete your profile'**
  String get completeProfileTitle;

  /// Supporting text on the complete-profile screen
  ///
  /// In en, this message translates to:
  /// **'Add your branch and phone number to continue.'**
  String get completeProfileSubtitle;

  /// Button that saves branch and phone
  ///
  /// In en, this message translates to:
  /// **'Save and continue'**
  String get completeProfileSubmit;

  /// SnackBar after profile completion
  ///
  /// In en, this message translates to:
  /// **'Profile updated.'**
  String get completeProfileSaved;

  /// Semantics / tooltip for tap-to-call on the requester phone
  ///
  /// In en, this message translates to:
  /// **'Call {phone}'**
  String callEmployeePhone(String phone);

  /// Section title for the requesting employee on detail screens
  ///
  /// In en, this message translates to:
  /// **'Requester'**
  String get requesterSection;

  /// Heading when a grouped trip has more than one requester
  ///
  /// In en, this message translates to:
  /// **'Requesters'**
  String get requestersSection;

  /// Passenger total on a driver trip, taken from the server count
  ///
  /// In en, this message translates to:
  /// **'Passengers: {count}'**
  String passengersCountLabel(int count);

  /// Title of the trip request details screen
  ///
  /// In en, this message translates to:
  /// **'Request details'**
  String get requestDetailsTitle;

  /// Driver name line on a trip card
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String tripDriverNameValue(String name);

  /// Shown when a trip has no driver yet
  ///
  /// In en, this message translates to:
  /// **'Driver: Unassigned'**
  String get tripDriverUnassigned;

  /// Trip start time line
  ///
  /// In en, this message translates to:
  /// **'Started: {dateTime}'**
  String tripStartedValue(String dateTime);

  /// Trip end time line
  ///
  /// In en, this message translates to:
  /// **'Ended: {dateTime}'**
  String tripEndedValue(String dateTime);

  /// Shown when startedAt is null
  ///
  /// In en, this message translates to:
  /// **'Not started yet'**
  String get tripNotStartedYet;

  /// Shown when endedAt is null
  ///
  /// In en, this message translates to:
  /// **'Not ended yet'**
  String get tripNotEndedYet;

  /// Drivers admin tab for approved requests awaiting a trip
  ///
  /// In en, this message translates to:
  /// **'Approved requests'**
  String get approvedRequestsTab;

  /// Title when there are no approved requests awaiting trips
  ///
  /// In en, this message translates to:
  /// **'No approved requests'**
  String get approvedRequestsEmptyTitle;

  /// Supporting text when approved-awaiting-trip queue is empty
  ///
  /// In en, this message translates to:
  /// **'Approved requests that are not yet in a trip will show up here.'**
  String get approvedRequestsEmptyMessage;

  /// Trips filter for started trips
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get tripsInProgressTab;

  /// Trips filter for completed trips
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get tripsCompletedTab;

  /// Empty state for in-progress trips filter
  ///
  /// In en, this message translates to:
  /// **'No trips in progress.'**
  String get adminTripsInProgressEmptyMessage;

  /// Empty state for completed trips filter
  ///
  /// In en, this message translates to:
  /// **'No completed trips yet.'**
  String get adminTripsCompletedEmptyMessage;

  /// Drivers admin tab for the live map
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get liveMapTab;

  /// Title of driver and admin live map screens
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get liveMapTitle;

  /// Chip when the driver is sharing GPS with dispatch
  ///
  /// In en, this message translates to:
  /// **'Sharing location'**
  String get sharingLocation;

  /// Chip when location sharing is disabled
  ///
  /// In en, this message translates to:
  /// **'Location off'**
  String get locationSharingOff;

  /// Shown when a live GPS read or upload fails but the previous point is kept
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t send a new position. Dispatch still has your last known location.'**
  String get locationUpdateKeptLast;

  /// Banner when trip starts without location permission
  ///
  /// In en, this message translates to:
  /// **'Trip started, but location sharing is off. Tap Location off to enable GPS for dispatch.'**
  String get locationSharingWarning;

  /// Note on the map when place coordinates are missing
  ///
  /// In en, this message translates to:
  /// **'Destination location not set'**
  String get destinationLocationNotSet;

  /// Floating button to re-enable follow mode on the driver map
  ///
  /// In en, this message translates to:
  /// **'Recenter'**
  String get recenterMap;

  /// Straight-line distance remaining to destination
  ///
  /// In en, this message translates to:
  /// **'{km} km remaining'**
  String distanceRemainingKm(String km);

  /// Label for fellow passengers listed in trip request notes
  ///
  /// In en, this message translates to:
  /// **'Passengers (from notes)'**
  String get passengersFromNotes;

  /// Link from an in-progress trip to the live map
  ///
  /// In en, this message translates to:
  /// **'Open live map'**
  String get openLiveMap;

  /// Empty-state title when no drivers are tracking
  ///
  /// In en, this message translates to:
  /// **'No active trips right now'**
  String get noActiveTripsRightNow;

  /// Empty-state message for the admin live map
  ///
  /// In en, this message translates to:
  /// **'A started trip appears here only after the driver app is sharing GPS (Location allowed + a GPS fix). Check the driver device if this stays empty.'**
  String get noActiveTripsRightNowMessage;

  /// Button that zooms the admin map to show all active drivers
  ///
  /// In en, this message translates to:
  /// **'Fit all'**
  String get fitAllDrivers;

  /// Stale driver marker label
  ///
  /// In en, this message translates to:
  /// **'Last seen {minutes} min ago'**
  String lastSeenMinutesAgo(int minutes);

  /// Driver speed on the admin bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Speed: {speed} km/h'**
  String speedKmh(String speed);

  /// Last GPS update time on the admin bottom sheet
  ///
  /// In en, this message translates to:
  /// **'Last update: {time}'**
  String lastUpdateValue(String time);

  /// Button from admin live map sheet to trip details
  ///
  /// In en, this message translates to:
  /// **'Open trip details'**
  String get openTripDetails;

  /// Section label for place lat/lng picker
  ///
  /// In en, this message translates to:
  /// **'Location on map'**
  String get placeCoordinatesLabel;

  /// Button that fills place coordinates from the device GPS
  ///
  /// In en, this message translates to:
  /// **'Use my current location'**
  String get useMyCurrentLocation;

  /// Latitude number field label
  ///
  /// In en, this message translates to:
  /// **'Latitude'**
  String get latitudeLabel;

  /// Longitude number field label
  ///
  /// In en, this message translates to:
  /// **'Longitude'**
  String get longitudeLabel;

  /// Validation when latitude is out of range
  ///
  /// In en, this message translates to:
  /// **'Enter a valid latitude (-90 to 90).'**
  String get validationLatitudeInvalid;

  /// Validation when longitude is out of range
  ///
  /// In en, this message translates to:
  /// **'Enter a valid longitude (-180 to 180).'**
  String get validationLongitudeInvalid;

  /// Validation when place coordinates are missing on save
  ///
  /// In en, this message translates to:
  /// **'Pick a location on the map before saving.'**
  String get validationPlaceLocationRequired;

  /// Address field on the place form
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get placeAddressLabel;

  /// Validation when a place address is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the address.'**
  String get validationPlaceAddressRequired;

  /// Validation when only one place coordinate is filled
  ///
  /// In en, this message translates to:
  /// **'Enter both latitude and longitude, or leave both empty.'**
  String get validationPlaceCoordinatePair;

  /// Explains that a new place can be saved without a map point
  ///
  /// In en, this message translates to:
  /// **'Location is optional. Tap the map or enter latitude and longitude.'**
  String get placeLocationOptionalHint;

  /// Removes the selected place coordinates
  ///
  /// In en, this message translates to:
  /// **'Clear location'**
  String get clearPlaceLocation;

  /// Place list subtitle when lat/lng exist
  ///
  /// In en, this message translates to:
  /// **'Coordinates set'**
  String get placeHasCoordinates;

  /// Place list subtitle when lat/lng are missing
  ///
  /// In en, this message translates to:
  /// **'No coordinates'**
  String get placeMissingCoordinates;

  /// Hint overlay on empty place coordinate picker
  ///
  /// In en, this message translates to:
  /// **'Tap the map to set the location'**
  String get tapMapToSetLocation;

  /// Shown when selecting a legacy place without coordinates
  ///
  /// In en, this message translates to:
  /// **'This place has no location and cannot be used for a trip. Ask an admin to add coordinates.'**
  String get placeCannotSelectWithoutLocation;

  /// Warning badge on places missing latitude/longitude
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get noLocationBadge;

  /// Error when device location services are off
  ///
  /// In en, this message translates to:
  /// **'Turn on location services to continue.'**
  String get locationServicesDisabled;

  /// Error when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location permission is required to share with dispatch.'**
  String get locationPermissionDenied;

  /// Error when GPS fix fails for place picker
  ///
  /// In en, this message translates to:
  /// **'Location is unavailable.'**
  String get locationUnavailable;

  /// App bar title for the map location picker
  ///
  /// In en, this message translates to:
  /// **'Pick a location'**
  String get pickLocationTitle;

  /// FAB tooltip to center the map on the device GPS
  ///
  /// In en, this message translates to:
  /// **'My location'**
  String get myLocationButton;

  /// Hint for Nominatim search field (submit only)
  ///
  /// In en, this message translates to:
  /// **'Search place or address'**
  String get locationSearchHint;

  /// Tooltip for submitting the location search
  ///
  /// In en, this message translates to:
  /// **'Search'**
  String get locationSearchAction;

  /// Empty Nominatim search results
  ///
  /// In en, this message translates to:
  /// **'No places found for that search.'**
  String get locationSearchNoResults;

  /// Nominatim search network or server error
  ///
  /// In en, this message translates to:
  /// **'Search failed. Check your connection and try again.'**
  String get locationSearchFailed;

  /// Shown while reverse-geocoding the map center
  ///
  /// In en, this message translates to:
  /// **'Resolving address…'**
  String get resolvingAddress;

  /// Fallback when reverse geocoding fails
  ///
  /// In en, this message translates to:
  /// **'Address not available'**
  String get addressNotAvailable;

  /// Primary button on the location picker
  ///
  /// In en, this message translates to:
  /// **'Confirm location'**
  String get confirmLocation;

  /// Opens app or location settings from the picker
  ///
  /// In en, this message translates to:
  /// **'Open settings'**
  String get openSettingsAction;

  /// Button next to saved-places selector to open the map picker
  ///
  /// In en, this message translates to:
  /// **'Choose on map'**
  String get chooseOnMap;

  /// Title of the sheet after confirming a map pick
  ///
  /// In en, this message translates to:
  /// **'Name this location'**
  String get nameMapPlaceTitle;

  /// Optional Arabic name when naming a map-picked place
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic, optional)'**
  String get placeNameArOptionalLabel;

  /// Attach map location to the trip without saving a place
  ///
  /// In en, this message translates to:
  /// **'Use for this trip only'**
  String get useLocationForTripOnly;

  /// Create an approved place from the map pick (admins only)
  ///
  /// In en, this message translates to:
  /// **'Save as a new place'**
  String get saveLocationAsPlace;

  /// Badge on trip details for a map-picked place
  ///
  /// In en, this message translates to:
  /// **'Custom location'**
  String get customLocationChip;

  /// Admin button to open the shared location picker
  ///
  /// In en, this message translates to:
  /// **'Pick on map'**
  String get pickLocationOnMap;

  /// Admin button to re-open the picker for existing coordinates
  ///
  /// In en, this message translates to:
  /// **'Edit on map'**
  String get editLocationOnMap;

  /// Collapsed section for typing lat/lng by hand
  ///
  /// In en, this message translates to:
  /// **'Enter coordinates manually'**
  String get enterCoordinatesManually;

  /// Legacy key; prefer noLocationBadge
  ///
  /// In en, this message translates to:
  /// **'No location'**
  String get noMapLocationBadge;

  /// Action to attach coordinates to a place without opening full edit
  ///
  /// In en, this message translates to:
  /// **'Add location'**
  String get addLocationAction;

  /// Action to edit a driver's details
  ///
  /// In en, this message translates to:
  /// **'Edit driver'**
  String get editDriver;

  /// Title of the edit-driver dialog
  ///
  /// In en, this message translates to:
  /// **'Edit driver'**
  String get editDriverTitle;

  /// SnackBar after a driver is edited
  ///
  /// In en, this message translates to:
  /// **'Driver updated.'**
  String get driverUpdated;

  /// Button that saves driver edits
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get saveDriver;

  /// Section title for lifecycle events on trip details
  ///
  /// In en, this message translates to:
  /// **'Trip events'**
  String get tripEventsSection;

  /// Trip events label for goingStartedAt
  ///
  /// In en, this message translates to:
  /// **'Trip started'**
  String get tripEventTripStarted;

  /// Trip events label for goingEndedAt
  ///
  /// In en, this message translates to:
  /// **'Arrived at destination'**
  String get tripEventArrivedAtDestination;

  /// Trip events label for returnStartedAt
  ///
  /// In en, this message translates to:
  /// **'Started returning'**
  String get tripEventStartedReturning;

  /// Trip events label for finishedAt
  ///
  /// In en, this message translates to:
  /// **'Trip ended'**
  String get tripEventTripEnded;

  /// Shown when goingEndedAt is null
  ///
  /// In en, this message translates to:
  /// **'Not arrived yet'**
  String get tripNotArrivedYet;

  /// Shown when returnStartedAt is null
  ///
  /// In en, this message translates to:
  /// **'Not returning yet'**
  String get tripNotReturningYet;

  /// Who approved or rejected a request
  ///
  /// In en, this message translates to:
  /// **'Handled by: {name}'**
  String handledByValue(String name);

  /// When a request was approved or rejected
  ///
  /// In en, this message translates to:
  /// **'Handled at: {dateTime}'**
  String handledAtValue(String dateTime);

  /// Filter chip for pending requests
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get filterPending;

  /// Filter chip for approved requests
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get filterApproved;

  /// Filter chip for rejected requests
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get filterRejected;

  /// Title when the filtered requests list is empty
  ///
  /// In en, this message translates to:
  /// **'No requests'**
  String get requestsEmptyTitle;

  /// Supporting text when filtered requests are empty
  ///
  /// In en, this message translates to:
  /// **'No trip requests match this filter.'**
  String get requestsEmptyMessage;

  /// Label for the driver's English name
  ///
  /// In en, this message translates to:
  /// **'Name (English)'**
  String get driverNameEnLabel;

  /// Label for the driver's Arabic name
  ///
  /// In en, this message translates to:
  /// **'Name (Arabic)'**
  String get driverNameArLabel;

  /// Label for the Egyptian national ID field
  ///
  /// In en, this message translates to:
  /// **'National ID'**
  String get nationalIdLabel;

  /// Label for the Egyptian car plate fields
  ///
  /// In en, this message translates to:
  /// **'Car plate'**
  String get carLicenseLabel;

  /// Letters part of an Egyptian car plate
  ///
  /// In en, this message translates to:
  /// **'Letters'**
  String get carPlateLettersLabel;

  /// Numbers part of an Egyptian car plate
  ///
  /// In en, this message translates to:
  /// **'Numbers'**
  String get carPlateNumbersLabel;

  /// Label for the personal driving license text field
  ///
  /// In en, this message translates to:
  /// **'Personal license'**
  String get personalLicenseLabel;

  /// Title of the driver details screen
  ///
  /// In en, this message translates to:
  /// **'Driver details'**
  String get driverDetailsTitle;

  /// Masked national ID line on the drivers list
  ///
  /// In en, this message translates to:
  /// **'National ID: {masked}'**
  String nationalIdMaskedValue(String masked);

  /// Shown when a legacy driver has no private profile yet
  ///
  /// In en, this message translates to:
  /// **'National ID: not set'**
  String get nationalIdNotSet;

  /// Car plate line in the assignment picker
  ///
  /// In en, this message translates to:
  /// **'Car plate: {license}'**
  String carLicenseValue(String license);

  /// Shown in the picker when the car plate is missing
  ///
  /// In en, this message translates to:
  /// **'Car plate: not set'**
  String get carLicenseNotSet;

  /// Validation when driver English name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the English name.'**
  String get validationDriverNameEnRequired;

  /// Validation when driver Arabic name is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the Arabic name.'**
  String get validationDriverNameArRequired;

  /// Validation when phone format is invalid
  ///
  /// In en, this message translates to:
  /// **'Enter a valid phone number.'**
  String get validationPhoneInvalid;

  /// Validation when national ID is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the national ID.'**
  String get validationNationalIdRequired;

  /// Validation when national ID is not 14 digits
  ///
  /// In en, this message translates to:
  /// **'Enter a valid 14-digit Egyptian national ID.'**
  String get validationNationalIdInvalid;

  /// Validation when the car plate is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the car plate.'**
  String get validationCarLicenseRequired;

  /// Validation when the car plate is not an Egyptian letters-and-numbers plate
  ///
  /// In en, this message translates to:
  /// **'Enter 1–3 Arabic letters and 1–4 numbers, like ط ع ب 9295.'**
  String get validationCarPlateInvalid;

  /// Validation when personal license is empty
  ///
  /// In en, this message translates to:
  /// **'Enter the personal license.'**
  String get validationPersonalLicenseRequired;

  /// Section label for name/email/phone/branch on signup
  ///
  /// In en, this message translates to:
  /// **'Your details'**
  String get registerSectionDetails;

  /// Section label for password fields on signup
  ///
  /// In en, this message translates to:
  /// **'Security'**
  String get registerSectionSecurity;

  /// Role chip label for employees
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get roleLabelEmployee;

  /// Role chip label for drivers
  ///
  /// In en, this message translates to:
  /// **'Driver'**
  String get roleLabelDriver;

  /// Role chip label for company admins
  ///
  /// In en, this message translates to:
  /// **'Company admin'**
  String get roleLabelCompanyAdmin;

  /// Role chip label for drivers admins
  ///
  /// In en, this message translates to:
  /// **'Drivers admin'**
  String get roleLabelDriversAdmin;

  /// Trip bootstrap checklist step
  ///
  /// In en, this message translates to:
  /// **'Getting your location'**
  String get bootstrapGettingLocation;

  /// Trip bootstrap checklist step
  ///
  /// In en, this message translates to:
  /// **'Loading trip locations'**
  String get bootstrapLoadingLocations;

  /// Trip bootstrap checklist step
  ///
  /// In en, this message translates to:
  /// **'Preparing route'**
  String get bootstrapPreparingRoute;

  /// Trip bootstrap checklist step
  ///
  /// In en, this message translates to:
  /// **'Sharing location with dispatch'**
  String get bootstrapSharingLocation;

  /// Banner when no GPS fix is available yet
  ///
  /// In en, this message translates to:
  /// **'Waiting for GPS signal'**
  String get waitingForGpsSignal;

  /// Chip when location permission is denied
  ///
  /// In en, this message translates to:
  /// **'Location off, tap to fix'**
  String get locationOffTapToFix;

  /// Chip when OSRM failed and a straight line is shown
  ///
  /// In en, this message translates to:
  /// **'Route unavailable, showing direct line'**
  String get approximateRoute;

  /// Chip when a place was forward-geocoded
  ///
  /// In en, this message translates to:
  /// **'Approximate location'**
  String get approximateLocation;

  /// Note when a place has no coordinates
  ///
  /// In en, this message translates to:
  /// **'Location not set for {name}'**
  String locationNotSetFor(String name);

  /// Card title when within arrival radius
  ///
  /// In en, this message translates to:
  /// **'You have arrived'**
  String get youHaveArrived;

  /// Button to switch to the return leg
  ///
  /// In en, this message translates to:
  /// **'Arrived / Start return'**
  String get arrivedStartReturn;

  /// Opens external maps for turn-by-turn
  ///
  /// In en, this message translates to:
  /// **'Navigate'**
  String get navigateButton;

  /// Progress percentage on the live map card
  ///
  /// In en, this message translates to:
  /// **'{percent}% complete'**
  String tripProgressPercent(int percent);

  /// Covered and remaining distance on the live map
  ///
  /// In en, this message translates to:
  /// **'{covered} km covered · {remaining} km remaining'**
  String distanceCoveredRemaining(String covered, String remaining);

  /// Approximate ETA label
  ///
  /// In en, this message translates to:
  /// **'ETA ~{minutes} min (approximate)'**
  String etaApproximateMinutes(int minutes);

  /// Debug sheet title on the live map
  ///
  /// In en, this message translates to:
  /// **'Dev tools'**
  String get devToolsTitle;

  /// Toggle GPS simulation along the route
  ///
  /// In en, this message translates to:
  /// **'Simulate movement'**
  String get devSimulateMovement;

  /// Simulation speed label
  ///
  /// In en, this message translates to:
  /// **'Speed: {speed} km/h'**
  String devSimulateSpeed(int speed);

  /// Pause simulated movement
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get devPauseSimulation;

  /// Resume simulated movement
  ///
  /// In en, this message translates to:
  /// **'Resume'**
  String get devResumeSimulation;

  /// Jump simulator near the destination
  ///
  /// In en, this message translates to:
  /// **'Jump to 90%'**
  String get devJumpToNinety;

  /// Read-only progress line in admin driver sheet
  ///
  /// In en, this message translates to:
  /// **'{percent}% · {remaining} km remaining'**
  String adminTripProgress(int percent, String remaining);

  /// Notice when OSRM fails and a dashed straight line is drawn
  ///
  /// In en, this message translates to:
  /// **'Route unavailable, showing direct line'**
  String get routeUnavailableShowingDirectLine;

  /// Manual button to re-fetch the OSRM planned route
  ///
  /// In en, this message translates to:
  /// **'Recalculate route'**
  String get recalculateRoute;

  /// Generic retry button on the live map
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retryAction;

  /// Loading state while acquiring the trip start GPS fix
  ///
  /// In en, this message translates to:
  /// **'Getting your location…'**
  String get locatingDriverPosition;

  /// Shown after the ~15s position timeout on live map open
  ///
  /// In en, this message translates to:
  /// **'Could not get your location. Check GPS and try again.'**
  String get locationFixTimedOut;

  /// Top phase chip when the driver is at the destination
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get liveMapPhaseArrived;

  /// Estimated route distance in the bottom card
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String estimatedDistanceKm(String km);

  /// Estimated ETA from the planned route
  ///
  /// In en, this message translates to:
  /// **'ETA {minutes} min'**
  String estimatedEtaMinutes(int minutes);

  /// Section title for the trip report card
  ///
  /// In en, this message translates to:
  /// **'Trip report'**
  String get tripReportTitle;

  /// Chip shown while a trip report is still collecting data
  ///
  /// In en, this message translates to:
  /// **'Report in progress'**
  String get tripReportInProgress;

  /// Label for goingStartedAt on the trip report
  ///
  /// In en, this message translates to:
  /// **'Started at'**
  String get tripReportStartedAt;

  /// Label for finishedAt on the trip report
  ///
  /// In en, this message translates to:
  /// **'Finished at'**
  String get tripReportFinishedAt;

  /// Label for total trip duration
  ///
  /// In en, this message translates to:
  /// **'Total duration'**
  String get tripReportTotalDuration;

  /// Label for outbound leg duration
  ///
  /// In en, this message translates to:
  /// **'Going duration'**
  String get tripReportGoingDuration;

  /// Label for wait time between going end and return start
  ///
  /// In en, this message translates to:
  /// **'Waiting at destination'**
  String get tripReportWaitingDuration;

  /// Label for return leg duration
  ///
  /// In en, this message translates to:
  /// **'Return duration'**
  String get tripReportReturnDuration;

  /// Label for outbound distance
  ///
  /// In en, this message translates to:
  /// **'Distance going'**
  String get tripReportDistanceGoing;

  /// Label for return distance
  ///
  /// In en, this message translates to:
  /// **'Distance back'**
  String get tripReportDistanceReturn;

  /// Label for total distance
  ///
  /// In en, this message translates to:
  /// **'Total distance'**
  String get tripReportDistanceTotal;

  /// Formatted distance in kilometers
  ///
  /// In en, this message translates to:
  /// **'{km} km'**
  String tripReportDistanceKmValue(String km);

  /// Duration with hours
  ///
  /// In en, this message translates to:
  /// **'{hours}h {minutes}m {seconds}s'**
  String tripReportDurationHoursMinutesSeconds(
    int hours,
    int minutes,
    int seconds,
  );

  /// Duration with minutes only
  ///
  /// In en, this message translates to:
  /// **'{minutes}m {seconds}s'**
  String tripReportDurationMinutesSeconds(int minutes, int seconds);

  /// Duration under one minute
  ///
  /// In en, this message translates to:
  /// **'{seconds}s'**
  String tripReportDurationSeconds(int seconds);

  /// Heading above the trip report map
  ///
  /// In en, this message translates to:
  /// **'Route'**
  String get tripReportRouteSection;

  /// Map legend for the going polyline
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get tripReportGoingRouteLegend;

  /// Map legend for the return polyline
  ///
  /// In en, this message translates to:
  /// **'Returning'**
  String get tripReportReturnRouteLegend;

  /// Button or action to open driver trip details
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get viewTripDetails;

  /// Trip assignment empty state when nobody is officially available
  ///
  /// In en, this message translates to:
  /// **'No available drivers'**
  String get noAvailableDriversTitle;

  /// Trip assignment empty state message
  ///
  /// In en, this message translates to:
  /// **'Approve an availability request first, or wait for a driver to become free.'**
  String get noAvailableDriversMessage;

  /// Relative time: less than a minute ago
  ///
  /// In en, this message translates to:
  /// **'Just now'**
  String get relativeTimeJustNow;

  /// Relative time in minutes
  ///
  /// In en, this message translates to:
  /// **'{minutes} min ago'**
  String relativeTimeMinutesAgo(int minutes);

  /// Relative time in hours
  ///
  /// In en, this message translates to:
  /// **'{hours} hr ago'**
  String relativeTimeHoursAgo(int hours);

  /// Relative time in days
  ///
  /// In en, this message translates to:
  /// **'{days} d ago'**
  String relativeTimeDaysAgo(int days);

  /// Label for Drivers Admin multi-select of a driver's favorite places
  ///
  /// In en, this message translates to:
  /// **'Favorite places'**
  String get favoritePlacesLabel;

  /// Search hint when adding favorite places on the driver form
  ///
  /// In en, this message translates to:
  /// **'Search places to add'**
  String get favoritePlacesSearchHint;

  /// Semantics label for removing a favorite place chip
  ///
  /// In en, this message translates to:
  /// **'Remove favorite place'**
  String get favoritePlaceRemove;

  /// Section header for recommended drivers in the assign picker
  ///
  /// In en, this message translates to:
  /// **'Recommended'**
  String get recommendedDriversSection;

  /// Section header for non-recommended drivers in the assign picker
  ///
  /// In en, this message translates to:
  /// **'Other drivers'**
  String get otherDriversSection;

  /// Chip when the trip matches a driver's favorite place
  ///
  /// In en, this message translates to:
  /// **'Favorite place'**
  String get driverReasonFavoritePlace;

  /// Chip when the driver is officially available
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get driverReasonAvailable;

  /// Warning chip when the driver is not officially available
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get driverReasonUnavailable;

  /// Warning chip when the driver has an in-progress trip
  ///
  /// In en, this message translates to:
  /// **'On active trip'**
  String get driverReasonOnActiveTrip;

  /// Warning chip when the driver has a nearby scheduled trip
  ///
  /// In en, this message translates to:
  /// **'Schedule conflict'**
  String get driverReasonScheduleConflict;

  /// Title of the confirm dialog when assigning a non-ideal driver
  ///
  /// In en, this message translates to:
  /// **'Assign this driver?'**
  String get assignDriverWarningTitle;

  /// Body of the confirm dialog when assigning a non-ideal driver
  ///
  /// In en, this message translates to:
  /// **'This driver is not fully available for this trip. You can still assign them.'**
  String get assignDriverWarningMessage;

  /// Confirm action that continues despite availability warnings
  ///
  /// In en, this message translates to:
  /// **'Assign anyway'**
  String get assignDriverWarningContinue;

  /// Shown when a driver has no favorite places on details
  ///
  /// In en, this message translates to:
  /// **'None'**
  String get driverFavoritePlacesEmpty;

  /// Company admin home tab for the signed-in admin's own trip requests
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get myRequestsTab;

  /// Filter chip: show all of my trip requests
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get myRequestsFilterAll;

  /// Filter chip: show active (in-progress) own trip requests
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get myRequestsFilterActive;

  /// Filter chip: show completed own trip requests
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get myRequestsFilterCompleted;

  /// Filter chip: show cancelled or rejected own trip requests
  ///
  /// In en, this message translates to:
  /// **'Cancelled / Rejected'**
  String get myRequestsFilterCancelledRejected;

  /// Title when the company admin has no own trip requests
  ///
  /// In en, this message translates to:
  /// **'No requests yet'**
  String get myRequestsEmptyTitle;

  /// Supporting text when My Requests list is empty
  ///
  /// In en, this message translates to:
  /// **'Trip requests you create for yourself will appear here.'**
  String get myRequestsEmptyMessage;

  /// Supporting text when a My Requests filter has no matches
  ///
  /// In en, this message translates to:
  /// **'No requests match this filter.'**
  String get myRequestsFilteredEmptyMessage;

  /// Title of the own-request progress details screen
  ///
  /// In en, this message translates to:
  /// **'Request progress'**
  String get myRequestProgressTitle;

  /// Progress step: request submitted
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get requestProgressStepRequested;

  /// Progress step: request approved
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get requestProgressStepApproved;

  /// Progress step: a driver was assigned to the trip
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get requestProgressStepDriverAssigned;

  /// Progress step: trip going to destination
  ///
  /// In en, this message translates to:
  /// **'Going'**
  String get requestProgressStepGoing;

  /// Progress step: arrived at destination
  ///
  /// In en, this message translates to:
  /// **'Arrived'**
  String get requestProgressStepArrived;

  /// Progress step: returning from destination
  ///
  /// In en, this message translates to:
  /// **'Returning'**
  String get requestProgressStepReturning;

  /// Progress step: trip completed
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get requestProgressStepCompleted;

  /// Compact progress bar label showing the current step
  ///
  /// In en, this message translates to:
  /// **'Current: {step}'**
  String requestProgressCurrentStep(String step);

  /// Compact progress bar label when the request failed
  ///
  /// In en, this message translates to:
  /// **'Failed: {step}'**
  String requestProgressFailedStep(String step);

  /// Section title for assigned driver on own-request details
  ///
  /// In en, this message translates to:
  /// **'Assigned driver'**
  String get assignedDriverSection;

  /// Assigned driver phone line
  ///
  /// In en, this message translates to:
  /// **'Phone: {phone}'**
  String assignedDriverPhoneValue(String phone);

  /// Shown when the linked trip has no driver yet
  ///
  /// In en, this message translates to:
  /// **'No driver assigned yet.'**
  String get assignedDriverPending;

  /// Role chip label for system administrators
  ///
  /// In en, this message translates to:
  /// **'System admin'**
  String get roleLabelAdmin;

  /// Title of the system admin home screen
  ///
  /// In en, this message translates to:
  /// **'Admin dashboard'**
  String get adminDashboardTitle;

  /// Subtitle on the system admin dashboard
  ///
  /// In en, this message translates to:
  /// **'Manage drivers, places, and employees. Request trips for yourself.'**
  String get adminDashboardSubtitle;

  /// Dashboard card for drivers management
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get adminDriversSection;

  /// Hint under drivers card
  ///
  /// In en, this message translates to:
  /// **'Add, edit, or deactivate drivers'**
  String get adminDriversSectionHint;

  /// Dashboard card for places management
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get adminPlacesSection;

  /// Hint under places card
  ///
  /// In en, this message translates to:
  /// **'Manage locations and map pins'**
  String get adminPlacesSectionHint;

  /// Dashboard card for employees management
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get adminEmployeesSection;

  /// Hint under employees card
  ///
  /// In en, this message translates to:
  /// **'Add, edit, or deactivate employees'**
  String get adminEmployeesSectionHint;

  /// Dashboard card for resetting any account password
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get adminUsersSection;

  /// Hint under the users card
  ///
  /// In en, this message translates to:
  /// **'Set a temporary password for any account'**
  String get adminUsersSectionHint;

  /// Search field on the users screen
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, or phone'**
  String get adminUsersSearchHint;

  /// Role filter that shows every account
  ///
  /// In en, this message translates to:
  /// **'All roles'**
  String get adminFilterAllRoles;

  /// Empty state title on the users screen
  ///
  /// In en, this message translates to:
  /// **'No users'**
  String get adminUsersEmptyTitle;

  /// Empty state message on the users screen
  ///
  /// In en, this message translates to:
  /// **'No accounts match this search.'**
  String get adminUsersEmptyMessage;

  /// Button that sets a temporary password
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get adminResetPasswordAction;

  /// Title of the temporary-password dialog
  ///
  /// In en, this message translates to:
  /// **'Reset password'**
  String get adminResetPasswordTitle;

  /// Explains that the temporary password is replaced on the next sign-in
  ///
  /// In en, this message translates to:
  /// **'{name} must change this password the next time they sign in.'**
  String adminResetPasswordMessage(String name);

  /// Note under the temporary password fields
  ///
  /// In en, this message translates to:
  /// **'Share this password with the user. They must change it when they sign in.'**
  String get adminResetPasswordNote;

  /// Snack bar after a password reset
  ///
  /// In en, this message translates to:
  /// **'Temporary password saved.'**
  String get adminResetPasswordSuccess;

  /// Shown when the account must still change the temporary password
  ///
  /// In en, this message translates to:
  /// **'Temporary password'**
  String get adminTemporaryPasswordBadge;

  /// Dashboard card for admin own trip requests
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get adminMyTripsSection;

  /// Hint under my trips card
  ///
  /// In en, this message translates to:
  /// **'Follow progress of your requests'**
  String get adminMyTripsSectionHint;

  /// Dashboard card to open the trip request form
  ///
  /// In en, this message translates to:
  /// **'Request trip'**
  String get adminRequestTripSection;

  /// Hint under request trip card
  ///
  /// In en, this message translates to:
  /// **'Auto-accepted and sent for driver assignment'**
  String get adminRequestTripSectionHint;

  /// Search field hint on admin list screens
  ///
  /// In en, this message translates to:
  /// **'Search by name, email, or phone'**
  String get adminSearchHint;

  /// Active-status filter: all
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get adminFilterAll;

  /// Active-status filter: active only
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get adminFilterActive;

  /// Active-status filter: inactive only
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get adminFilterInactive;

  /// Branch filter chip for all branches
  ///
  /// In en, this message translates to:
  /// **'All branches'**
  String get adminFilterAllBranches;

  /// Empty state title for admin drivers list
  ///
  /// In en, this message translates to:
  /// **'No drivers found'**
  String get adminDriversEmptyTitle;

  /// Empty state message for admin drivers list
  ///
  /// In en, this message translates to:
  /// **'Add a driver or clear filters to see results.'**
  String get adminDriversEmptyMessage;

  /// Empty state title for admin employees list
  ///
  /// In en, this message translates to:
  /// **'No employees found'**
  String get adminEmployeesEmptyTitle;

  /// Empty state message for admin employees list
  ///
  /// In en, this message translates to:
  /// **'Add an employee or clear filters to see results.'**
  String get adminEmployeesEmptyMessage;

  /// Dialog title for creating an employee
  ///
  /// In en, this message translates to:
  /// **'Add employee'**
  String get adminAddEmployeeTitle;

  /// Dialog title for editing an employee
  ///
  /// In en, this message translates to:
  /// **'Edit employee'**
  String get adminEditEmployeeTitle;

  /// Primary action to create an employee
  ///
  /// In en, this message translates to:
  /// **'Add employee'**
  String get adminAddEmployee;

  /// Primary action to save employee edits
  ///
  /// In en, this message translates to:
  /// **'Save employee'**
  String get adminSaveEmployee;

  /// SnackBar after creating an employee
  ///
  /// In en, this message translates to:
  /// **'Employee created'**
  String get adminEmployeeCreated;

  /// SnackBar after updating an employee
  ///
  /// In en, this message translates to:
  /// **'Employee updated'**
  String get adminEmployeeUpdated;

  /// Confirmation dialog title for soft delete
  ///
  /// In en, this message translates to:
  /// **'Deactivate account?'**
  String get adminSoftDeleteConfirmTitle;

  /// Confirmation message when soft-deleting a driver
  ///
  /// In en, this message translates to:
  /// **'{name} will be deactivated and cannot sign in. Auth account is kept.'**
  String adminSoftDeleteDriverMessage(String name);

  /// Confirmation message when soft-deleting an employee
  ///
  /// In en, this message translates to:
  /// **'{name} will be deactivated and cannot sign in. Auth account is kept.'**
  String adminSoftDeleteEmployeeMessage(String name);

  /// Confirm soft-delete button
  ///
  /// In en, this message translates to:
  /// **'Deactivate'**
  String get adminSoftDeleteAction;

  /// SnackBar after soft delete
  ///
  /// In en, this message translates to:
  /// **'Account deactivated'**
  String get adminSoftDeleteSuccess;

  /// Menu action to reactivate a soft-deleted user
  ///
  /// In en, this message translates to:
  /// **'Reactivate'**
  String get adminReactivateAction;

  /// Debug dialog title for seeding an admin profile
  ///
  /// In en, this message translates to:
  /// **'Seed admin profile (debug)'**
  String get adminSeedDebugTitle;

  /// Debug dialog explanation for admin seed
  ///
  /// In en, this message translates to:
  /// **'Writes an admin profile for a user id that already exists.'**
  String get adminSeedDebugMessage;

  /// Label for UID field in admin seed dialog
  ///
  /// In en, this message translates to:
  /// **'Auth UID'**
  String get adminSeedUidLabel;

  /// Confirm button for admin seed dialog
  ///
  /// In en, this message translates to:
  /// **'Write profile'**
  String get adminSeedDebugAction;

  /// SnackBar after debug admin seed succeeds
  ///
  /// In en, this message translates to:
  /// **'Admin profile written'**
  String get adminSeedDebugSuccess;

  /// Bottom bar: my trips
  ///
  /// In en, this message translates to:
  /// **'My trips'**
  String get navMyTrips;

  /// Bottom bar: trips
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get navTrips;

  /// Bottom bar: requests
  ///
  /// In en, this message translates to:
  /// **'Requests'**
  String get navRequests;

  /// Bottom bar: places
  ///
  /// In en, this message translates to:
  /// **'Places'**
  String get navPlaces;

  /// Bottom bar: my requests
  ///
  /// In en, this message translates to:
  /// **'My requests'**
  String get navMyRequests;

  /// Bottom bar: drivers
  ///
  /// In en, this message translates to:
  /// **'Drivers'**
  String get navDrivers;

  /// Bottom bar: live map
  ///
  /// In en, this message translates to:
  /// **'Live map'**
  String get navLiveMap;

  /// Bottom bar: dashboard
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get navDashboard;

  /// Bottom bar: employees
  ///
  /// In en, this message translates to:
  /// **'Employees'**
  String get navEmployees;

  /// More menu: reset any account password
  ///
  /// In en, this message translates to:
  /// **'Users'**
  String get navUsers;

  /// Bottom bar: company admin requested trips
  ///
  /// In en, this message translates to:
  /// **'Requested trips'**
  String get navRequestedTrips;

  /// Bottom bar: driver assigned trips
  ///
  /// In en, this message translates to:
  /// **'Assigned trips'**
  String get navAssignedTrips;

  /// Bottom bar: driver completed trips
  ///
  /// In en, this message translates to:
  /// **'Completed trips'**
  String get navCompletedTrips;

  /// Bottom bar: driver stats
  ///
  /// In en, this message translates to:
  /// **'Stats'**
  String get navStats;

  /// Placeholder body for a screen that is not built yet
  ///
  /// In en, this message translates to:
  /// **'Coming soon'**
  String get comingSoon;

  /// Forced password change screen title
  ///
  /// In en, this message translates to:
  /// **'Change your password'**
  String get forcedChangePasswordTitle;

  /// Explains why the rest of the app is blocked
  ///
  /// In en, this message translates to:
  /// **'You must change your password before continuing.'**
  String get forcedChangePasswordMessage;

  /// Bottom bar: profile
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get navProfile;

  /// Bottom bar: settings
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get navSettings;

  /// Bottom bar overflow menu
  ///
  /// In en, this message translates to:
  /// **'More'**
  String get navMore;

  /// Profile screen title
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profileTitle;

  /// SnackBar after profile update
  ///
  /// In en, this message translates to:
  /// **'Profile saved'**
  String get profileSaved;

  /// Profile save button
  ///
  /// In en, this message translates to:
  /// **'Save profile'**
  String get profileSave;

  /// Read-only role field
  ///
  /// In en, this message translates to:
  /// **'Role'**
  String get roleFieldLabel;

  /// Settings screen title
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settingsTitle;

  /// Language section heading
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// Change-password section heading
  ///
  /// In en, this message translates to:
  /// **'Change password'**
  String get changePasswordTitle;

  /// Current password field
  ///
  /// In en, this message translates to:
  /// **'Current password'**
  String get currentPasswordLabel;

  /// New password field
  ///
  /// In en, this message translates to:
  /// **'New password'**
  String get newPasswordLabel;

  /// Change-password submit button
  ///
  /// In en, this message translates to:
  /// **'Update password'**
  String get changePasswordAction;

  /// SnackBar after password change
  ///
  /// In en, this message translates to:
  /// **'Password updated'**
  String get changePasswordSuccess;

  /// Shown when change-password returns 429
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Try again in a minute.'**
  String get changePasswordRateLimited;

  /// Logout confirmation title
  ///
  /// In en, this message translates to:
  /// **'Sign out?'**
  String get logoutConfirmTitle;

  /// Logout confirmation body
  ///
  /// In en, this message translates to:
  /// **'You will need to sign in again to continue.'**
  String get logoutConfirmMessage;

  /// Extra warning when a driver signs out during an active trip
  ///
  /// In en, this message translates to:
  /// **'You have a trip in progress. Signing out stops live tracking.'**
  String get logoutActiveTripWarning;

  /// Confirm logout button
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get logoutConfirmAction;

  /// Scheduled departure on the live-map driver sheet
  ///
  /// In en, this message translates to:
  /// **'Scheduled {time}'**
  String liveMapScheduledAt(String time);

  /// My Trips tab for every request
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get myTripsTabAll;

  /// My Trips tab for active requests
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get myTripsTabActive;

  /// My Trips tab for completed requests
  ///
  /// In en, this message translates to:
  /// **'Completed'**
  String get myTripsTabCompleted;

  /// My Trips tab for cancelled requests
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get myTripsTabCancelled;

  /// Banner when completed trips still need a report
  ///
  /// In en, this message translates to:
  /// **'{count, plural, =1{1 trip needs your report} other{{count} trips need your report}}'**
  String myTripsNeedReport(int count);

  /// Empty title on a My Trips tab
  ///
  /// In en, this message translates to:
  /// **'No trips here'**
  String get myTripsEmptyTitle;

  /// Empty message on a My Trips tab
  ///
  /// In en, this message translates to:
  /// **'Trip requests in this tab will show up here.'**
  String get myTripsEmptyMessage;

  /// Assigned driver on a trip request card
  ///
  /// In en, this message translates to:
  /// **'Driver: {name}'**
  String myTripsDriverName(String name);

  /// Trip request details screen title
  ///
  /// In en, this message translates to:
  /// **'Trip details'**
  String get tripRequestDetailsTitle;

  /// Pickup field label
  ///
  /// In en, this message translates to:
  /// **'Pickup'**
  String get detailPickup;

  /// Destination field label
  ///
  /// In en, this message translates to:
  /// **'Destination'**
  String get detailDestination;

  /// Address field label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get detailAddress;

  /// Requested time field label
  ///
  /// In en, this message translates to:
  /// **'Requested'**
  String get detailRequestedAt;

  /// Notes field label on trip details
  ///
  /// In en, this message translates to:
  /// **'Notes'**
  String get detailNotes;

  /// Phone field label
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get detailPhone;

  /// Branch field label
  ///
  /// In en, this message translates to:
  /// **'Branch'**
  String get detailBranch;

  /// Employee field label
  ///
  /// In en, this message translates to:
  /// **'Employee'**
  String get detailEmployee;

  /// Rejection reason field label
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get detailRejectionReason;

  /// When the request was handled
  ///
  /// In en, this message translates to:
  /// **'Handled'**
  String get detailHandledAt;

  /// Shown when a request has no notes
  ///
  /// In en, this message translates to:
  /// **'No notes'**
  String get detailNoNotes;

  /// Heading for the linked trip block
  ///
  /// In en, this message translates to:
  /// **'Assigned trip'**
  String get tripBlockTitle;

  /// Shown when the linked trip has no driver
  ///
  /// In en, this message translates to:
  /// **'No driver assigned yet'**
  String get tripBlockNoDriver;

  /// Read-only label when a report auto-closed
  ///
  /// In en, this message translates to:
  /// **'Not confirmed (auto-closed after 24h)'**
  String get confirmationUnconfirmed;

  /// Label after the employee confirms a trip
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get confirmationConfirmed;

  /// Label when a report is still pending
  ///
  /// In en, this message translates to:
  /// **'Waiting for your report'**
  String get confirmationPending;

  /// Confirmed that the driver showed up
  ///
  /// In en, this message translates to:
  /// **'Driver showed up'**
  String get driverShowedUpYes;

  /// Confirmed that the driver did not show up
  ///
  /// In en, this message translates to:
  /// **'Driver did not show up'**
  String get driverShowedUpNo;

  /// Required question on the trip report
  ///
  /// In en, this message translates to:
  /// **'Did the driver show up?'**
  String get confirmTripQuestion;

  /// Report choice: the driver showed up
  ///
  /// In en, this message translates to:
  /// **'Driver showed up'**
  String get confirmTripYes;

  /// Report choice: the driver did not show up
  ///
  /// In en, this message translates to:
  /// **'Did not show up'**
  String get confirmTripNo;

  /// Hint for the optional trip report note
  ///
  /// In en, this message translates to:
  /// **'Optional'**
  String get confirmTripNoteHint;

  /// Submit the trip report
  ///
  /// In en, this message translates to:
  /// **'Submit report'**
  String get confirmTripSubmit;

  /// SnackBar after a trip report is saved
  ///
  /// In en, this message translates to:
  /// **'Trip report submitted.'**
  String get confirmTripSuccess;

  /// Shown when confirm-trip returns 409
  ///
  /// In en, this message translates to:
  /// **'This trip was already confirmed or closed'**
  String get confirmTripAlreadyClosed;

  /// Validation when the show-up answer is missing
  ///
  /// In en, this message translates to:
  /// **'Choose whether the driver showed up.'**
  String get confirmTripChooseAnswer;

  /// Validation when the trip report note is too long
  ///
  /// In en, this message translates to:
  /// **'Note must be 500 characters or fewer.'**
  String get confirmTripNoteTooLong;

  /// Week period
  ///
  /// In en, this message translates to:
  /// **'Week'**
  String get periodWeek;

  /// Month period
  ///
  /// In en, this message translates to:
  /// **'Month'**
  String get periodMonth;

  /// Year period
  ///
  /// In en, this message translates to:
  /// **'Year'**
  String get periodYear;

  /// All-time period
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get periodAll;

  /// Range label when the period is all time
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get periodAllTime;

  /// Previous period button
  ///
  /// In en, this message translates to:
  /// **'Previous period'**
  String get periodPrevious;

  /// Next period button
  ///
  /// In en, this message translates to:
  /// **'Next period'**
  String get periodNext;

  /// Empty assigned trips for the selected period
  ///
  /// In en, this message translates to:
  /// **'No assigned trips in this period.'**
  String get assignedTripsEmptyMessage;

  /// Empty completed trips for the selected period
  ///
  /// In en, this message translates to:
  /// **'No completed trips in this period.'**
  String get completedTripsEmptyMessage;

  /// Trip distance in kilometres
  ///
  /// In en, this message translates to:
  /// **'Distance {distance} km'**
  String tripDistanceValue(String distance);

  /// Trip duration as h:mm
  ///
  /// In en, this message translates to:
  /// **'Duration {duration}'**
  String tripDurationValue(String duration);

  /// Stats tile for trip count
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get statsTrips;

  /// Stats tile for driving time
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get statsTime;

  /// Stats tile for distance
  ///
  /// In en, this message translates to:
  /// **'Distance'**
  String get statsDistance;

  /// Distance value on the stats tile
  ///
  /// In en, this message translates to:
  /// **'{distance} km'**
  String statsKmValue(String distance);

  /// Empty stats chart
  ///
  /// In en, this message translates to:
  /// **'No trips in this period.'**
  String get statsChartEmpty;

  /// My Trips tab for cancelled and rejected requests
  ///
  /// In en, this message translates to:
  /// **'Cancelled/Rejected'**
  String get myTripsTabCancelledRejected;

  /// Trip status shown on a request card
  ///
  /// In en, this message translates to:
  /// **'Trip status: {status}'**
  String tripStatusLine(String status);

  /// Passenger confirmation status on a trip
  ///
  /// In en, this message translates to:
  /// **'Confirmation: {status}'**
  String confirmationStatusValue(String status);

  /// Badge when driver_showed_up is false
  ///
  /// In en, this message translates to:
  /// **'Driver did not show'**
  String get driverDidNotShow;

  /// Drivers admin trips tab for awaiting_report
  ///
  /// In en, this message translates to:
  /// **'Awaiting report'**
  String get tripsAwaitingReportTab;

  /// Last location time on an in-progress trip
  ///
  /// In en, this message translates to:
  /// **'Last seen {time}'**
  String liveProgressLastSeen(String time);

  /// Live map driver state on_trip
  ///
  /// In en, this message translates to:
  /// **'On a trip'**
  String get liveMapStateOnTrip;

  /// Live map driver state available
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get liveMapStateAvailable;

  /// Live map driver state unavailable
  ///
  /// In en, this message translates to:
  /// **'Unavailable'**
  String get liveMapStateUnavailable;

  /// Heading for drivers without coordinates
  ///
  /// In en, this message translates to:
  /// **'No location yet'**
  String get liveMapNoLocationTitle;

  /// Note under the temporary password field
  ///
  /// In en, this message translates to:
  /// **'The driver must change this password on first login.'**
  String get driverMustChangePasswordNote;

  /// Favorite places picker limit
  ///
  /// In en, this message translates to:
  /// **'Choose up to 5 favorite places.'**
  String get favoritePlacesLimit;

  /// Recommendation rank
  ///
  /// In en, this message translates to:
  /// **'Tier {tier}'**
  String recommendationTier(int tier);

  /// How many trips the driver has this week
  ///
  /// In en, this message translates to:
  /// **'{count} trips this week'**
  String recommendationTripsThisWeek(int count);

  /// Shown when deleting the headquarters place returns 422
  ///
  /// In en, this message translates to:
  /// **'The headquarters place cannot be deleted.'**
  String get cannotDeleteHeadquartersPlace;

  /// Loads the next page of a list
  ///
  /// In en, this message translates to:
  /// **'Load more'**
  String get loadMore;

  /// Empty created-by-me trips list
  ///
  /// In en, this message translates to:
  /// **'No trips in this tab'**
  String get createdByMeEmptyTitle;

  /// Empty created-by-me trips message
  ///
  /// In en, this message translates to:
  /// **'Trips you create will show up here.'**
  String get createdByMeEmptyMessage;

  /// Empty awaiting-report trips tab
  ///
  /// In en, this message translates to:
  /// **'No trips are waiting for a passenger report.'**
  String get adminTripsAwaitingReportEmptyMessage;

  /// Empty live map after a filter
  ///
  /// In en, this message translates to:
  /// **'No drivers match this filter.'**
  String get liveMapNoDrivers;

  /// Socket is connected
  ///
  /// In en, this message translates to:
  /// **'Live'**
  String get realtimeConnected;

  /// Socket is connecting
  ///
  /// In en, this message translates to:
  /// **'Connecting'**
  String get realtimeConnecting;

  /// Socket is disconnected
  ///
  /// In en, this message translates to:
  /// **'Offline'**
  String get realtimeDisconnected;

  /// Answer when a request is not approved yet
  ///
  /// In en, this message translates to:
  /// **'Pending approval'**
  String get trackingPendingApproval;

  /// Timeline question: was the request approved
  ///
  /// In en, this message translates to:
  /// **'Approved?'**
  String get trackingApprovedQuestion;

  /// Approved answer with the decision time
  ///
  /// In en, this message translates to:
  /// **'Approved {time}'**
  String trackingApprovedAt(String time);

  /// Answer when a tracking step has not happened
  ///
  /// In en, this message translates to:
  /// **'Not yet'**
  String get trackingNotYet;

  /// Timeline question: was a driver assigned
  ///
  /// In en, this message translates to:
  /// **'Driver assigned?'**
  String get trackingDriverQuestion;

  /// Assigned driver name and phone
  ///
  /// In en, this message translates to:
  /// **'{name} · {phone}'**
  String trackingDriverLine(String name, String phone);

  /// Timeline question for the current stage
  ///
  /// In en, this message translates to:
  /// **'Where is it now?'**
  String get trackingNowQuestion;

  /// Tracking timeline: request submitted
  ///
  /// In en, this message translates to:
  /// **'Submitted'**
  String get trackingStageSubmitted;

  /// Tracking timeline: request approved
  ///
  /// In en, this message translates to:
  /// **'Approved'**
  String get trackingStageApproved;

  /// Tracking timeline: request rejected
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get trackingStageRejected;

  /// Tracking timeline: driver assigned
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get trackingStageDriverAssigned;

  /// Tracking timeline: trip started
  ///
  /// In en, this message translates to:
  /// **'In progress'**
  String get trackingStageInProgress;

  /// Tracking timeline: driver ended the trip
  ///
  /// In en, this message translates to:
  /// **'Trip finished'**
  String get trackingStageFinished;

  /// Tracking timeline: waiting for the requester report
  ///
  /// In en, this message translates to:
  /// **'Awaiting confirmation'**
  String get trackingStageAwaitingConfirmation;

  /// Tracking timeline: requester confirmed the trip
  ///
  /// In en, this message translates to:
  /// **'Confirmed'**
  String get trackingStageConfirmed;

  /// Tracking timeline: confirmation window closed
  ///
  /// In en, this message translates to:
  /// **'Unconfirmed'**
  String get trackingStageUnconfirmed;

  /// Tracking timeline: request or trip cancelled
  ///
  /// In en, this message translates to:
  /// **'Cancelled'**
  String get trackingStageCancelled;

  /// My Trips chip after a driver is assigned
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get trackingChipDriverAssigned;

  /// Heading above a rejection reason
  ///
  /// In en, this message translates to:
  /// **'Rejection reason'**
  String get trackingRejectionTitle;

  /// Scheduled time on the tracking timeline
  ///
  /// In en, this message translates to:
  /// **'Scheduled {time}'**
  String trackingScheduled(String time);

  /// Assigned car plate on the tracking timeline
  ///
  /// In en, this message translates to:
  /// **'Car plate {license}'**
  String trackingVehicle(String license);

  /// Shown when an assigned driver has no phone
  ///
  /// In en, this message translates to:
  /// **'No phone'**
  String get trackingNoPhone;

  /// Confirms the date and time chosen for a trip
  ///
  /// In en, this message translates to:
  /// **'Use this time'**
  String get useThisTime;

  /// Notifications screen title and bell tooltip
  ///
  /// In en, this message translates to:
  /// **'Notifications'**
  String get notificationsTitle;

  /// Empty notifications list
  ///
  /// In en, this message translates to:
  /// **'No notifications yet.'**
  String get notificationsEmpty;

  /// Marks every notification read
  ///
  /// In en, this message translates to:
  /// **'Mark all as read'**
  String get notificationsMarkAll;

  /// Accessibility label for an unread notification
  ///
  /// In en, this message translates to:
  /// **'Unread'**
  String get notificationsUnread;

  /// Fallback when a notification key is not recognized
  ///
  /// In en, this message translates to:
  /// **'Notification'**
  String get notificationUnknown;

  /// Title for request_submitted
  ///
  /// In en, this message translates to:
  /// **'New trip request'**
  String get notificationRequestSubmittedTitle;

  /// Body for request_submitted
  ///
  /// In en, this message translates to:
  /// **'{requester} requested a trip from {pickup} to {destination}.'**
  String notificationRequestSubmittedBody(
    String requester,
    String pickup,
    String destination,
  );

  /// Title for trip_ready_to_assign
  ///
  /// In en, this message translates to:
  /// **'Trip ready to assign'**
  String get notificationTripReadyTitle;

  /// Body for trip_ready_to_assign
  ///
  /// In en, this message translates to:
  /// **'{requester} is waiting for a driver on the trip from {pickup} to {destination}.'**
  String notificationTripReadyBody(
    String requester,
    String pickup,
    String destination,
  );

  /// Title for trip_assigned
  ///
  /// In en, this message translates to:
  /// **'Driver assigned'**
  String get notificationTripAssignedTitle;

  /// Body for trip_assigned
  ///
  /// In en, this message translates to:
  /// **'{driver} is assigned to the trip from {pickup} to {destination}.'**
  String notificationTripAssignedBody(
    String driver,
    String pickup,
    String destination,
  );

  /// Title for own_trip_assigned
  ///
  /// In en, this message translates to:
  /// **'Driver assigned to your trip'**
  String get notificationOwnTripAssignedTitle;

  /// Body for own_trip_assigned
  ///
  /// In en, this message translates to:
  /// **'{driver} is assigned to your trip from {pickup} to {destination}.'**
  String notificationOwnTripAssignedBody(
    String driver,
    String pickup,
    String destination,
  );

  /// Title for trip_ended_report_needed
  ///
  /// In en, this message translates to:
  /// **'Trip ended'**
  String get notificationTripEndedTitle;

  /// Body for trip_ended_report_needed
  ///
  /// In en, this message translates to:
  /// **'Your trip from {pickup} to {destination} has ended. Please submit the report.'**
  String notificationTripEndedBody(String pickup, String destination);

  /// Android notification channel name for trip pushes
  ///
  /// In en, this message translates to:
  /// **'Trips'**
  String get notificationChannelTrips;

  /// Android notification channel description for trip pushes
  ///
  /// In en, this message translates to:
  /// **'Trip assignments and request updates'**
  String get notificationChannelTripsDescription;

  /// No description provided for @navAttendance.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get navAttendance;

  /// No description provided for @attendanceCardTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance'**
  String get attendanceCardTitle;

  /// No description provided for @attendanceNotCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not checked in'**
  String get attendanceNotCheckedIn;

  /// No description provided for @attendanceCheckedInAt.
  ///
  /// In en, this message translates to:
  /// **'Checked in at {time}'**
  String attendanceCheckedInAt(String time);

  /// No description provided for @attendanceCheckedOutAt.
  ///
  /// In en, this message translates to:
  /// **'Checked out at {time}'**
  String attendanceCheckedOutAt(String time);

  /// No description provided for @attendanceScanCheckIn.
  ///
  /// In en, this message translates to:
  /// **'Scan QR to check in'**
  String get attendanceScanCheckIn;

  /// No description provided for @attendanceScanCheckOut.
  ///
  /// In en, this message translates to:
  /// **'Scan QR to check out'**
  String get attendanceScanCheckOut;

  /// No description provided for @attendanceScanTitle.
  ///
  /// In en, this message translates to:
  /// **'Scan QR'**
  String get attendanceScanTitle;

  /// No description provided for @attendanceScanCancelled.
  ///
  /// In en, this message translates to:
  /// **'Scan cancelled.'**
  String get attendanceScanCancelled;

  /// No description provided for @attendanceScanUnsupported.
  ///
  /// In en, this message translates to:
  /// **'QR scanning runs on the Android or iOS app. Stop the app completely, then open it again on a phone or emulator. Hot reload does not load the camera.'**
  String get attendanceScanUnsupported;

  /// No description provided for @attendanceCheckedInSuccess.
  ///
  /// In en, this message translates to:
  /// **'Checked in.'**
  String get attendanceCheckedInSuccess;

  /// No description provided for @attendanceCheckedOutSuccess.
  ///
  /// In en, this message translates to:
  /// **'Checked out.'**
  String get attendanceCheckedOutSuccess;

  /// No description provided for @attendanceHistoryEmpty.
  ///
  /// In en, this message translates to:
  /// **'No attendance in this period.'**
  String get attendanceHistoryEmpty;

  /// No description provided for @attendanceTotals.
  ///
  /// In en, this message translates to:
  /// **'Present {present}, absent {absent}, on-site {hours} h'**
  String attendanceTotals(int present, int absent, String hours);

  /// No description provided for @attendanceAbsent.
  ///
  /// In en, this message translates to:
  /// **'Absent'**
  String get attendanceAbsent;

  /// No description provided for @attendanceNoCheckOut.
  ///
  /// In en, this message translates to:
  /// **'No check-out'**
  String get attendanceNoCheckOut;

  /// No description provided for @attendanceDayLine.
  ///
  /// In en, this message translates to:
  /// **'In {checkIn} · Out {checkOut} · {hours} h'**
  String attendanceDayLine(String checkIn, String checkOut, String hours);

  /// No description provided for @attendanceStatusCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in'**
  String get attendanceStatusCheckedIn;

  /// No description provided for @attendanceStatusCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'Checked out'**
  String get attendanceStatusCheckedOut;

  /// No description provided for @attendanceInvalidQr.
  ///
  /// In en, this message translates to:
  /// **'This QR code is not valid.'**
  String get attendanceInvalidQr;

  /// No description provided for @attendanceMockLocation.
  ///
  /// In en, this message translates to:
  /// **'A mocked location cannot be used to check in.'**
  String get attendanceMockLocation;

  /// No description provided for @attendanceLowAccuracy.
  ///
  /// In en, this message translates to:
  /// **'The GPS reading is not accurate enough.'**
  String get attendanceLowAccuracy;

  /// No description provided for @attendanceOutsideRadius.
  ///
  /// In en, this message translates to:
  /// **'You are {distance} m from headquarters. The allowed radius is {radius} m.'**
  String attendanceOutsideRadius(int distance, int radius);

  /// No description provided for @attendanceAlreadyCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'You already checked in today.'**
  String get attendanceAlreadyCheckedIn;

  /// No description provided for @attendanceNotCheckedInError.
  ///
  /// In en, this message translates to:
  /// **'Check in before checking out.'**
  String get attendanceNotCheckedInError;

  /// No description provided for @attendanceAlreadyCheckedOut.
  ///
  /// In en, this message translates to:
  /// **'You already checked out today.'**
  String get attendanceAlreadyCheckedOut;

  /// No description provided for @attendanceActiveTrip.
  ///
  /// In en, this message translates to:
  /// **'Finish the active trip before checking out.'**
  String get attendanceActiveTrip;

  /// No description provided for @attendanceFilterAll.
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get attendanceFilterAll;

  /// No description provided for @attendanceFilterCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Checked in today'**
  String get attendanceFilterCheckedIn;

  /// No description provided for @attendanceFilterNotCheckedIn.
  ///
  /// In en, this message translates to:
  /// **'Not checked in'**
  String get attendanceFilterNotCheckedIn;

  /// No description provided for @attendanceFilterEmpty.
  ///
  /// In en, this message translates to:
  /// **'No drivers match this attendance filter.'**
  String get attendanceFilterEmpty;

  /// No description provided for @attendanceOnTrip.
  ///
  /// In en, this message translates to:
  /// **'On trip'**
  String get attendanceOnTrip;

  /// No description provided for @attendanceAdjustTitle.
  ///
  /// In en, this message translates to:
  /// **'Adjust attendance'**
  String get attendanceAdjustTitle;

  /// No description provided for @attendanceWorkDate.
  ///
  /// In en, this message translates to:
  /// **'Work date'**
  String get attendanceWorkDate;

  /// No description provided for @attendanceCheckInTime.
  ///
  /// In en, this message translates to:
  /// **'Check-in time'**
  String get attendanceCheckInTime;

  /// No description provided for @attendanceCheckOutTime.
  ///
  /// In en, this message translates to:
  /// **'Check-out time'**
  String get attendanceCheckOutTime;

  /// No description provided for @attendanceReasonLabel.
  ///
  /// In en, this message translates to:
  /// **'Reason'**
  String get attendanceReasonLabel;

  /// No description provided for @attendanceReasonRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a reason.'**
  String get attendanceReasonRequired;

  /// No description provided for @attendanceAdjustSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get attendanceAdjustSave;

  /// No description provided for @attendanceCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get attendanceCancel;

  /// No description provided for @attendanceQrTitle.
  ///
  /// In en, this message translates to:
  /// **'Attendance QR'**
  String get attendanceQrTitle;

  /// No description provided for @attendanceOffDay.
  ///
  /// In en, this message translates to:
  /// **'Today is a weekly day off.'**
  String get attendanceOffDay;

  /// No description provided for @locationPreciseRequired.
  ///
  /// In en, this message translates to:
  /// **'Precise location is required.'**
  String get locationPreciseRequired;

  /// No description provided for @locationInaccurate.
  ///
  /// In en, this message translates to:
  /// **'The location reading is not accurate enough.'**
  String get locationInaccurate;

  /// No description provided for @locationMocked.
  ///
  /// In en, this message translates to:
  /// **'Mock locations are not allowed.'**
  String get locationMocked;

  /// Slide-to-confirm track label for attendance check-in
  ///
  /// In en, this message translates to:
  /// **'Slide to check in'**
  String get slideToCheckIn;

  /// Slide-to-confirm track label for attendance check-out
  ///
  /// In en, this message translates to:
  /// **'Slide to check out'**
  String get slideToCheckOut;

  /// Form section title for name fields
  ///
  /// In en, this message translates to:
  /// **'Personal details'**
  String get formSectionPersonal;

  /// Form section title for email and phone
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get formSectionContact;

  /// Form section title for car plate and licenses
  ///
  /// In en, this message translates to:
  /// **'Vehicle & license'**
  String get formSectionVehicle;

  /// Form section title for password fields
  ///
  /// In en, this message translates to:
  /// **'Sign-in'**
  String get formSectionAccess;

  /// Form section title for branch and work places
  ///
  /// In en, this message translates to:
  /// **'Work'**
  String get formSectionWork;

  /// Form section title for map coordinates
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get formSectionLocation;

  /// Form section title for place names and address
  ///
  /// In en, this message translates to:
  /// **'Place details'**
  String get formSectionPlace;

  /// Shown when a form fails validation
  ///
  /// In en, this message translates to:
  /// **'Check the highlighted fields.'**
  String get formFixErrors;

  /// Password strength label
  ///
  /// In en, this message translates to:
  /// **'Weak'**
  String get passwordStrengthWeak;

  /// Password strength label
  ///
  /// In en, this message translates to:
  /// **'Fair'**
  String get passwordStrengthFair;

  /// Password strength label
  ///
  /// In en, this message translates to:
  /// **'Good'**
  String get passwordStrengthGood;

  /// Password strength label
  ///
  /// In en, this message translates to:
  /// **'Strong'**
  String get passwordStrengthStrong;

  /// Tooltip for the clear button in a search field
  ///
  /// In en, this message translates to:
  /// **'Clear search'**
  String get clearSearch;

  /// Dashboard chart title
  ///
  /// In en, this message translates to:
  /// **'Trips this week'**
  String get adminTripsWeekTitle;

  /// Dashboard chart subtitle
  ///
  /// In en, this message translates to:
  /// **'Scheduled per day, last 7 days'**
  String get adminTripsWeekSubtitle;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
