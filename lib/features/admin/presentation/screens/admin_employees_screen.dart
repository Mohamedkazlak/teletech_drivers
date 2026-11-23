import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';
import 'package:teletech_drivers/features/admin/presentation/controllers/employee_activation_controller.dart';
import 'package:teletech_drivers/features/admin/presentation/controllers/employee_soft_delete_controller.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/employee_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/widgets/employee_form_dialog.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/branch.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';

enum _ActiveFilter { all, active, inactive }

/// Admin employees list: search, active + branch filters, CRUD + soft delete.
class AdminEmployeesScreen extends ConsumerStatefulWidget {
  const AdminEmployeesScreen({super.key});

  @override
  ConsumerState<AdminEmployeesScreen> createState() =>
      _AdminEmployeesScreenState();
}

class _AdminEmployeesScreenState extends ConsumerState<AdminEmployeesScreen> {
  final _searchController = TextEditingController();
  _ActiveFilter _activeFilter = _ActiveFilter.all;
  Branch? _branchFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _filtered(List<AppUser> items) {
    final query = _searchController.text.trim().toLowerCase();
    final languageCode = Localizations.localeOf(context).languageCode;
    return [
      for (final employee in items)
        if (_matchesActive(employee) &&
            _matchesBranch(employee) &&
            _matchesQuery(employee, query, languageCode))
          employee,
    ];
  }

  bool _matchesActive(AppUser employee) {
    return switch (_activeFilter) {
      _ActiveFilter.all => true,
      _ActiveFilter.active => employee.isActive,
      _ActiveFilter.inactive => !employee.isActive,
    };
  }

  bool _matchesBranch(AppUser employee) {
    final filter = _branchFilter;
    if (filter == null) return true;
    return employee.branch == filter;
  }

  bool _matchesQuery(AppUser employee, String query, String languageCode) {
    if (query.isEmpty) return true;
    final name = employee.localizedName(languageCode).toLowerCase();
    return name.contains(query) ||
        employee.email.toLowerCase().contains(query) ||
        (employee.phone?.toLowerCase().contains(query) ?? false);
  }

  Future<void> _openForm(BuildContext context, {AppUser? employee}) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await EmployeeFormDialog.show(
      context,
      employee: employee,
    );
    if (!context.mounted || succeeded != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          employee == null
              ? l10n.adminEmployeeCreated
              : l10n.adminEmployeeUpdated,
        ),
      ),
    );
  }

  Future<void> _confirmSoftDelete(
    BuildContext context,
    AppUser employee,
  ) async {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final name = employee.localizedName(languageCode);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.adminSoftDeleteConfirmTitle),
          content: Text(l10n.adminSoftDeleteEmployeeMessage(name)),
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
        .read(employeeSoftDeleteControllerProvider.notifier)
        .softDelete(employeeId: employee.id, deletedBy: uid);
    if (!context.mounted || !succeeded) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(l10n.adminSoftDeleteSuccess)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final employeesAsync = ref.watch(allEmployeesProvider);

    ref.listen(employeeSoftDeleteControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || identical(previous?.failure, failure)) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    });

    return AppScaffold(
      title: l10n.adminEmployeesSection,
      floatingActionButton: FloatingActionButton(
        heroTag: 'admin-add-employee',
        tooltip: l10n.adminAddEmployee,
        onPressed: () => _openForm(context),
        child: const Icon(Icons.person_add_alt_1),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: l10n.adminSearchHint,
                border: const OutlineInputBorder(),
              ),
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
                    selected: _activeFilter == entry.$1,
                    onSelected: (_) =>
                        setState(() => _activeFilter = entry.$1),
                  ),
                ],
                const SizedBox(width: 8),
                FilterChip(
                  label: Text(l10n.adminFilterAllBranches),
                  selected: _branchFilter == null,
                  onSelected: (_) => setState(() => _branchFilter = null),
                ),
                for (final branch in Branch.values) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(branchLabel(branch, l10n)),
                    selected: _branchFilter == branch,
                    onSelected: (_) => setState(() => _branchFilter = branch),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: employeesAsync.when(
              loading: () =>
                  Center(child: AppLoadingIndicator(label: l10n.loading)),
              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text(
                    messageForError(error, l10n),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              data: (employees) {
                final filtered = _filtered(employees);
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: l10n.adminEmployeesEmptyTitle,
                    message: l10n.adminEmployeesEmptyMessage,
                    icon: Icons.badge_outlined,
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final employee = filtered[index];
                    final branch = employee.branch;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: Theme.of(context).dividerColor,
                        ),
                      ),
                      title: Text(employee.localizedName(languageCode)),
                      subtitle: Text(
                        '${employee.email}\n'
                        '${employee.phone ?? ''} · '
                        '${branch == null ? '—' : branchLabel(branch, l10n)} · '
                        '${employee.isActive ? l10n.adminFilterActive : l10n.adminFilterInactive}',
                      ),
                      isThreeLine: true,
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) async {
                          switch (value) {
                            case 'edit':
                              await _openForm(context, employee: employee);
                            case 'delete':
                              await _confirmSoftDelete(context, employee);
                            case 'activate':
                              await ref
                                  .read(
                                    employeeActivationControllerProvider
                                        .notifier,
                                  )
                                  .setActive(
                                    employeeId: employee.id,
                                    isActive: true,
                                  );
                          }
                        },
                        itemBuilder: (context) => [
                          PopupMenuItem(
                            value: 'edit',
                            child: Text(l10n.adminEditEmployeeTitle),
                          ),
                          if (!employee.isActive)
                            PopupMenuItem(
                              value: 'activate',
                              child: Text(l10n.adminReactivateAction),
                            ),
                          if (employee.isActive)
                            PopupMenuItem(
                              value: 'delete',
                              child: Text(l10n.adminSoftDeleteAction),
                            ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
