import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';

/// One option of a [SegmentedSwitch].
class SegmentOption<T> {
  const SegmentOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Pill switch with a sliding navy thumb (week / month / year, …).
///
/// Equal-width segments; the thumb glides with [AppMotion.easeInOut] and the
/// labels cross-fade their colour. Direction-aware, so the thumb moves the
/// right way in Arabic.
class SegmentedSwitch<T> extends StatelessWidget {
  const SegmentedSwitch({
    required this.options,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final List<SegmentOption<T>> options;
  final T selected;
  final ValueChanged<T> onChanged;

  static const double height = 40;

  @override
  Widget build(BuildContext context) {
    final count = options.length;
    final index = options.indexWhere((o) => o.value == selected);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final duration = reduceMotion ? Duration.zero : AppMotion.standard;
    final labelStyle = Theme.of(context).textTheme.labelLarge;

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(height / 2),
        border: Border.all(color: AppColors.line),
      ),
      child: Stack(
        children: [
          if (index >= 0 && count > 0)
            Positioned.fill(
              child: AnimatedAlign(
                duration: duration,
                curve: AppMotion.easeInOut,
                alignment: AlignmentDirectional(
                  count == 1 ? 0 : -1 + 2 * index / (count - 1),
                  0,
                ),
                child: FractionallySizedBox(
                  widthFactor: 1 / count,
                  heightFactor: 1,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.navy,
                      borderRadius: BorderRadius.circular(height / 2),
                    ),
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (var i = 0; i < count; i++)
                Expanded(
                  child: Semantics(
                    button: true,
                    selected: i == index,
                    child: GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () {
                        if (i == index) return;
                        HapticFeedback.selectionClick();
                        onChanged(options[i].value);
                      },
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: AnimatedDefaultTextStyle(
                            duration: duration,
                            curve: AppMotion.easeOut,
                            style: (labelStyle ?? const TextStyle()).copyWith(
                              color: i == index
                                  ? AppColors.white
                                  : AppColors.inkMuted,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(options[i].label, maxLines: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
