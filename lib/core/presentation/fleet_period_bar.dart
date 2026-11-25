import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/fleet_period_controller.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';
import 'package:teletech_drivers/core/time/fleet_period.dart';
import 'package:teletech_drivers/core/widgets/segmented_switch.dart';

/// Week / month / year (and all) control with previous and next arrows.
class FleetPeriodBar extends ConsumerWidget {
  const FleetPeriodBar({required this.provider, super.key});

  final NotifierProvider<FleetPeriodController, FleetPeriodAnchor> provider;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final anchor = ref.watch(provider);
    final controller = ref.read(provider.notifier);
    final allowed = controller.allowed;
    final locale = Localizations.localeOf(context).toString();
    final canNext = anchor.canGoForward(DateTime.now());

    final textTheme = Theme.of(context).textTheme;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final rangeLabel = _rangeLabel(anchor, l10n, locale);

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedSwitch<FleetPeriodKind>(
            options: [
              for (final kind in allowed)
                SegmentOption(value: kind, label: _kindLabel(kind, l10n)),
            ],
            selected: anchor.kind,
            onChanged: controller.select,
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              _StepButton(
                tooltip: l10n.periodPrevious,
                icon: Icons.chevron_left,
                onPressed: anchor.canShift ? controller.previous : null,
              ),
              Expanded(
                child: AnimatedSwitcher(
                  duration: reduceMotion ? Duration.zero : AppMotion.quick,
                  switchInCurve: AppMotion.easeOut,
                  switchOutCurve: AppMotion.easeOut,
                  transitionBuilder: (child, animation) => FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0, 0.25),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  ),
                  child: Text(
                    rangeLabel,
                    key: ValueKey(rangeLabel),
                    textAlign: TextAlign.center,
                    style: AppTypography.tabular(textTheme.titleSmall),
                  ),
                ),
              ),
              _StepButton(
                tooltip: l10n.periodNext,
                icon: Icons.chevron_right,
                onPressed: canNext ? controller.next : null,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Round previous / next stepper. Chevrons mirror automatically in RTL.
class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      style: IconButton.styleFrom(
        foregroundColor: AppColors.navy,
        disabledForegroundColor: AppColors.line,
      ),
      icon: Icon(icon),
    );
  }
}

String _kindLabel(FleetPeriodKind kind, AppLocalizations l10n) {
  return switch (kind) {
    FleetPeriodKind.week => l10n.periodWeek,
    FleetPeriodKind.month => l10n.periodMonth,
    FleetPeriodKind.year => l10n.periodYear,
    FleetPeriodKind.all => l10n.periodAll,
  };
}

String _rangeLabel(
  FleetPeriodAnchor anchor,
  AppLocalizations l10n,
  String locale,
) {
  if (anchor.kind == FleetPeriodKind.all) return l10n.periodAllTime;
  final bounds = anchor.bounds;
  return switch (anchor.kind) {
    FleetPeriodKind.week =>
      '${DateFormat.yMMMd(locale).format(bounds.start)} – ${DateFormat.yMMMd(locale).format(bounds.endInclusive)}',
    FleetPeriodKind.month => DateFormat.yMMMM(locale).format(bounds.start),
    FleetPeriodKind.year => DateFormat.y(locale).format(bounds.start),
    FleetPeriodKind.all => l10n.periodAllTime,
  };
}
