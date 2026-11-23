import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/fleet_period_bar.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
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
                            Row(
                              children: [
                                Expanded(
                                  child: _StatTile(
                                    label: l10n.statsTrips,
                                    value: '${value.trips}',
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _StatTile(
                                    label: l10n.statsTime,
                                    value: formatHoursMinutes(
                                      value.totalSeconds,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: _StatTile(
                                    label: l10n.statsDistance,
                                    value: l10n.statsKmValue(
                                      formatKilometers(value.totalKm),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            Text(
                              l10n.statsTrips,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            DriverStatsChart(
                              period: value.period,
                              buckets: value.breakdown,
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

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.deepBlue.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
        child: Column(
          children: [
            Text(
              value,
              style: textTheme.titleMedium?.copyWith(
                color: AppColors.navy,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: textTheme.labelMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
