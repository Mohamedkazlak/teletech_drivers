import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/router/app_routes.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/company_admin/presentation/widgets/my_requests_tab.dart';
import 'package:teletech_drivers/features/trip_request/presentation/navigation/open_new_trip_request.dart';

/// Admin own trip requests with progress (same as company / drivers admin).
class AdminMyTripsScreen extends ConsumerWidget {
  const AdminMyTripsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final user = ref.watch(currentUserProvider).asData?.value;

    return AppScaffold(
      title: l10n.adminMyTripsSection,
      floatingActionButton: user == null
          ? null
          : FloatingActionButton(
              heroTag: 'admin-request-trip',
              tooltip: l10n.requestATrip,
              onPressed: () => openNewTripRequest(context, user: user),
              child: const Icon(Icons.add),
            ),
      body: MyRequestsTab(
        requestDetailsPath: AppRoutes.adminMyRequestDetailsPath,
      ),
    );
  }
}
