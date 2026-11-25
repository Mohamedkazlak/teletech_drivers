import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_preview_map.dart';
import 'package:teletech_drivers/features/trip_request/presentation/models/place_selection.dart';

/// Place field that opens a searchable sheet of approved places.
///
/// One tap opens the sheet with the keyboard already up, so people can type
/// to filter or just scroll and tap. Each row shows the place name and its
/// address; places without a map location are marked and cannot be chosen
/// for trips. An "Other" row lets people enter or pick a custom place.
class PlaceSearchDropdown extends StatelessWidget {
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
    this.icon = Icons.place_outlined,
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

  /// Leading icon (pickup and destination use different marks).
  final IconData icon;

  String _labelFor(BuildContext context, PlaceSelection? selection) {
    if (selection is ApprovedPlaceSelection) {
      final languageCode = Localizations.localeOf(context).languageCode;
      return selection.place.displayName(languageCode);
    }
    if (selection is CustomPlaceSelection) return otherOptionLabel ?? '';
    return '';
  }

  Future<void> _open(BuildContext context) async {
    if (!enabled) return;
    FocusManager.instance.primaryFocus?.unfocus();
    final result = await showModalBottomSheet<PlaceSelection>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.white,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      sheetAnimationStyle: const AnimationStyle(
        curve: AppMotion.drawer,
        duration: Duration(milliseconds: 420),
        reverseDuration: Duration(milliseconds: 260),
      ),
      builder: (_) => _PlacePickerSheet(
        title: label,
        searchHint: searchHint,
        places: places,
        selected: selected,
        otherOptionLabel: includeOtherOption ? otherOptionLabel : null,
        requireCoordinates: requireCoordinates,
        excludePlaceIds: excludePlaceIds,
        icon: icon,
      ),
    );
    if (result != null) onSelected(result);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final selectedApproved = selected is ApprovedPlaceSelection
        ? (selected! as ApprovedPlaceSelection).place
        : null;
    final selectedMissingCoords =
        requireCoordinates &&
        selectedApproved != null &&
        !selectedApproved.hasCoordinates;
    final text = _labelFor(context, selected);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          value: text.isEmpty ? searchHint : text,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: enabled ? () => _open(context) : null,
            child: InputDecorator(
              isEmpty: text.isEmpty,
              decoration: InputDecoration(
                labelText: label,
                errorText: errorText,
                enabled: enabled,
                prefixIcon: Icon(icon),
                suffixIcon: const Icon(Icons.unfold_more_rounded),
              ),
              child: AnimatedSwitcher(
                duration: AppAnimations.duration(context, AppMotion.quick),
                child: Text(
                  text,
                  key: ValueKey(text),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge,
                ),
              ),
            ),
          ),
        ),
        if (selectedMissingCoords) ...[
          const SizedBox(height: 6),
          Text(
            l10n.placeCannotSelectWithoutLocation,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.error,
            ),
          ),
        ],
        AnimatedSize(
          duration: AppAnimations.duration(context, AppMotion.emphasized),
          curve: AppMotion.easeOut,
          alignment: Alignment.topCenter,
          child: selectedApproved != null && selectedApproved.hasCoordinates
              ? OptionalPlacePreviewMap(
                  latitude: selectedApproved.latitude,
                  longitude: selectedApproved.longitude,
                  height: 120,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _PlacePickerSheet extends StatefulWidget {
  const _PlacePickerSheet({
    required this.title,
    required this.searchHint,
    required this.places,
    required this.selected,
    required this.otherOptionLabel,
    required this.requireCoordinates,
    required this.excludePlaceIds,
    required this.icon,
  });

  final String title;
  final String searchHint;
  final List<Place> places;
  final PlaceSelection? selected;
  final String? otherOptionLabel;
  final bool requireCoordinates;
  final Set<String> excludePlaceIds;
  final IconData icon;

  @override
  State<_PlacePickerSheet> createState() => _PlacePickerSheetState();
}

class _PlacePickerSheetState extends State<_PlacePickerSheet> {
  final _query = TextEditingController();

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  bool _matches(Place place, String q) {
    return place.nameEn.toLowerCase().contains(q) ||
        place.nameAr.toLowerCase().contains(q) ||
        (place.address ?? '').toLowerCase().contains(q);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final media = MediaQuery.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final q = _query.text.trim().toLowerCase();
    final selectedId = widget.selected is ApprovedPlaceSelection
        ? (widget.selected! as ApprovedPlaceSelection).place.id
        : null;
    final visible = [
      for (final p in widget.places)
        if (!widget.excludePlaceIds.contains(p.id) && (q.isEmpty || _matches(p, q)))
          p,
    ];
    final animate = !AppAnimations.disabled(context);

    return Padding(
      padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
      child: SizedBox(
        height: media.size.height * 0.82,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.line,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(20, 14, 8, 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text(widget.title, style: theme.textTheme.titleLarge),
                  ),
                  IconButton(
                    tooltip: l10n.dialogCancel,
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                controller: _query,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  prefixIcon: const Icon(Icons.search_rounded),
                  suffixIcon: q.isEmpty
                      ? null
                      : IconButton(
                          tooltip: l10n.dialogCancel,
                          onPressed: () => setState(_query.clear),
                          icon: const Icon(Icons.close_rounded),
                        ),
                ),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                children: [
                  if (visible.isEmpty && widget.otherOptionLabel == null)
                    Padding(
                      padding: const EdgeInsets.all(32),
                      child: Text(
                        widget.searchHint,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ),
                  for (var i = 0; i < visible.length; i++)
                    _stagger(
                      animate,
                      i,
                      _PlaceRow(
                        place: visible[i],
                        languageCode: languageCode,
                        selected: visible[i].id == selectedId,
                        usable:
                            !widget.requireCoordinates ||
                            visible[i].hasCoordinates,
                        onTap: () {
                          final place = visible[i];
                          if (widget.requireCoordinates &&
                              !place.hasCoordinates) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.placeCannotSelectWithoutLocation,
                                ),
                              ),
                            );
                            return;
                          }
                          Navigator.of(
                            context,
                          ).pop(ApprovedPlaceSelection(place));
                        },
                      ),
                    ),
                  if (widget.otherOptionLabel != null) ...[
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                      child: Divider(height: 1),
                    ),
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.paleBlue,
                        foregroundColor: AppColors.deepBlue,
                        child: Icon(Icons.edit_location_alt_outlined),
                      ),
                      title: Text(widget.otherOptionLabel!),
                      trailing: widget.selected is CustomPlaceSelection
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.deepBlue,
                            )
                          : null,
                      onTap: () => Navigator.of(
                        context,
                      ).pop(const CustomPlaceSelection()),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stagger(bool animate, int i, Widget child) {
    if (!animate || i > 7) return child;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AppMotion.emphasized + AppMotion.staggerAt(i),
      curve: AppMotion.easeOut,
      builder: (context, v, child) => Opacity(
        opacity: v,
        child: Transform.translate(offset: Offset(0, 12 * (1 - v)), child: child),
      ),
      child: child,
    );
  }
}

class _PlaceRow extends StatelessWidget {
  const _PlaceRow({
    required this.place,
    required this.languageCode,
    required this.selected,
    required this.usable,
    required this.onTap,
  });

  final Place place;
  final String languageCode;
  final bool selected;
  final bool usable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final address = place.address?.trim();
    return Opacity(
      opacity: usable ? 1 : 0.55,
      child: ListTile(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        selected: selected,
        selectedTileColor: AppColors.paleBlue,
        leading: CircleAvatar(
          backgroundColor: selected ? AppColors.deepBlue : AppColors.paleBlue,
          foregroundColor: selected ? AppColors.white : AppColors.deepBlue,
          child: Icon(
            usable ? Icons.place_outlined : Icons.location_off_outlined,
          ),
        ),
        title: Text(
          place.displayName(languageCode),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: (address != null && address.isNotEmpty) || !usable
            ? Text(
                usable ? address! : l10n.noLocationBadge,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.inkMuted,
                ),
              )
            : null,
        trailing: selected
            ? const Icon(Icons.check_circle_rounded, color: AppColors.deepBlue)
            : null,
        onTap: onTap,
      ),
    );
  }
}
