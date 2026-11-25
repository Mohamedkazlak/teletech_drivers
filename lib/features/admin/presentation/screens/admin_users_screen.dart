import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/widgets/search_field.dart';
import 'package:teletech_drivers/core/widgets/success_moment.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/surface_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/role_label.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/user_account_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/widgets/reset_password_dialog.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';

/// System admin directory: reset any account to a temporary password.
class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  UserRole? _roleFilter;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AppUser> _filtered(List<AppUser> items) {
    final query = _searchController.text.trim().toLowerCase();
    final languageCode = Localizations.localeOf(context).languageCode;
    return [
      for (final user in items)
        if (_matchesRole(user) && _matchesQuery(user, query, languageCode))
          user,
    ];
  }

  bool _matchesRole(AppUser user) {
    final filter = _roleFilter;
    if (filter == null) return true;
    return user.role == filter;
  }

  bool _matchesQuery(AppUser user, String query, String languageCode) {
    if (query.isEmpty) return true;
    final name = user.localizedName(languageCode).toLowerCase();
    return name.contains(query) ||
        user.email.toLowerCase().contains(query) ||
        (user.phone?.toLowerCase().contains(query) ?? false);
  }

  Future<void> _reset(BuildContext context, AppUser user) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await ResetPasswordDialog.show(context, user: user);
    if (!context.mounted || succeeded != true) return;
    await showSuccessMoment(context, message: l10n.adminResetPasswordSuccess);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final usersAsync = ref.watch(allUserAccountsProvider);
    final currentUserId = ref.watch(currentUserProvider).asData?.value?.id;

    return AppScaffold(
      title: l10n.adminUsersSection,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SearchField(
              controller: _searchController,
              hintText: l10n.adminUsersSearchHint,
              onChanged: (_) => setState(() {}),
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 0),
            child: Row(
              children: [
                FilterChip(
                  label: Text(l10n.adminFilterAllRoles),
                  selected: _roleFilter == null,
                  onSelected: (_) => setState(() => _roleFilter = null),
                ),
                for (final role in UserRole.values) ...[
                  const SizedBox(width: 8),
                  FilterChip(
                    label: Text(roleLabel(role, l10n)),
                    selected: _roleFilter == role,
                    onSelected: (_) => setState(() => _roleFilter = role),
                  ),
                ],
              ],
            ),
          ),
          Expanded(
            child: usersAsync.when(
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
              data: (users) {
                final filtered = _filtered(users);
                if (filtered.isEmpty) {
                  return EmptyState(
                    title: l10n.adminUsersEmptyTitle,
                    message: l10n.adminUsersEmptyMessage,
                    icon: Icons.manage_accounts_outlined,
                  );
                }
                return ListView.separated(
                  padding: GlassBarInset.listPadding(
                    context,
                    const EdgeInsetsDirectional.all(16),
                  ),
                  itemCount: filtered.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final user = filtered[index];
                    final isSelf = user.id == currentUserId;
                    return SurfaceCard(
                      animateIndex: index,
                      child: ListTile(
                      contentPadding: const EdgeInsetsDirectional.fromSTEB(14, 8, 4, 8),
                      leading: InitialsAvatar(
                        name: user.localizedName(languageCode),
                        statusColor: user.isActive ? AppColors.success : AppColors.inkMuted,
                      ),
                      title: Text(user.localizedName(languageCode)),
                      subtitle: Text(
                        '${user.email}\n'
                        '${roleLabel(user.role, l10n)} · '
                        '${user.isActive ? l10n.adminFilterActive : l10n.adminFilterInactive}'
                        '${user.mustChangePassword ? ' · ${l10n.adminTemporaryPasswordBadge}' : ''}',
                      ),
                      isThreeLine: true,
                      trailing: isSelf
                          ? null
                          : PopupMenuButton<String>(
                              tooltip: l10n.adminResetPasswordAction,
                              onSelected: (value) async {
                                if (value == 'reset') {
                                  await _reset(context, user);
                                }
                              },
                              itemBuilder: (context) => [
                                PopupMenuItem(
                                  value: 'reset',
                                  child: Text(l10n.adminResetPasswordAction),
                                ),
                              ],
                            ),
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
