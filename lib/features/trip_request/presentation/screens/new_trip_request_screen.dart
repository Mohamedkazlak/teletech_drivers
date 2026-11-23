import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/app_text_field.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/controllers/place_form_controller.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/screens/location_picker_screen.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/time/cairo_clock.dart';
import 'package:teletech_drivers/features/trip_request/presentation/controllers/create_trip_request_controller.dart';
import 'package:teletech_drivers/features/trip_request/presentation/scheduling/schedule_field_message.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/future_schedule_dialog.dart';
import 'package:teletech_drivers/features/trip_request/presentation/models/place_selection.dart';
import 'package:teletech_drivers/features/trip_request/presentation/validation/trip_request_validators.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/custom_place_field.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/map_place_outcome_sheet.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/map_picked_place_summary.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/no_places_available_state.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/place_search_dropdown.dart';

/// Form for an employee to submit a new trip request.
class NewTripRequestScreen extends ConsumerStatefulWidget {
  const NewTripRequestScreen({super.key});

  @override
  ConsumerState<NewTripRequestScreen> createState() =>
      _NewTripRequestScreenState();
}

class _NewTripRequestScreenState extends ConsumerState<NewTripRequestScreen> {
  final _notesController = TextEditingController();
  final _customPickupController = TextEditingController();
  final _customDestinationController = TextEditingController();

  PlaceSelection? _pickup;
  PlaceSelection? _destination;
  DateTime? _requestedDateTime;
  String? _pickupError;
  String? _destinationError;
  String? _dateTimeError;

  @override
  void dispose() {
    _notesController.dispose();
    _customPickupController.dispose();
    _customDestinationController.dispose();
    super.dispose();
  }

  bool get _canSavePlace {
    final role = ref.read(currentUserProvider).asData?.value?.role;
    return role == UserRole.companyAdmin ||
        role == UserRole.driversAdmin ||
        role == UserRole.admin;
  }

  /// Appends a blank line so the employee can list another fellow rider name.
  void _addNotesNameLine() {
    final text = _notesController.text;
    final insertion = text.isEmpty || text.endsWith('\n') ? '' : '\n';
    final next = '$text$insertion';
    _notesController.value = TextEditingValue(
      text: next,
      selection: TextSelection.collapsed(offset: next.length),
    );
    setState(() {});
  }

  Future<void> _pickDateTime() async {
    final picked = await FutureScheduleDialog.pick(
      context,
      initialUtc: _requestedDateTime,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _requestedDateTime = picked;
      _dateTimeError = null;
    });
    ref.read(createTripRequestControllerProvider.notifier).clearFailure();
  }

  void _onPickupSelected(PlaceSelection? selection) {
    final l10n = AppLocalizations.of(context);
    setState(() {
      if (selection is CustomPlaceSelection) {
        _customPickupController.clear();
        _pickup = CustomPlaceSelection(_customPickupController.text);
      } else {
        _customPickupController.clear();
        _pickup = selection;
      }
      _pickupError = null;
      if (_destinationError != null) {
        _destinationError = TripRequestValidators.destinationPlace(
          _destination,
          l10n,
          pickup: _pickup,
        );
      }
    });
  }

  void _onDestinationSelected(PlaceSelection? selection) {
    setState(() {
      if (selection is CustomPlaceSelection) {
        _customDestinationController.clear();
        _destination = CustomPlaceSelection(_customDestinationController.text);
      } else {
        _customDestinationController.clear();
        _destination = selection;
      }
      _destinationError = null;
    });
  }

  Future<void> _chooseOnMap({required bool forPickup}) async {
    final l10n = AppLocalizations.of(context);
    final places = ref.read(activePlacesProvider).asData?.value ?? const [];
    final picked = await LocationPickerScreen.open(context);
    if (picked == null || !mounted) return;

    final outcome = await showMapPlaceOutcomeSheet(
      context: context,
      location: picked,
      canSavePlace: _canSavePlace,
      existingPlaces: places,
    );
    if (outcome == null || !mounted) return;

    if (outcome is MapPlaceUseForTripOnly) {
      setState(() {
        if (forPickup) {
          _customPickupController.text = outcome.selection.trimmedName;
          _pickup = outcome.selection;
          _pickupError = null;
        } else {
          _customDestinationController.text = outcome.selection.trimmedName;
          _destination = outcome.selection;
          _destinationError = null;
        }
      });
      return;
    }

    if (outcome is MapPlaceSaveAsPlace) {
      final geocoded = outcome.location.address?.trim() ?? '';
      final saved = await ref
          .read(placeFormControllerProvider.notifier)
          .add(
            nameEn: outcome.nameEn,
            nameAr: outcome.nameAr,
            latitude: outcome.location.lat,
            longitude: outcome.location.lng,
            address: geocoded.isNotEmpty ? geocoded : outcome.nameAr,
          );
      if (!mounted) return;
      if (!saved) {
        final failure = ref.read(placeFormControllerProvider).failure;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure?.message(l10n) ?? l10n.errorUnknown)),
        );
        return;
      }

      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(l10n.placeCreated)));

      ref.invalidate(activePlacesProvider);
      final refreshed = await ref
          .read(activePlacesProvider.future)
          .catchError((_) => places);
      if (!mounted) return;
      final match = _findSavedPlace(
        refreshed,
        nameEn: outcome.nameEn,
        nameAr: outcome.nameAr,
      );
      if (match == null) {
        // Place created; use trip-only custom until stream refreshes.
        final fallback = CustomPlaceSelection(
          outcome.nameEn,
          outcome.location.lat,
          outcome.location.lng,
          outcome.location.address,
        );
        setState(() {
          if (forPickup) {
            _pickup = fallback;
            _pickupError = null;
          } else {
            _destination = fallback;
            _destinationError = null;
          }
        });
        return;
      }

      setState(() {
        if (forPickup) {
          _customPickupController.clear();
          _pickup = ApprovedPlaceSelection(match);
          _pickupError = null;
        } else {
          _customDestinationController.clear();
          _destination = ApprovedPlaceSelection(match);
          _destinationError = null;
        }
      });
    }
  }

  String? _bannerMessage(
    Failure? failure,
    String? timeError,
    AppLocalizations l10n,
  ) {
    if (failure == null) return null;
    if (failure is ValidationFailure && timeError != null) {
      final otherFields = failure.fieldErrors.keys.where(
        (key) => key != 'requested_at' && key != 'scheduled_at',
      );
      if (otherFields.isEmpty) return null;
    }
    return failure.message(l10n);
  }

  Place? _findSavedPlace(
    List<Place> places, {
    required String nameEn,
    required String nameAr,
  }) {
    final enKey = nameEn.toLowerCase();
    final arKey = nameAr.toLowerCase();
    for (final place in places) {
      if (place.nameEn.toLowerCase() == enKey ||
          place.nameAr.toLowerCase() == arKey) {
        return place;
      }
    }
    return null;
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;

    var pickup = _pickup;
    var destination = _destination;
    if (pickup is CustomPlaceSelection && !pickup.isMapPick) {
      pickup = CustomPlaceSelection(_customPickupController.text);
    }
    if (destination is CustomPlaceSelection && !destination.isMapPick) {
      destination = CustomPlaceSelection(_customDestinationController.text);
    }

    final pickupError = TripRequestValidators.pickupPlace(pickup, l10n);
    final destinationError = TripRequestValidators.destinationPlace(
      destination,
      l10n,
      pickup: pickup,
    );
    final dateError = TripRequestValidators.requestedDateTime(
      _requestedDateTime,
      l10n,
    );

    setState(() {
      _pickup = pickup;
      _destination = destination;
      _pickupError = pickupError;
      _destinationError = destinationError;
      _dateTimeError = dateError;
    });

    if (pickupError != null ||
        destinationError != null ||
        dateError != null ||
        pickup == null ||
        destination == null ||
        _requestedDateTime == null) {
      return;
    }

    ref.read(createTripRequestControllerProvider.notifier).clearFailure();

    final result = await ref
        .read(createTripRequestControllerProvider.notifier)
        .submit(
          pickupPlaceId: pickup.storagePlaceId,
          pickupPlaceName: pickup.storagePlaceName(languageCode),
          destinationPlaceId: destination.storagePlaceId,
          destinationPlaceName: destination.storagePlaceName(languageCode),
          requestedDateTime: _requestedDateTime!,
          notes: _notesController.text,
          pickupLat: pickup.hasCoordinates ? pickup.lat : null,
          pickupLng: pickup.hasCoordinates ? pickup.lng : null,
          pickupAddress: pickup.address,
          destinationLat: destination.hasCoordinates ? destination.lat : null,
          destinationLng: destination.hasCoordinates ? destination.lng : null,
          destinationAddress: destination.address,
        );

    if (!mounted) return;
    if (result == null) {
      final failure = ref.read(createTripRequestControllerProvider).failure;
      final serverMessage = scheduleFieldMessage(failure);
      if (serverMessage != null) {
        setState(() => _dateTimeError = serverMessage);
      }
      return;
    }

    final tripId = result.tripId;
    final message = tripId != null && tripId.isNotEmpty
        ? l10n.driversAdminTripUnassigned
        : l10n.tripRequestCreated;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final formState = ref.watch(createTripRequestControllerProvider);
    final serverTimeError = scheduleFieldMessage(formState.failure);
    final timeError = _dateTimeError ?? serverTimeError;
    final banner = _bannerMessage(formState.failure, serverTimeError, l10n);
    final placesAsync = ref.watch(activePlacesProvider);
    final locale = Localizations.localeOf(context);
    final languageCode = locale.languageCode;
    final dateFormat = DateFormat.yMMMd(locale.toString()).add_jm();
    final requested = _requestedDateTime;
    final pickupIsCustom = _pickup is CustomPlaceSelection;
    final destinationIsCustom = _destination is CustomPlaceSelection;
    final pickupIsMap =
        _pickup is CustomPlaceSelection &&
        (_pickup! as CustomPlaceSelection).isMapPick;
    final destinationIsMap =
        _destination is CustomPlaceSelection &&
        (_destination! as CustomPlaceSelection).isMapPick;

    return AppScaffold(
      title: l10n.newTripRequestTitle,
      showBackButton: true,
      body: SafeArea(
        child: placesAsync.when(
          loading: () =>
              Center(child: AppLoadingIndicator(label: l10n.loading)),
          error: (error, _) => Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                messageForError(error, l10n),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
            ),
          ),
          data: (places) {
            if (places.isEmpty) {
              return const NoPlacesAvailableState();
            }

            return ListView(
              padding: const EdgeInsetsDirectional.fromSTEB(24, 16, 24, 24),
              children: [
                AnimatedErrorBanner(message: banner),
                if (banner != null) const SizedBox(height: 16),
                PlaceSearchDropdown(
                  key: ValueKey('pickup-$languageCode-${_pickup.runtimeType}'),
                  places: places,
                  selected: pickupIsMap ? null : _pickup,
                  label: l10n.pickupLocationLabel,
                  searchHint: l10n.searchPlacesHint,
                  otherOptionLabel: l10n.otherPlaceOption,
                  errorText: pickupIsCustom ? null : _pickupError,
                  enabled: !formState.isLoading,
                  onSelected: _onPickupSelected,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: formState.isLoading
                        ? null
                        : () => _chooseOnMap(forPickup: true),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l10n.chooseOnMap),
                  ),
                ),
                if (pickupIsMap) ...[
                  MapPickedPlaceSummary(
                    selection: _pickup! as CustomPlaceSelection,
                    enabled: !formState.isLoading,
                    onClear: () {
                      setState(() {
                        _pickup = null;
                        _customPickupController.clear();
                        _pickupError = null;
                      });
                    },
                  ),
                ] else if (pickupIsCustom) ...[
                  CustomPlaceField(
                    controller: _customPickupController,
                    label: l10n.customPlaceLabel,
                    hint: l10n.customPlaceHint,
                    errorText: _pickupError,
                    enabled: !formState.isLoading,
                    onChanged: (value) {
                      setState(() {
                        _pickup = CustomPlaceSelection(value);
                        _pickupError = null;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                PlaceSearchDropdown(
                  key: ValueKey(
                    'destination-$languageCode-${_destination.runtimeType}',
                  ),
                  places: places,
                  selected: destinationIsMap ? null : _destination,
                  label: l10n.destinationLabel,
                  searchHint: l10n.searchPlacesHint,
                  otherOptionLabel: l10n.otherPlaceOption,
                  errorText: destinationIsCustom ? null : _destinationError,
                  enabled: !formState.isLoading,
                  onSelected: _onDestinationSelected,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: formState.isLoading
                        ? null
                        : () => _chooseOnMap(forPickup: false),
                    icon: const Icon(Icons.map_outlined),
                    label: Text(l10n.chooseOnMap),
                  ),
                ),
                if (destinationIsMap) ...[
                  MapPickedPlaceSummary(
                    selection: _destination! as CustomPlaceSelection,
                    enabled: !formState.isLoading,
                    onClear: () {
                      setState(() {
                        _destination = null;
                        _customDestinationController.clear();
                        _destinationError = null;
                      });
                    },
                  ),
                ] else if (destinationIsCustom) ...[
                  CustomPlaceField(
                    controller: _customDestinationController,
                    label: l10n.customPlaceLabel,
                    hint: l10n.customPlaceHint,
                    errorText: _destinationError,
                    enabled: !formState.isLoading,
                    onChanged: (value) {
                      setState(() {
                        _destination = CustomPlaceSelection(value);
                        _destinationError = null;
                      });
                    },
                  ),
                ],
                const SizedBox(height: 16),
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: l10n.requestedDateTimeLabel,
                    prefixIcon: const Icon(Icons.calendar_month_outlined),
                    errorText: timeError,
                  ),
                  child: InkWell(
                    onTap: formState.isLoading ? null : _pickDateTime,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              requested == null
                                  ? l10n.selectDateTime
                                  : dateFormat.format(
                                      CairoClock.wall(requested),
                                    ),
                              style: Theme.of(context).textTheme.bodyLarge
                                  ?.copyWith(
                                    color: requested == null
                                        ? Theme.of(context).hintColor
                                        : null,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _notesController,
                  label: l10n.notesLabel,
                  hintText: l10n.notesHint,
                  helperText: l10n.notesFellowEmployeesHint,
                  enabled: !formState.isLoading,
                  keyboardType: TextInputType.multiline,
                  textInputAction: TextInputAction.newline,
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 8,
                  maxLength: 500,
                  prefixIcon: Icons.notes_outlined,
                ),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: TextButton.icon(
                    onPressed: formState.isLoading ? null : _addNotesNameLine,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: Text(l10n.addAnotherNameLine),
                  ),
                ),
                const SizedBox(height: 24),
                AppButton(
                  label: l10n.submitTripRequest,
                  loadingLabel: l10n.loading,
                  isLoading: formState.isLoading,
                  onPressed: _submit,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
