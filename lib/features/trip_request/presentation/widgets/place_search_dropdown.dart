import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_preview_map.dart';
import 'package:teletech_drivers/features/trip_request/presentation/models/place_selection.dart';

/// Searchable list of approved places, plus an "Other" custom option.
///
/// Mobile interaction (Strategy: browse-then-search):
/// 1. First tap opens the list without the keyboard so options stay readable.
/// 2. Second tap on the field enables typing and shows the keyboard to filter.
class PlaceSearchDropdown extends StatefulWidget {
  const PlaceSearchDropdown({
    required this.places,
    required this.label,
    required this.searchHint,
    required this.onSelected,
    this.otherOptionLabel,
    this.selected,
    this.errorText,
    this.enabled = true,
    this.includeOtherOption = true,
    this.requireCoordinates = true,
    this.excludePlaceIds = const {},
    super.key,
  });

  final List<Place> places;
  final PlaceSelection? selected;
  final String label;
  final String searchHint;

  /// Label for the custom "Other" row; required when [includeOtherOption] is true.
  final String? otherOptionLabel;
  final String? errorText;
  final bool enabled;

  /// When false, only approved places are listed (e.g. favorite-place multi-select).
  final bool includeOtherOption;

  /// When true, places without coordinates cannot be selected (trip requests).
  final bool requireCoordinates;

  /// Place ids already chosen elsewhere (hidden from the list).
  final Set<String> excludePlaceIds;
  final ValueChanged<PlaceSelection?> onSelected;

  @override
  State<PlaceSearchDropdown> createState() => _PlaceSearchDropdownState();
}

class _PlaceSearchDropdownState extends State<PlaceSearchDropdown> {
  late final TextEditingController _searchController;
  late final FocusNode _focusNode;
  var _didSyncInitialLabel = false;
  var _listOpen = false;
  var _searchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _focusNode = FocusNode(canRequestFocus: false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didSyncInitialLabel) {
      _didSyncInitialLabel = true;
      _searchController.text = _labelFor(widget.selected);
    }
  }

  @override
  void didUpdateWidget(covariant PlaceSearchDropdown oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.enabled && _listOpen) {
      _closeList();
      return;
    }
    final selectionChanged =
        (widget.selected == null) != (oldWidget.selected == null) ||
        (widget.selected != null &&
            oldWidget.selected != null &&
            !PlaceSelection.isSame(widget.selected, oldWidget.selected));
    if (selectionChanged && !_searchActive) {
      final next = _labelFor(widget.selected);
      if (_searchController.text != next) {
        _searchController.text = next;
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  String _labelFor(PlaceSelection? selection) {
    if (selection is ApprovedPlaceSelection) {
      final languageCode = Localizations.localeOf(context).languageCode;
      final place = selection.place;
      if (widget.requireCoordinates && !place.hasCoordinates) {
        final l10n = AppLocalizations.of(context);
        return '${place.displayName(languageCode)} (${l10n.noLocationBadge})';
      }
      return place.displayName(languageCode);
    }
    if (selection is CustomPlaceSelection) {
      return widget.otherOptionLabel ?? '';
    }
    return '';
  }

  List<_PlaceOption> _buildOptions(AppLocalizations l10n, String languageCode) {
    return [
      for (final place in widget.places)
        if (!widget.excludePlaceIds.contains(place.id))
          _PlaceOption(
            value: ApprovedPlaceSelection(place),
            label: place.hasCoordinates || !widget.requireCoordinates
                ? place.displayName(languageCode)
                : '${place.displayName(languageCode)} (${l10n.noLocationBadge})',
            enabled: !widget.requireCoordinates || place.hasCoordinates,
            nameEn: place.nameEn,
            nameAr: place.nameAr,
          ),
      if (widget.includeOtherOption)
        _PlaceOption(
          value: const CustomPlaceSelection(),
          label: widget.otherOptionLabel ?? '',
          enabled: true,
          leadingIcon: Icons.edit_outlined,
          alwaysVisible: true,
        ),
    ];
  }

  List<_PlaceOption> _filterOptions(List<_PlaceOption> options, String filter) {
    final query = filter.trim().toLowerCase();
    if (query.isEmpty || !_searchActive) return options;

    return [
      for (final option in options)
        if (option.alwaysVisible || option.matches(query)) option,
    ];
  }

  double _menuMaxHeight(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return ((size.height - keyboard) * 0.42).clamp(180.0, 360.0);
  }

  void _openList() {
    _focusNode.canRequestFocus = false;
    _focusNode.unfocus();
    setState(() {
      _listOpen = true;
      _searchActive = false;
    });
  }

  void _enableSearch() {
    _focusNode.canRequestFocus = true;
    setState(() {
      _searchActive = true;
      _searchController.clear();
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _searchActive) {
        _focusNode.requestFocus();
      }
    });
  }

  void _closeList() {
    _focusNode.canRequestFocus = false;
    _focusNode.unfocus();
    setState(() {
      _listOpen = false;
      _searchActive = false;
      _searchController.text = _labelFor(widget.selected);
    });
  }

  void _onFieldTap() {
    if (!widget.enabled) return;
    if (!_listOpen) {
      _openList();
      return;
    }
    if (!_searchActive) {
      _enableSearch();
    }
  }

  void _toggleList() {
    if (!widget.enabled) return;
    if (_listOpen) {
      _closeList();
    } else {
      _openList();
    }
  }

  void _onOptionSelected(_PlaceOption option, AppLocalizations l10n) {
    if (widget.requireCoordinates &&
        option.value is ApprovedPlaceSelection &&
        !(option.value as ApprovedPlaceSelection).place.hasCoordinates) {
      widget.onSelected(null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.placeCannotSelectWithoutLocation)),
      );
      return;
    }
    widget.onSelected(option.value);
    _focusNode.canRequestFocus = false;
    _focusNode.unfocus();
    setState(() {
      _listOpen = false;
      _searchActive = false;
      _searchController.text = option.label;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final theme = Theme.of(context);
    final selectedApproved = widget.selected is ApprovedPlaceSelection
        ? (widget.selected! as ApprovedPlaceSelection).place
        : null;
    final selectedMissingCoords =
        widget.requireCoordinates &&
        selectedApproved != null &&
        !selectedApproved.hasCoordinates;
    final options = _filterOptions(
      _buildOptions(l10n, languageCode),
      _searchController.text,
    );

    return TapRegion(
      onTapOutside: (_) {
        if (_listOpen) _closeList();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _searchController,
            focusNode: _focusNode,
            enabled: widget.enabled,
            readOnly: !_searchActive,
            enableInteractiveSelection: _searchActive,
            textInputAction: TextInputAction.search,
            onTap: _onFieldTap,
            onChanged: _searchActive ? (_) => setState(() {}) : null,
            decoration: InputDecoration(
              labelText: widget.label,
              hintText: widget.searchHint,
              errorText: widget.errorText,
              prefixIcon: const Icon(Icons.place_outlined),
              suffixIcon: IconButton(
                tooltip: widget.label,
                onPressed: widget.enabled ? _toggleList : null,
                icon: Icon(
                  _listOpen ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                ),
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          if (_listOpen) ...[
            const SizedBox(height: 6),
            Material(
              elevation: 3,
              shadowColor: theme.colorScheme.shadow.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
              clipBehavior: Clip.antiAlias,
              color: theme.colorScheme.surfaceContainerHigh,
              // SingleChildScrollView (not shrinkWrap ListView) so parents that
              // measure intrinsic height (dialogs, Column min) do not crash.
              child: ConstrainedBox(
                constraints: BoxConstraints(maxHeight: _menuMaxHeight(context)),
                child: options.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 20,
                        ),
                        child: Text(
                          widget.searchHint,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.hintColor,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    : SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (
                              var index = 0;
                              index < options.length;
                              index++
                            ) ...[
                              if (index > 0)
                                Divider(
                                  height: 1,
                                  indent: 16,
                                  endIndent: 16,
                                  color: theme.dividerColor.withValues(
                                    alpha: 0.5,
                                  ),
                                ),
                              ListTile(
                                enabled: options[index].enabled,
                                leading: options[index].leadingIcon == null
                                    ? null
                                    : Icon(options[index].leadingIcon),
                                title: Text(
                                  options[index].label,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                contentPadding:
                                    const EdgeInsetsDirectional.fromSTEB(
                                      16,
                                      4,
                                      16,
                                      4,
                                    ),
                                onTap: options[index].enabled
                                    ? () => _onOptionSelected(
                                        options[index],
                                        l10n,
                                      )
                                    : null,
                              ),
                            ],
                          ],
                        ),
                      ),
              ),
            ),
          ],
          if (selectedMissingCoords) ...[
            const SizedBox(height: 6),
            Text(
              l10n.placeCannotSelectWithoutLocation,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.error,
              ),
            ),
          ],
          if (selectedApproved != null && selectedApproved.hasCoordinates)
            OptionalPlacePreviewMap(
              latitude: selectedApproved.latitude,
              longitude: selectedApproved.longitude,
              height: 120,
            ),
        ],
      ),
    );
  }
}

class _PlaceOption {
  const _PlaceOption({
    required this.value,
    required this.label,
    required this.enabled,
    this.nameEn = '',
    this.nameAr = '',
    this.leadingIcon,
    this.alwaysVisible = false,
  });

  final PlaceSelection value;
  final String label;
  final bool enabled;
  final String nameEn;
  final String nameAr;
  final IconData? leadingIcon;
  final bool alwaysVisible;

  bool matches(String query) {
    return label.toLowerCase().contains(query) ||
        nameEn.toLowerCase().contains(query) ||
        nameAr.toLowerCase().contains(query);
  }
}
