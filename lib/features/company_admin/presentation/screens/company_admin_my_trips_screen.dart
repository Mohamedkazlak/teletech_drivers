import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/widgets/brand_fab.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:teletech_drivers/features/trip_request/presentation/navigation/open_new_trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/my_trips_panel.dart';

/// Company admin's own trip requests (same mine API as employees).
class CompanyAdminMyTripsScreen extends ConsumerWidget {
  const CompanyAdminMyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;

    return AppScaffold(
      title: l10n.navMyTrips,
      actions: const [
        LanguageToggleButton(),
        SignOutButton(style: SignOutButtonStyle.icon),
      ],
      floatingActionButton: user == null
          ? null
          : BrandFab(
 heroTag: 'company-admin-my-trips-new',
 tooltip: l10n.newTripRequest,
 icon: Icons.add,
 onPressed: () => openNewTripRequest(context, user: user),
 ),
      body: MyTripsPanel(
        detailsPath: AppRoutes.companyAdminMyTripRequestPath,
        cancelledTabLabel: l10n.myTripsTabCancelledRejected,
      ),
    );
  }
}
