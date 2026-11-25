import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/surface_card.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip_status.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// Dashboard card: trips scheduled on each of the last seven days.
///
/// Read-only overview; hides itself if trips can't be loaded.
class TripsWeekChart extends ConsumerWidget {
  const TripsWeekChart({this.animateIndex, super.key});

  final int? animateIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final tripsAsync = ref.watch(allTripsProvider);
    return tripsAsync.when(
      skipLoadingOnRefresh: true,
      skipLoadingOnReload: true,
      loading: () => const SurfaceCard(
        child: SizedBox(
          height: 196,
          child: Center(child: SkeletonBox(width: 160, height: 16)),
        ),
      ),
      error: (_, _) => const SizedBox.shrink(),
      data: (trips) {
        final days = lastSevenDays(trips, DateTime.now());
        final total = days.fold<int>(0, (sum, day) => sum + day.count);
        return SurfaceCard(
          animateIndex: animateIndex,
          padding: const EdgeInsetsDirectional.fromSTEB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.adminTripsWeekTitle,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n.adminTripsWeekSubtitle,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: total.toDouble()),
                    duration: AppAnimations.duration(
                      context,
                      AppMotion.emphasized,
                    ),
                    curve: AppMotion.easeOut,
                    builder: (context, value, _) => Text(
                      value.round().toString(),
                      style: AppTypography.tabular(
                        Theme.of(context).textTheme.headlineMedium?.copyWith(
                          color: AppColors.navy,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(height: 140, child: _WeekBars(days: days)),
            ],
          ),
        );
      },
    );
  }

  /// Counts non-cancelled trips per local calendar day, oldest first,
  /// ending today.
  static List<({DateTime day, int count})> lastSevenDays(
    List<Trip> trips,
    DateTime now,
  ) {
    final today = DateTime(now.year, now.month, now.day);
    final counts = <DateTime, int>{
      for (var i = 6; i >= 0; i--) today.subtract(Duration(days: i)): 0,
    };
    for (final trip in trips) {
      if (trip.status == TripStatus.cancelled) continue;
      final local = trip.scheduledAt.toLocal();
      final key = DateTime(local.year, local.month, local.day);
      if (counts.containsKey(key)) counts[key] = counts[key]! + 1;
    }
    return [for (final e in counts.entries) (day: e.key, count: e.value)];
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.days});

  final List<({DateTime day, int count})> days;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final labelStyle = Theme.of(
      context,
    ).textTheme.labelSmall?.copyWith(color: AppColors.inkMuted);
    final maxCount = days.fold<int>(0, (m, d) => math.max(m, d.count));
    final maxY = math.max(maxCount, 1).toDouble();
    final reduceMotion = AppAnimations.disabled(context);

    return BarChart(
      duration: reduceMotion ? Duration.zero : const Duration(milliseconds: 450),
      curve: AppMotion.easeOut,
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
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
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= days.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    DateFormat.E(locale).format(days[index].day),
                    style: index == days.length - 1
                        ? labelStyle?.copyWith(
                            color: AppColors.deepBlue,
                            fontWeight: FontWeight.w700,
                          )
                        : labelStyle,
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var index = 0; index < days.length; index++)
            BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: days[index].count.toDouble(),
                  color: index == days.length - 1
                      ? AppColors.signal
                      : AppColors.deepBlue,
                  width: 16,
                  borderRadius: BorderRadius.circular(8),
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
    );
  }
}
