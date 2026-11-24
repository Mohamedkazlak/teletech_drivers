import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';
import 'package:teletech_drivers/features/driver_stats/domain/entities/stats_bucket.dart';
import 'package:teletech_drivers/features/driver_stats/presentation/stats_chart_label.dart';

/// Bar chart of trips per stats bucket.
class DriverStatsChart extends StatelessWidget {
  const DriverStatsChart({
    required this.period,
    required this.buckets,
    super.key,
  });

  final String period;
  final List<StatsBucket> buckets;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final hasTrips = buckets.any((bucket) => bucket.trips > 0);
    if (buckets.isEmpty || !hasTrips) {
      return SizedBox(
        height: 220,
        child: EmptyState(
          icon: Icons.insights_rounded,
          title: l10n.driverTripsEmptyTitle,
          message: l10n.statsChartEmpty,
        ),
      );
    }
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted);
    final reduceMotion = AppAnimations.disabled(context);

    final locale = Localizations.localeOf(context).toString();
    final labels = [
      for (final bucket in buckets)
        statsChartLabel(
          period: period,
          bucketLabel: bucket.label,
          localeName: locale,
        ),
    ];
    final maxTrips = buckets.fold<int>(
      0,
      (max, bucket) => math.max(max, bucket.trips),
    );
    final maxY = (maxTrips == 0 ? 1 : maxTrips).toDouble();

    return SizedBox(
      height: 220,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = math.max(constraints.maxWidth, buckets.length * 36.0);
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: width,
              child: BarChart(
                duration: reduceMotion
                    ? Duration.zero
                    : const Duration(milliseconds: 450),
                curve: AppMotion.easeOut,
                BarChartData(
                  maxY: maxY,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipColor: (_) => AppColors.navy,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        return BarTooltipItem(
                          rod.toY.toInt().toString(),
                          AppTypography.tabular(
                                Theme.of(context).textTheme.labelLarge,
                              )?.copyWith(color: AppColors.white) ??
                              const TextStyle(color: AppColors.white),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    drawVerticalLine: false,
                    horizontalInterval: maxY <= 5 ? 1 : null,
                    getDrawingHorizontalLine: (_) => const FlLine(
                      color: AppColors.line,
                      strokeWidth: 1,
                      dashArray: [4, 4],
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: maxY <= 5 ? 1 : null,
                        getTitlesWidget: (value, meta) {
                          if (value != value.roundToDouble()) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            value.toInt().toString(),
                            style: AppTypography.tabular(labelStyle),
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(labels[index], style: labelStyle),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var index = 0; index < buckets.length; index++)
                      BarChartGroupData(
                        x: index,
                        barRods: [
                          BarChartRodData(
                            toY: buckets[index].trips.toDouble(),
                            color: AppColors.deepBlue,
                            width: 14,
                            borderRadius: BorderRadius.circular(7),
                            backDrawRodData: BackgroundBarChartRodData(
                              show: true,
                              toY: maxY,
                              color: AppColors.paleBlue,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
