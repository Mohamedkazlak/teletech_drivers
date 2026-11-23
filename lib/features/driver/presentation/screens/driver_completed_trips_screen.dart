import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/presentation/fleet_period_bar.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:teletech_drivers/features/driver/presentation/providers/driver_period_providers.dart';
import 'package:teletech_drivers/features/driver/presentation/widgets/driver_period_trip_list.dart';
import 'package:teletech_drivers/features/trip/domain/entities/mine_trips_filter.dart';

/// Completed trips for the selected week, month, or year.
class DriverCompletedTripsScreen extends ConsumerWidget {
  const DriverCompletedTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final anchor = ref.watch(completedTripsPeriodProvider);
    final date = anchor.apiDate;

    return AppScaffold(
      title: l10n.navCompletedTrips,
      actions: const [
        LanguageToggleButton(),
        SignOutButton(style: SignOutButtonStyle.icon),
      ],
      body: user == null || date == null
          ? Center(child: Text(l10n.homeEmpty))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FleetPeriodBar(provider: completedTripsPeriodProvider),
                Expanded(
                  child: DriverPeriodTripList(
                    filter: MineTripsFilter(
                      status: MineTripStatuses.completed,
                      period: anchor.apiPeriod,
                      date: date,
                    ),
                    emptyMessage: l10n.completedTripsEmptyMessage,
                    showActions: false,
                    showMetrics: true,
                  ),
                ),
              ],
            ),
    );
  }
}
