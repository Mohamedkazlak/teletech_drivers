import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/widgets/search_field.dart';
import 'package:teletech_drivers/core/widgets/brand_refresh.dart';
import 'package:teletech_drivers/core/widgets/swipe_actions.dart';
import 'package:teletech_drivers/core/widgets/success_moment.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/surface_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';
import 'package:teletech_drivers/features/admin/presentation/controllers/driver_soft_delete_controller.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/domain/entities/driver_profile.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/controllers/driver_activation_controller.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/add_driver_dialog.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/edit_driver_dialog.dart';

enum _ActiveFilter { all, active, inactive }

/// Admin drivers list: search, active filter, CRUD + soft delete.
class AdminDriversScreen extends ConsumerStatefulWidget {
  const AdminDriversScreen({super.key});

  @override
  ConsumerState<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends ConsumerState<AdminDriversScreen> {
  final _searchController = TextEditingController();
  _ActiveFilter _filter = _ActiveFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<DriverProfile> _filtered(List<DriverProfile> items) {
    final query = _searchController.text.trim().toLowerCase();
    return [
      for (final driver in items)
        if (_matchesFilter(driver) && _matchesQuery(driver, query)) driver,
    ];
  }

  bool _matchesFilter(DriverProfile driver) {
    return switch (_filter) {
      _ActiveFilter.all => true,
      _ActiveFilter.active => driver.isActive,
      _ActiveFilter.inactive => !driver.isActive,
    };
  }

  bool _matchesQuery(DriverProfile driver, String query) {
    if (query.isEmpty) return true;
    return driver.nameEn.toLowerCase().contains(query) ||
        driver.nameAr.toLowerCase().contains(query) ||
        driver.email.toLowerCase().contains(query) ||
        driver.phone.toLowerCase().contains(query);
  }

  Future<void> _openAdd(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await AddDriverDialog.show(context);
    if (!context.mounted || succeeded != true) return;
    await showSuccessMoment(context, message: l10n.driverCreated);
  }

  Future<void> _openEdit(BuildContext context, DriverProfile driver) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await EditDriverDialog.show(context, driver: driver);
    if (!context.mounted || succeeded != true) return;
    await showSuccessMoment(context, message: l10n.driverUpdated);
  }

  Future<void> _confirmSoftDelete(
    BuildContext context,
    DriverProfile driver,
  ) async {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final name = languageCode == 'ar' ? driver.nameAr : driver.nameEn;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.adminSoftDeleteConfirmTitle),
          content: Text(l10n.adminSoftDeleteDriverMessage(name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.adminSoftDeleteAction),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final uid = ref.read(currentUserProvider).asData?.value?.id;
    if (uid == null) return;

    final succeeded = await ref
        .read(driverSoftDeleteControllerProvider.notifier)
        .softDelete(driverId: driver.id, deletedBy: uid);
    if (!context.mounted || !succeeded) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminSoftDeleteSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final driversAsync = ref.watch(allDriverProfilesProvider);

    ref.listen(driverSoftDeleteControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || identical(previous?.failure, failure)) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    });

    return AppScaffold(
      title: l10n.adminDriversSection,
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin-add-driver',
        tooltip: l10n.addDriver,
        onPressed: () => _openAdd(context),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.adminSearchHint,
              onChanged: (_) => setState(() {}),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Row(
              children: [
                for (final entry in [
                  (_ActiveFilter.all, l10n.adminFilterAll),
                  (_ActiveFilter.active, l10n.adminFilterActive),
                  (_ActiveFilter.inactive, l10n.adminFilterInactive),
                ]) ...[
                  if (entry.$1 != _ActiveFilter.all) const SizedBox(width: 8),
                  FilterChip(
                    label: Text(entry.$2),
                    selected: _filter == entry.$1,
                    onSelected: (_) => setState(() => _filter = entry.$1),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: driversAsync.when(
              loading: () => PeopleListSkeleton(label: l10n.loading),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    messageForError(error, l10n),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (drivers) {
                final filtered = _filtered(drivers);
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: l10n.adminDriversEmptyTitle,
                    message: l10n.adminDriversEmptyMessage,
                    icon: Icons.local_taxi_outlined,
                  );
                }
                return BrandRefresh(
                  onRefresh: () async {
                    ref.invalidate(allDriverProfilesProvider);
                    try {
                      await ref.read(allDriverProfilesProvider.future);
                    } on Object {
                      // The error view replaces the list.
                    }
                  },
                  child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final driver = filtered[index];
                    final name = languageCode == 'ar'
                        ? driver.nameAr
                        : driver.nameEn;
                    return SwipeActions(
                      itemKey: ValueKey(driver.id),
                      editLabel: l10n.editDriver,
                      onEdit: () => _openEdit(context, driver),
                      destructiveLabel: l10n.adminSoftDeleteAction,
                      onDestructive: driver.isActive
                          ? () => _confirmSoftDelete(context, driver)
                          : null,
                      child: SurfaceCard(
                      animateIndex: index,
                      child: ListTile(
                      contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 8, 4, 8),
                      leading: InitialsAvatar(
                        name: name,
                        statusColor: driver.isActive ? AppColors.success : AppColors.inkMuted,
                      ),
                      title: Text(name),
                      subtitle: Text(
                        '${driver.email}\n'
                        '${[driver.phone, driver.isActive ? l10n.adminFilterActive : l10n.adminFilterInactive].where((part) => part.trim().isNotEmpty).join(' · ')}',
                      ),
                      isThreeLine: true,
                      onTap: () => context.push(
                        AppRoutes.adminDriverDetailsPath(driver.id),
                      ),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              await _openEdit(context, driver);
                            case 'delete':
                              await _confirmSoftDelete(context, driver);
                            case 'activate':
                              await ref
                                  .read(
                                    driverActivationControllerProvider.notifier,
                                  )
                                  .setActive(
                                    driverId: driver.id,
                                    isActive: true,
                                  );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.editDriver),
                          ),
                          if (!driver.isActive)
                            PopupMenuItem(
                              value: 'activate',
                              child: Text(l10n.adminReactivateAction),
                            ),
                          if (driver.isActive)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.adminSoftDeleteAction),
                            ),
                        ],
                      ),
                    ),
                    ),
                    );
                  },
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
