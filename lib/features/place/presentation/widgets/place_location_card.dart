import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/features/place/domain/entities/picked_location.dart';
import 'package:teletech_drivers/features/place/presentation/screens/location_picker_screen.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_preview_map.dart';

/// Location step of the place form: one calm card that is either an invitation
/// to choose a spot, or a map preview of the spot already chosen.
///
/// Choosing opens the full-screen picker (search, drag the map, address
/// lookup), so the form itself stays short.
class PlaceLocationCard extends StatelessWidget {
  const PlaceLocationCard({
    required this.latitude,
    required this.longitude,
    required this.address,
    required this.enabled,
    required this.onPicked,
    required this.onClear,
    super.key,
  });

  final double? latitude;
  final double? longitude;
  final String? address;
  final bool enabled;
  final ValueChanged<PickedLocation> onPicked;
  final VoidCallback onClear;

  bool get _has => latitude != null && longitude != null;

  Future<void> _choose(BuildContext context) async {
    final picked = await LocationPickerScreen.open(
      context,
      initialLocation: _has
          ? PickedLocation(
              lat: latitude!,
              lng: longitude!,
              address: address,
            )
          : null,
    );
    if (picked != null) onPicked(picked);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return AnimatedSwitcher(
      duration: AppAnimations.duration(context, AppMotion.emphasized),
      switchInCurve: AppMotion.easeOut,
      switchOutCurve: AppMotion.easeOut,
      transitionBuilder: (child, animation) => FadeTransition(
        opacity: animation,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.96, end: 1).animate(animation),
          child: child,
        ),
      ),
      child: _has
          ? Container(
              key: const ValueKey('set'),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  PlacePreviewMap(
                    latitude: latitude!,
                    longitude: longitude!,
                    height: 168,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(
                              Icons.check_circle_rounded,
                              color: AppColors.success,
                              size: 18,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              l10n.placeLocationSetTitle,
                              style: theme.textTheme.titleSmall,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          (address != null && address!.trim().isNotEmpty)
                              ? address!
                              : '${latitude!.toStringAsFixed(5)}, '
                                    '${longitude!.toStringAsFixed(5)}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: AppColors.inkMuted,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: AppButton(
                                label: l10n.placeChangeLocation,
                                icon: Icons.edit_location_alt_outlined,
                                variant: AppButtonVariant.tonal,
                                onPressed: enabled
                                    ? () => _choose(context)
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton.filledTonal(
                              tooltip: l10n.clearPlaceLocation,
                              onPressed: enabled ? onClear : null,
                              icon: const Icon(Icons.location_off_outlined),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          : Container(
              key: const ValueKey('empty'),
              padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.line),
              ),
              child: Column(
                children: [
                  const _PinBadge(),
                  const SizedBox(height: 18),
                  Text(
                    l10n.placeLocationEmptyTitle,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    l10n.placeLocationEmptyBody,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: AppColors.inkMuted,
                      height: 1.45,
                    ),
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: l10n.placeChooseOnMap,
                    icon: Icons.map_outlined,
                    pulse: true,
                    onPressed: enabled ? () => _choose(context) : null,
                  ),
                ],
              ),
            ),
    );
  }
}

/// A pin that gently bobs over a pulsing ring.
class _PinBadge extends StatefulWidget {
  const _PinBadge();

  @override
  State<_PinBadge> createState() => _PinBadgeState();
}

class _PinBadgeState extends State<_PinBadge>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AppAnimations.disabled(context)) {
      _c.stop();
    } else if (!_c.isAnimating) {
      _c.repeat();
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(
      dimension: 96,
      child: AnimatedBuilder(
        animation: _c,
        builder: (context, _) {
          final t = _c.value;
          final ring = Curves.easeOut.transform(t);
          final bob = -6 * (0.5 - (t - 0.5).abs()) * 2;
          return Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 56 + 40 * ring,
                height: 56 + 40 * ring,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.signal.withValues(alpha: 0.5 * (1 - ring)),
                    width: 2,
                  ),
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.paleBlue,
                ),
              ),
              Transform.translate(
                offset: Offset(0, bob),
                child: const Icon(
                  Icons.place_rounded,
                  size: 32,
                  color: AppColors.deepBlue,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
