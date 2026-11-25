import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/theme/app_colors.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/employee_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/providers/user_account_providers.dart';
import 'package:teletech_drivers/features/admin/presentation/widgets/admin_section_card.dart';
import 'package:teletech_drivers/features/admin/presentation/widgets/trips_week_chart.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/providers/driver_providers.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/trip_request/presentation/navigation/open_new_trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/providers/trip_request_providers.dart';

/// System admin home: section cards with counts (no approval / assignment UI).
class AdminDashboardScreen extends ConsumerWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;
    final driversAsync = ref.watch(allDriverProfilesProvider);
    final placesAsync = ref.watch(allPlacesProvider);
    final employeesAsync = ref.watch(allEmployeesProvider);
    final usersAsync = ref.watch(allUserAccountsProvider);
    final myTripsAsync = ref.watch(employeeTripRequestsProvider);

    final driversCount = driversAsync.asData?.value.length;
    final placesCount = placesAsync.asData?.value.length;
    final employeesCount = employeesAsync.asData?.value.length;
    final usersCount = usersAsync.asData?.value.length;
    final myTripsCount = myTripsAsync.asData?.value.length;

    final loading =
        driversAsync.isLoading ||
        placesAsync.isLoading ||
        employeesAsync.isLoading ||
        usersAsync.isLoading ||
        myTripsAsync.isLoading;

    return AppScaffold(
      title: l10n.adminDashboardTitle,
      actions: const [
        LanguageToggleButton(),
        SignOutButton(style: SignOutButtonStyle.icon),
      ],
      body: loading &&
              driversCount == null &&
              placesCount == null &&
              employeesCount == null &&
              usersCount == null &&
              myTripsCount == null
          ? Center(child: AppLoadingIndicator(label: l10n.loading))
          : ListView(
              padding: GlassBarInset.listPadding(
                context,
                const EdgeInsetsDirectional.all(16),
              ),
              children: [
                Text(
                  l10n.adminDashboardSubtitle,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.inkMuted,
                  ),
                ),
                const SizedBox(height: 16),
                _TileGrid(
                  columns: MediaQuery.sizeOf(context).width >= 700 ? 3 : 2,
                  children: [
                    AdminSectionCard(
                      animateIndex: 0,
                      title: l10n.adminDriversSection,
                      subtitle: l10n.adminDriversSectionHint,
                      icon: Icons.local_taxi_outlined,
                      count: driversCount,
                      onTap: () => context.go(AppRoutes.adminDrivers),
                    ),
                    AdminSectionCard(
                      animateIndex: 1,
                      title: l10n.adminPlacesSection,
                      subtitle: l10n.adminPlacesSectionHint,
                      icon: Icons.place_outlined,
                      count: placesCount,
                      onTap: () => context.go(AppRoutes.adminPlaces),
                    ),
                    AdminSectionCard(
                      animateIndex: 2,
                      title: l10n.adminEmployeesSection,
                      subtitle: l10n.adminEmployeesSectionHint,
                      icon: Icons.badge_outlined,
                      count: employeesCount,
                      onTap: () => context.go(AppRoutes.adminEmployees),
                    ),
                    AdminSectionCard(
                      animateIndex: 3,
                      title: l10n.adminUsersSection,
                      subtitle: l10n.adminUsersSectionHint,
                      icon: Icons.manage_accounts_outlined,
                      count: usersCount,
                      onTap: () => context.go(AppRoutes.adminUsers),
                    ),
                    AdminSectionCard(
                      animateIndex: 4,
                      title: l10n.adminMyTripsSection,
                      subtitle: l10n.adminMyTripsSectionHint,
                      icon: Icons.assignment_outlined,
                      count: myTripsCount,
                      onTap: () => context.go(AppRoutes.adminMyTrips),
                    ),
                    AdminSectionCard(
                      animateIndex: 5,
                      title: l10n.adminRequestTripSection,
                      subtitle: l10n.adminRequestTripSectionHint,
                      icon: Icons.add_road_outlined,
                      emphasized: true,
                      onTap: () {
                        if (user == null) return;
                        openNewTripRequest(context, user: user);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const TripsWeekChart(animateIndex: 6),
              ],
            ),
    );
  }
}

/// Rows of equal-height tiles that grow with their text, so no title or
/// hint is ever cut off (a fixed-ratio grid clips long translations).
class _TileGrid extends StatelessWidget {
  const _TileGrid({required this.columns, required this.children});

  final int columns;
  final List<Widget> children;

  static const double _gap = 12;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var start = 0; start < children.length; start += columns) {
      final end = (start + columns).clamp(0, children.length);
      final rowChildren = children.sublist(start, end);
      rows.add(
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 150),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (var i = 0; i < columns; i++) ...[
                  if (i > 0) const SizedBox(width: _gap),
                  Expanded(
                    child: i < rowChildren.length
                        ? rowChildren[i]
                        : const SizedBox.shrink(),
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          rows[i],
        ],
      ],
    );
  }
}
