import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/fleet_period_bar.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/theme/app_gradients.dart';
import 'package:teletech_drivers/core/theme/app_motion.dart';
import 'package:teletech_drivers/core/theme/app_typography.dart';
import 'package:teletech_drivers/core/widgets/animation_helpers.dart';
import 'package:teletech_drivers/core/widgets/brand_mark.dart';
import 'package:teletech_drivers/core/theme/app_theme.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/utils/measurement_format.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/list_failure_view.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:teletech_drivers/features/driver_stats/presentation/providers/driver_stats_providers.dart';
import 'package:teletech_drivers/features/driver_stats/presentation/widgets/driver_stats_chart.dart';

/// Driver stats: period, summary tiles, and a trips-per-bucket bar chart.
class DriverStatsScreen extends ConsumerWidget {
  const DriverStatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final stats = ref.watch(driverStatsProvider);

    return AppScaffold(
      title: l10n.navStats,
      actions: const [
        LanguageToggleButton(),
        SignOutButton(style: SignOutButtonStyle.icon),
      ],
      body: user == null
          ? Center(child: Text(l10n.homeEmpty))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FleetPeriodBar(provider: driverStatsPeriodProvider),
                Expanded(
                  child: stats.when(
                    loading: () => Center(
                      child: AppLoadingIndicator(label: l10n.loading),
                    ),
                    error: (error, _) => ListFailureView(
                      message: messageForError(error, l10n),
                      onRetry: () => ref.invalidate(driverStatsProvider),
                    ),
                    data: (value) {
                      return RefreshIndicator(
                        onRefresh: () async {
                          ref.invalidate(driverStatsProvider);
                          try {
                            await ref.read(driverStatsProvider.future);
                          } on Object {
                            // The error view replaces this body.
                          }
                        },
                        child: ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: GlassBarInset.listPadding(
                            context,
                            const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 24),
                          ),
                          children: [
                            _StatsSummary(
                              trips: value.trips,
                              tiles: [
                                (
                                  label: l10n.statsTime,
                                  value: formatHoursMinutes(value.totalSeconds),
                                  icon: Icons.schedule_rounded,
                                ),
                                (
                                  label: l10n.statsDistance,
                                  value: l10n.statsKmValue(
                                    formatKilometers(value.totalKm),
                                  ),
                                  icon: Icons.straighten_rounded,
                                ),
                              ],
                              tripsLabel: l10n.statsTrips,
                            ),
                            const SizedBox(height: 16),
                            DecoratedBox(
                              decoration: BoxDecoration(
                                color: AppColors.white,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.cardRadius,
                                ),
                                border: Border.all(color: AppColors.line),
                              ),
                              child: Padding(
                                padding: const EdgeInsetsDirectional.fromSTEB(
                                  16,
                                  16,
                                  16,
                                  8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      l10n.statsTrips,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                    const SizedBox(height: 12),
                                    DriverStatsChart(
                                      period: value.period,
                                      buckets: value.breakdown,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}

typedef _Tile = ({String label, String value, IconData icon});

/// One hero number (trips) on the dark surface, with time and distance beside.
class _StatsSummary extends StatelessWidget {
  const _StatsSummary({
    required this.trips,
    required this.tripsLabel,
    required this.tiles,
  });

  final int trips;
  final String tripsLabel;
  final List<_Tile> tiles;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final muted = AppColors.white.withValues(alpha: 0.68);
    final countDuration = AppAnimations.duration(
      context,
      const Duration(milliseconds: 700),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.primary,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppTheme.floatingShadow(opacity: 0.16),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          const Positioned.fill(child: RingField()),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tripsLabel,
                        style: textTheme.labelLarge?.copyWith(color: muted),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: trips.toDouble()),
                        duration: countDuration,
                        curve: AppMotion.easeOut,
                        builder: (context, value, _) => Text(
                          value.round().toString(),
                          style: AppTypography.tabular(
                            textTheme.displayMedium?.copyWith(
                              color: AppColors.white,
                              fontWeight: FontWeight.w600,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    for (final tile in tiles) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(tile.icon, size: 16, color: muted),
                          const SizedBox(width: 6),
                          Text(
                            tile.value,
                            style: AppTypography.tabular(
                              textTheme.titleMedium?.copyWith(
                                color: AppColors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        tile.label,
                        style: textTheme.labelSmall?.copyWith(color: muted),
                      ),
                      if (tile != tiles.last) const SizedBox(height: 10),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
