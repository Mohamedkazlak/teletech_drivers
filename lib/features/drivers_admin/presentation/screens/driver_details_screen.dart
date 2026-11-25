import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:teletech_drivers/core/widgets/success_moment.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/fleet_period_bar.dart';
import 'package:teletech_drivers/core/utils/measurement_format.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/status_chip.dart';
import 'package:teletech_drivers/features/attendance/presentation/widgets/driver_attendance_panel.dart';
import 'package:teletech_drivers/features/driver_stats/presentation/providers/driver_stats_providers.dart';
import 'package:teletech_drivers/features/driver_stats/presentation/widgets/driver_stats_chart.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_completed_trip.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_totals.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/edit_driver_dialog.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip_request/domain/entities/trip_confirmation_status.dart';

/// Full driver details including unmasked national ID and licenses.
class DriverDetailsScreen extends ConsumerWidget {
  const DriverDetailsScreen({required this.driverId, super.key});

  final String driverId;

  Future<void> _edit(
    BuildContext context,
    WidgetRef ref,
    DriverProfile driver,
  ) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await EditDriverDialog.show(context, driver: driver);
    if (!context.mounted || succeeded != true) return;
    ref.invalidate(driverProfileProvider(driverId));
    await showSuccessMoment(context, message: l10n.driverUpdated);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final profileAsync = ref.watch(driverProfileProvider(driverId));

    return AppScaffold(
      title: l10n.driverDetailsTitle,
      showBackButton: true,
      actions: [
        if (profileAsync case AsyncData(:final value))
          IconButton(
            tooltip: l10n.editDriver,
            onPressed: () => _edit(context, ref, value),
            icon: const Icon(Icons.edit_outlined),
          ),
      ],
      body: profileAsync.when(
        loading: () => Center(child: AppLoadingIndicator(label: l10n.loading)),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              messageForError(error, l10n),
              style: Theme.of(context).textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
          ),
        ),
        data: (driver) => _DriverDetailsBody(driver: driver),
      ),
    );
  }
}

class _DriverDetailsBody extends ConsumerWidget {
  const _DriverDetailsBody({required this.driver});

  final DriverProfile driver;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final textTheme = Theme.of(context).textTheme;
    final languageCode = Localizations.localeOf(context).languageCode;
    final statusLabel = driver.isActive
        ? l10n.driverStatusActive
        : l10n.driverStatusInactive;
    final places = ref.watch(activePlacesProvider).asData?.value ?? const [];
    final favoriteLabel = driver.favoritePlaceIds.isEmpty
        ? l10n.driverFavoritePlacesEmpty
        : driver.favoritePlaceIds
              .map((id) {
                for (final place in places) {
                  if (place.id == id) return place.displayName(languageCode);
                }
                return id;
              })
              .join(', ');

    return ListView(
      padding: const EdgeInsetsDirectional.fromSTEB(16, 12, 16, 24),
      children: [
        Text(
          driver.localizedName(languageCode),
          style: textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(statusLabel, style: textTheme.bodyMedium),
        const SizedBox(height: 20),
        _DetailRow(label: l10n.driverNameEnLabel, value: driver.nameEn),
        _DetailRow(label: l10n.driverNameArLabel, value: driver.nameAr),
        _DetailRow(label: l10n.emailLabel, value: driver.email),
        _DetailRow(label: l10n.phoneLabel, value: driver.phone),
        _DetailRow(label: l10n.nationalIdLabel, value: driver.nationalId),
        _DetailRow(label: l10n.carLicenseLabel, value: driver.carLicense),
        _DetailRow(
          label: l10n.personalLicenseLabel,
          value: driver.personalLicense,
        ),
        _DetailRow(label: l10n.favoritePlacesLabel, value: favoriteLabel),
        if (driver.totals != null) ...[
          const SizedBox(height: 8),
          _TotalsRow(l10n: l10n, totals: driver.totals!),
        ],
        const SizedBox(height: 12),
        FleetPeriodBar(provider: adminDriverPeriodProvider(driver.id)),
        const SizedBox(height: 8),
        _DriverStatsSection(driverId: driver.id),
        const SizedBox(height: 16),
        DriverAttendancePanel(driverId: driver.id),
        const SizedBox(height: 16),
        Text(l10n.navTrips, style: textTheme.titleMedium),
        const SizedBox(height: 8),
        _DriverTripsSection(driverId: driver.id),
      ],
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.l10n, required this.totals});

  final AppLocalizations l10n;
  final DriverTotals totals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatTile(label: l10n.statsTrips, value: '${totals.trips}'),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: l10n.statsTime,
            value: formatHoursMinutes(totals.totalSeconds),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _StatTile(
            label: l10n.statsDistance,
            value: l10n.statsKmValue(formatKilometers(totals.totalKm)),
          ),
        ),
      ],
    );
  }
}

class _DriverStatsSection extends ConsumerWidget {
  const _DriverStatsSection({required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final stats = ref.watch(adminDriverStatsProvider(driverId));
    return stats.when(
      loading: () => AppLoadingIndicator(label: l10n.loading),
      error: (error, _) => Text(messageForError(error, l10n)),
      data: (value) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                  value: formatHoursMinutes(value.totalSeconds),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _StatTile(
                  label: l10n.statsDistance,
                  value: l10n.statsKmValue(formatKilometers(value.totalKm)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          DriverStatsChart(period: value.period, buckets: value.breakdown),
        ],
      ),
    );
  }
}

class _DriverTripsSection extends ConsumerWidget {
  const _DriverTripsSection({required this.driverId});

  final String driverId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final trips = ref.watch(adminDriverTripsProvider(driverId));
    return trips.when(
      loading: () => AppLoadingIndicator(label: l10n.loading),
      error: (error, _) => Text(messageForError(error, l10n)),
      data: (items) {
        if (items.isEmpty) return Text(l10n.statsChartEmpty);
        final locale = Localizations.localeOf(context).toString();
        final format = DateFormat.yMMMd(locale).add_jm();
        return Column(
          children: [
            for (final trip in items) ...[
              _CompletedTripTile(trip: trip, format: format, l10n: l10n),
              const Divider(height: 1),
            ],
          ],
        );
      },
    );
  }
}

class _CompletedTripTile extends StatelessWidget {
  const _CompletedTripTile({
    required this.trip,
    required this.format,
    required this.l10n,
  });

  final DriverCompletedTrip trip;
  final DateFormat format;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final status = trip.confirmationStatus;
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('${trip.pickupSummary} → ${trip.destinationSummary}'),
      subtitle: Text(format.format(trip.scheduledAt.toLocal())),
      trailing: status == null && trip.driverShowedUp != false
          ? null
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (status != null)
                  Text(switch (status) {
                    TripConfirmationStatus.pending => l10n.confirmationPending,
                    TripConfirmationStatus.confirmed =>
                      l10n.confirmationConfirmed,
                    TripConfirmationStatus.unconfirmed =>
                      l10n.confirmationUnconfirmed,
                  }, style: Theme.of(context).textTheme.labelSmall),
                if (trip.driverShowedUp == false)
                  StatusChip(
                    label: l10n.driverDidNotShow,
                    color: AppColors.error,
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
    return Column(
      children: [
        Text(value, style: Theme.of(context).textTheme.titleMedium),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(value.isEmpty ? '—' : value, style: textTheme.bodyLarge),
        ],
      ),
    );
  }
}
