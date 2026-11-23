import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/fleet_period_controller.dart';
import 'package:teletech_drivers/core/time/fleet_period.dart';

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

    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final kind in allowed)
                ChoiceChip(
                  label: Text(_kindLabel(kind, l10n)),
                  selected: anchor.kind == kind,
                  onSelected: (_) => controller.select(kind),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              IconButton(
                tooltip: l10n.periodPrevious,
                onPressed: anchor.canShift ? controller.previous : null,
                icon: const Icon(Icons.arrow_back),
              ),
              Expanded(
                child: Text(
                  _rangeLabel(anchor, l10n, locale),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              IconButton(
                tooltip: l10n.periodNext,
                onPressed: canNext ? controller.next : null,
                icon: const Icon(Icons.arrow_forward),
              ),
            ],
          ),
        ],
      ),
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
