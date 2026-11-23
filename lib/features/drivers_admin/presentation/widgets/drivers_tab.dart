import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_attendance_filter.dart';
import 'package:teletech_drivers/features/trip/domain/services/driver_trip_activity.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/driver_activation_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/fix_legacy_drivers_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/add_driver_dialog.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/driver_attendance_filter_bar.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/driver_list_tile.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/drivers_empty_state.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/edit_driver_dialog.dart';
import 'package:teletech_drivers/features/trip/domain/entities/trip.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// Drivers admin tab: list, edit, details, activate/deactivate, and add.
class DriversTab extends ConsumerStatefulWidget {
  const DriversTab({super.key});

  @override
  ConsumerState<DriversTab> createState() => _DriversTabState();
}

class _DriversTabState extends ConsumerState<DriversTab> {
  DriverAttendanceFilter? _filter;

  Future<void> _openAddForm(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await AddDriverDialog.show(context);
    if (!context.mounted || succeeded != true) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.driverCreated)));
  }

  Future<void> _openEditForm(BuildContext context, DriverProfile driver) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await EditDriverDialog.show(context, driver: driver);
    if (!context.mounted || succeeded != true) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.driverUpdated)));
  }

  Future<void> _confirmFixLegacy(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.fixLegacyDriversConfirmTitle),
          content: Text(l10n.fixLegacyDriversConfirmMessage),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.fixLegacyDriversConfirmAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final updatedCount = await ref
        .read(fixLegacyDriversControllerProvider.notifier)
        .run();
    if (!context.mounted || updatedCount == null) return;

    final message = updatedCount == 0
        ? l10n.fixLegacyDriversNone
        : l10n.fixLegacyDriversSuccess(updatedCount);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Widget _fixLegacyAction({
    required BuildContext context,
    required WidgetRef ref,
    required AppLocalizations l10n,
    required bool isLoading,
  }) {
    return TextButton.icon(
      onPressed: isLoading ? null : () => _confirmFixLegacy(context, ref),
      icon: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.auto_fix_high_outlined),
      label: Text(l10n.fixLegacyDrivers),
    );
  }

  bool _driverOnTrip(String driverId, List<Trip>? trips) {
    if (trips == null) return false;
    return driverHasActiveTrip(driverId: driverId, trips: trips);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final drivers = ref.watch(driverProfilesByAttendanceProvider(_filter));
    final trips = ref.watch(allTripsProvider).asData?.value;
    final activationState = ref.watch(driverActivationControllerProvider);
    final fixLegacyState = ref.watch(fixLegacyDriversControllerProvider);

    ref.listen(driverActivationControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || identical(previous?.failure, failure)) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    });

    ref.listen(fixLegacyDriversControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || identical(previous?.failure, failure)) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    });

    return drivers.when(
      loading: () => Center(child: AppLoadingIndicator(label: l10n.loading)),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                messageForError(error, l10n),
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () =>
                    ref.invalidate(driverProfilesByAttendanceProvider(_filter)),
                child: Text(l10n.tryAgain),
              ),
              const SizedBox(height: 8),
              _fixLegacyAction(
                context: context,
                ref: ref,
                l10n: l10n,
                isLoading: fixLegacyState.isLoading,
              ),
            ],
          ),
        ),
      ),
      data: (items) {
        return Column(
          children: [
            DriverAttendanceFilterBar(
              selected: _filter,
              onChanged: (value) => setState(() => _filter = value),
            ),
            Align(
              alignment: AlignmentDirectional.centerEnd,
              child: Padding(
                padding: const EdgeInsetsDirectional.fromSTEB(8, 0, 8, 0),
                child: _fixLegacyAction(
                  context: context,
                  ref: ref,
                  l10n: l10n,
                  isLoading: fixLegacyState.isLoading,
                ),
              ),
            ),
            Expanded(
              child: items.isEmpty
                  ? (_filter == null
                        ? DriversEmptyState(
                            onAddDriver: () => _openAddForm(context),
                          )
                        : const _EmptyFilterState())
                  : ListView.separated(
                      padding: GlassBarInset.listPadding(
                        context,
                        const EdgeInsetsDirectional.fromSTEB(0, 8, 0, 88),
                      ),
                      itemCount: items.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final driver = items[index];
                        final isToggling =
                            activationState.isLoading &&
                            activationState.activeDriverId == driver.id;

                        return DriverListTile(
                          driver: driver,
                          onTrip: _driverOnTrip(driver.id, trips),
                          isToggling: isToggling,
                          onEdit: () => _openEditForm(context, driver),
                          onOpenDetails: () {
                            context.push(
                              AppRoutes.driversAdminDriverDetailsPath(
                                driver.id,
                              ),
                            );
                          },
                          onActiveChanged: (isActive) {
                            ref
                                .read(
                                  driverActivationControllerProvider.notifier,
                                )
                                .setActive(
                                  driverId: driver.id,
                                  isActive: isActive,
                                );
                          },
                        );
                      },
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Text(
          l10n.attendanceFilterEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ),
    );
  }
}
