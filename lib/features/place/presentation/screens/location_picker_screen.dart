import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
import 'package:permission_handler/permission_handler.dart' as ph;
import 'package:teletech_drivers/core/widgets/map_pins.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/features/place/data/services/address_resolver.dart';
import 'package:teletech_drivers/features/place/data/services/nominatim_geocoding_service.dart';
import 'package:teletech_drivers/features/place/domain/entities/picked_location.dart';
import 'package:teletech_drivers/features/tracking/domain/constants/map_defaults.dart';
import 'package:teletech_drivers/features/tracking/presentation/widgets/osm_map_layer.dart';

/// Full-screen Uber-style map picker. Pops [PickedLocation] or null if cancelled.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({this.initialLocation, super.key});

  /// When editing, centers the map on this point.
  final PickedLocation? initialLocation;

  /// Opens the picker and returns the confirmed location, or null if cancelled.
  static Future<PickedLocation?> open(
    BuildContext context, {
    PickedLocation? initialLocation,
  }) {
    return Navigator.of(context, rootNavigator: true).push<PickedLocation>(
      MaterialPageRoute(
        builder: (_) => LocationPickerScreen(initialLocation: initialLocation),
      ),
    );
  }

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen>
    with SingleTickerProviderStateMixin {
  final _mapController = MapController();
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  late final AddressResolver _addressResolver;
  late final NominatimGeocodingService _nominatim;
  late final AnimationController _pinController;

  LatLng _center = MapDefaults.defaultCenter;
  var _mapReady = false;
  var _pinLifted = false;
  var _locating = false;
  var _searching = false;
  var _resolvingAddress = false;
  var _cardVisible = false;
  String? _address;
  String? _locateMessage;
  String? _searchError;
  List<NominatimSearchResult> _searchResults = const [];
  Timer? _addressDebounce;
  Timer? _searchDebounce;
  int _addressRequestId = 0;

  @override
  void initState() {
    super.initState();
    _nominatim = NominatimGeocodingService();
    _addressResolver = AddressResolver(nominatim: _nominatim);
    _pinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    final initial = widget.initialLocation;
    if (initial != null) {
      _center = LatLng(initial.lat, initial.lng);
      _address = initial.address;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() => _cardVisible = true);
      if (initial == null) {
        unawaited(_bootstrapCenter());
      } else {
        unawaited(_resolveAddressForCenter());
      }
    });
  }

  @override
  void dispose() {
    _addressDebounce?.cancel();
    _searchDebounce?.cancel();
    _searchController.dispose();
    _searchFocus.dispose();
    _pinController.dispose();
    _mapController.dispose();
    _addressResolver.dispose();
    _nominatim.dispose();
    super.dispose();
  }

  Future<void> _bootstrapCenter() async {
    final position = await _tryReadCurrentPosition(requestIfNeeded: false);
    if (!mounted || position == null) {
      unawaited(_resolveAddressForCenter());
      return;
    }
    final point = LatLng(position.latitude, position.longitude);
    setState(() => _center = point);
    if (_mapReady) {
      _mapController.move(point, 15);
    }
    unawaited(_resolveAddressForCenter());
  }

  Future<Position?> _tryReadCurrentPosition({
    required bool requestIfNeeded,
  }) async {
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied && requestIfNeeded) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
    } on Object {
      return null;
    }
  }

  void _onMapEvent(MapEvent event) {
    if (event is MapEventMoveStart ||
        event is MapEventFlingAnimation ||
        event is MapEventDoubleTapZoom) {
      _setPinLifted(true);
    }

    if (event is MapEventMove) {
      _center = event.camera.center;
    }

    if (event is MapEventMoveEnd ||
        event is MapEventFlingAnimationEnd ||
        event is MapEventDoubleTapZoomEnd) {
      _center = event.camera.center;
      _setPinLifted(false);
      _scheduleAddressResolve();
    }
  }

  void _setPinLifted(bool lifted) {
    if (_pinLifted == lifted) return;
    _pinLifted = lifted;
    final disable = AppAnimations.disabled(context);
    if (disable) {
      _pinController.value = lifted ? 1 : 0;
      setState(() {});
      return;
    }
    if (lifted) {
      _pinController.forward();
    } else {
      _pinController.reverse();
    }
    setState(() {});
  }

  void _scheduleAddressResolve() {
    _addressDebounce?.cancel();
    _addressDebounce = Timer(const Duration(milliseconds: 600), () {
      unawaited(_resolveAddressForCenter());
    });
  }

  Future<void> _resolveAddressForCenter() async {
    final requestId = ++_addressRequestId;
    setState(() {
      _resolvingAddress = true;
      _address = null;
    });

    final resolved = await _addressResolver.resolve(
      lat: _center.latitude,
      lng: _center.longitude,
    );
    if (!mounted || requestId != _addressRequestId) return;

    setState(() {
      _resolvingAddress = false;
      _address = resolved;
    });
  }

  Future<void> _goToMyLocation() async {
    if (_locating) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _locating = true;
      _locateMessage = null;
    });

    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) {
        if (!mounted) return;
        setState(() => _locateMessage = l10n.locationServicesDisabled);
        await _showLocationHelp(
          message: l10n.locationServicesDisabled,
          openSettings: Geolocator.openLocationSettings,
        );
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() => _locateMessage = l10n.locationPermissionDenied);
        await _showLocationHelp(
          message: l10n.locationPermissionDenied,
          openSettings: ph.openAppSettings,
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      if (!mounted) return;
      final point = LatLng(position.latitude, position.longitude);
      setState(() => _center = point);
      unawaited(
        animateMapMove(
          controller: _mapController,
          target: point,
          zoom: 15,
          instant: AppAnimations.disabled(context),
        ),
      );
      _scheduleAddressResolve();
    } on Object {
      if (!mounted) return;
      setState(() => _locateMessage = l10n.locationUnavailable);
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _showLocationHelp({
    required String message,
    required Future<bool> Function() openSettings,
  }) async {
    final l10n = AppLocalizations.of(context);
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () async {
                Navigator.of(dialogContext).pop();
                await openSettings();
              },
              child: Text(l10n.openSettingsAction),
            ),
          ],
        );
      },
    );
  }

  /// Search as you type, after a short pause (the arrow still searches now).
  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    if (value.trim().length < 3) {
      if (_searchResults.isNotEmpty || _searchError != null) {
        setState(() {
          _searchResults = const [];
          _searchError = null;
        });
      }
      return;
    }
    _searchDebounce = Timer(const Duration(milliseconds: 550), () {
      if (mounted) unawaited(_submitSearch(keepFocus: true));
    });
  }

  Future<void> _submitSearch({bool keepFocus = false}) async {
    _searchDebounce?.cancel();
    final query = _searchController.text.trim();
    if (query.isEmpty || _searching) return;

    final l10n = AppLocalizations.of(context);
    if (!keepFocus) FocusScope.of(context).unfocus();
    setState(() {
      _searching = true;
      _searchError = null;
      _searchResults = const [];
    });

    try {
      final results = await _nominatim.search(query, limit: 5);
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchResults = results;
        if (results.isEmpty) {
          _searchError = l10n.locationSearchNoResults;
        }
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _searching = false;
        _searchError = l10n.locationSearchFailed;
      });
    }
  }

  void _selectSearchResult(NominatimSearchResult result) {
    final point = LatLng(result.lat, result.lng);
    setState(() {
      _center = point;
      _searchResults = const [];
      _searchError = null;
      _address = result.displayName;
      _resolvingAddress = false;
    });
    FocusScope.of(context).unfocus();
    _searchController.text = result.displayName;
    unawaited(
      animateMapMove(
        controller: _mapController,
        target: point,
        zoom: 15,
        instant: AppAnimations.disabled(context),
      ),
    );
    _addressDebounce?.cancel();
  }

  void _confirm() {
    Navigator.of(context).pop(
      PickedLocation(
        lat: _center.latitude,
        lng: _center.longitude,
        address: _address,
      ),
    );
  }

  String get _displayAddress {
    final l10n = AppLocalizations.of(context);
    if (_resolvingAddress) return l10n.resolvingAddress;
    final address = _address?.trim();
    if (address == null || address.isEmpty) {
      return l10n.addressNotAvailable;
    }
    return address;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final disableAnimations = AppAnimations.disabled(context);
    final pinOffset = Tween<double>(
      begin: 0,
      end: -14,
    ).animate(CurvedAnimation(parent: _pinController, curve: Curves.easeOut));
    final bottomPadding = MediaQuery.paddingOf(context).bottom;
    final coords =
        '${_center.latitude.toStringAsFixed(5)}, '
        '${_center.longitude.toStringAsFixed(5)}';

    return AppScaffold(
      title: l10n.pickLocationTitle,
      showBackButton: true,
      resizeToAvoidBottomInset: false,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: EdgeInsetsDirectional.only(bottom: 148 + bottomPadding),
        child: Tooltip(
          message: l10n.myLocationButton,
          child: Material(
            color: AppColors.white,
            elevation: 4,
            shadowColor: AppColors.navy.withValues(alpha: 0.4),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: _locating ? null : _goToMyLocation,
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: _locating
                      ? const SizedBox.square(
                          dimension: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(
                          Icons.my_location,
                          color: AppColors.deepBlue,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _center,
              initialZoom: widget.initialLocation != null
                  ? 15
                  : MapDefaults.defaultZoom,
              onMapReady: () => _mapReady = true,
              onMapEvent: _onMapEvent,
            ),
            children: [
              ...osmBaseLayers(textDirection: Directionality.of(context)),
            ],
          ),
          // Fixed center pin — map moves underneath (Uber-style).
          IgnorePointer(
            child: Center(
              child: AnimatedBuilder(
                animation: pinOffset,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, pinOffset.value),
                    child: child,
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const BrandPin(size: 42, animate: false),
                    AnimatedContainer(
                      duration: disableAnimations
                          ? Duration.zero
                          : const Duration(milliseconds: 180),
                      width: _pinLifted ? 6 : 10,
                      height: _pinLifted ? 3 : 4,
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 8, 12, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    elevation: 2,
                    borderRadius: BorderRadius.circular(12),
                    color: Theme.of(context).colorScheme.surface,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _searchFocus,
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: l10n.locationSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searching
                            ? const Padding(
                                padding: EdgeInsets.all(12),
                                child: SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                              )
                            : IconButton(
                                tooltip: l10n.locationSearchAction,
                                onPressed: _submitSearch,
                                icon: const Icon(Icons.arrow_forward),
                              ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                      ),
                      onChanged: _onSearchChanged,
                      onSubmitted: (_) => _submitSearch(),
                    ),
                  ),
                  if (_searchError != null) ...[
                    const SizedBox(height: 8),
                    Material(
                      color: AppColors.paleBlue,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Text(
                          _searchError!,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                  ],
                  if (_searchResults.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(12),
                      color: Theme.of(context).colorScheme.surface,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              for (
                                var index = 0;
                                index < _searchResults.length;
                                index++
                              ) ...[
                                if (index > 0) const Divider(height: 1),
                                ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.place_outlined),
                                  title: Text(
                                    _searchResults[index].displayName,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => _selectSearchResult(
                                    _searchResults[index],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  if (_locateMessage != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _locateMessage!,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedSlide(
              offset: _cardVisible ? Offset.zero : const Offset(0, 1),
              duration: disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 320),
              curve: Curves.easeOutCubic,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
                  child: Material(
                    elevation: 6,
                    borderRadius: BorderRadius.circular(16),
                    color: Theme.of(context).colorScheme.surface,
                    child: Padding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        16,
                        16,
                        16,
                        12,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.place,
                                color: AppColors.deepBlue,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.placePickerHint,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: AppColors.signal,
                                            fontWeight: FontWeight.w600,
                                          ),
                                    ),
                                    const SizedBox(height: 4),
                                    AnimatedSwitcher(
                                      duration: AppAnimations.duration(
                                        context,
                                        AppMotion.standard,
                                      ),
                                      switchInCurve: AppMotion.easeOut,
                                      transitionBuilder: (child, animation) =>
                                          FadeTransition(
                                            opacity: animation,
                                            child: child,
                                          ),
                                      child: Text(
                                        _displayAddress,
                                        key: ValueKey(_displayAddress),
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleSmall,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      coords,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(context).hintColor,
                                          ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_resolvingAddress)
                                const SizedBox.square(
                                  dimension: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          AppButton(
                            label: l10n.confirmLocation,
                            icon: Icons.check_rounded,
                            onPressed: _confirm,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
