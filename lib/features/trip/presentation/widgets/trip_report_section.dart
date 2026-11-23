import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_report.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/utils/trip_report_formatters.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_report_route_map.dart';
import 'package:teletech_drivers/features/trip/presentation/widgets/trip_status_chip.dart';

/// Trip report card: stats grid + route map (Driver / Drivers Admin only).
///
/// The report itself is built by the server and loaded via [tripReportProvider].
class TripReportSection extends ConsumerWidget {
  const TripReportSection({required this.trip, super.key});

  final Trip trip;

  /// Whether this trip should show a report section.
  static bool shouldShow(Trip trip) {
    return trip.goingStartedAt != null ||
        trip.status.isInProgress ||
        trip.status == TripStatus.completed;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!shouldShow(trip)) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context);
    return ref
        .watch(tripReportProvider(trip.id))
        .when(
          loading: () => AppLoadingIndicator(label: l10n.loading),
          error: (error, _) => Text(
            messageForError(error, l10n),
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          data: (report) => _TripReportCard(report: report),
        );
  }
}

class _TripReportCard extends StatelessWidget {
  const _TripReportCard({required this.report});

  final TripReport report;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final locale = Localizations.localeOf(context).toString();

    return Card(
      elevation: 0,
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        side: BorderSide(color: AppColors.midBlue.withValues(alpha: 0.18)),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(14, 14, 14, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.tripReportTitle,
                    style: textTheme.titleMedium,
                  ),
                ),
                if (report.isInProgress)
                  StatusChip(
                    label: l10n.tripReportInProgress,
                    color: AppColors.warning,
                  )
                else
                  TripStatusChip(status: report.status),
              ],
            ),
            const SizedBox(height: 12),
            _StatsGrid(
              children: [
                _StatCell(
                  label: l10n.tripReportStartedAt,
                  value: TripReportFormatters.dateTime(
                    report.startedAt,
                    locale,
                  ),
                ),
                _StatCell(
                  label: l10n.tripReportFinishedAt,
                  value: TripReportFormatters.dateTime(
                    report.finishedAt,
                    locale,
                  ),
                ),
                _StatCell(
                  label: l10n.tripReportTotalDuration,
                  value: TripReportFormatters.duration(
                    report.totalDuration,
                    l10n,
                  ),
                ),
                _StatCell(
                  label: l10n.tripReportGoingDuration,
                  value: TripReportFormatters.duration(
                    report.goingDuration,
                    l10n,
                  ),
                ),
                _StatCell(
                  label: l10n.tripReportWaitingDuration,
                  value: TripReportFormatters.duration(
                    report.waitingDuration,
                    l10n,
                  ),
                ),
                _StatCell(
                  label: l10n.tripReportReturnDuration,
                  value: TripReportFormatters.duration(
                    report.returnDuration,
                    l10n,
                  ),
                ),
                _StatCell(
                  label: l10n.tripReportDistanceGoing,
                  value: TripReportFormatters.distanceKm(
                    report.goingDistanceKm,
                    l10n,
                  ),
                ),
                _StatCell(
                  label: l10n.tripReportDistanceReturn,
                  value: TripReportFormatters.distanceKm(
                    report.returnDistanceKm,
                    l10n,
                  ),
                ),
                _StatCell(
                  label: l10n.tripReportDistanceTotal,
                  value: TripReportFormatters.distanceKm(
                    report.totalDistanceKm,
                    l10n,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(l10n.tripReportRouteSection, style: textTheme.titleSmall),
            const SizedBox(height: 8),
            TripReportRouteMap(report: report),
            if (report.hasRouteGeometry) ...[
              const SizedBox(height: 8),
              _RouteLegend(l10n: l10n),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatsGrid extends StatelessWidget {
  const _StatsGrid({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 420;
        final columns = wide ? 3 : 2;
        return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final child in children)
              SizedBox(
                width: (constraints.maxWidth - (columns - 1) * 8) / columns,
                child: child,
              ),
          ],
        );
      },
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.paleBlue,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.fromSTEB(10, 10, 10, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: textTheme.labelSmall?.copyWith(
                color: AppColors.navy.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RouteLegend extends StatelessWidget {
  const _RouteLegend({required this.l10n});

  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Wrap(
      spacing: 16,
      runSpacing: 6,
      children: [
        _LegendItem(
          color: tripReportGoingRouteColor,
          label: l10n.tripReportGoingRouteLegend,
          style: textTheme.bodySmall,
        ),
        _LegendItem(
          color: tripReportReturnRouteColor,
          label: l10n.tripReportReturnRouteLegend,
          style: textTheme.bodySmall,
        ),
      ],
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.style,
  });

  final Color color;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 16,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: style),
      ],
    );
  }
}
