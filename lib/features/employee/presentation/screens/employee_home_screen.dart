import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/presentation/branch_label.dart';
import 'package:teletech_drivers/core/presentation/role_label.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/widgets/home_header.dart';
import 'package:teletech_drivers/features/auth/domain/entities/app_user.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/features/trip_request/presentation/navigation/open_new_trip_request.dart';
import 'package:teletech_drivers/features/trip_request/presentation/widgets/my_trips_panel.dart';

/// Employee home: lists the user's trip requests and opens the create form.
class EmployeeHomeScreen extends ConsumerWidget {
  const EmployeeHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final auth = ref.watch(currentUserProvider);
    final user = auth.asData?.value;

    return AppScaffold(
      title: l10n.navMyTrips,
      actions: const [
        LanguageToggleButton(),
        SignOutButton(style: SignOutButtonStyle.icon),
      ],
      floatingActionButton: user == null
          ? null
          : FloatingActionButton.extended(
              heroTag: 'employee-new-trip-request',
              tooltip: l10n.newTripRequest,
              onPressed: () => openNewTripRequest(context, user: user),
              icon: const Icon(Icons.add_road_rounded),
              label: Text(l10n.newTripRequest),
            ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (user != null) _EmployeeHomeHeader(user: user),
            Expanded(
              child: auth.when(
                loading: () => TripListSkeleton(label: l10n.loading),
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
                data: (loadedUser) {
                  if (loadedUser == null) {
                    return Center(
                      child: Text(
                        l10n.homeEmpty,
                        style: Theme.of(context).textTheme.bodyLarge,
                        textAlign: TextAlign.center,
                      ),
                    );
                  }
                  return MyTripsPanel(
                    detailsPath: AppRoutes.employeeTripRequestPath,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmployeeHomeHeader extends StatelessWidget {
  const _EmployeeHomeHeader({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final chips = <Widget>[
      HomeHeaderChip(
        label: roleLabel(user.role, l10n),
        icon: Icons.badge_outlined,
      ),
      if (user.branch != null)
        HomeHeaderChip(
          label: branchLabel(user.branch!, l10n),
          icon: Icons.place_outlined,
        ),
    ];

    return HomeHeader(
      greeting: l10n.roleHomeWelcome(user.localizedName(languageCode)),
      chips: chips,
    );
  }
}
