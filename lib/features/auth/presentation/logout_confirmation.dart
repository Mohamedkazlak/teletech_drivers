import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/features/auth/domain/entities/user_role.dart';
import 'package:teletech_drivers/features/auth/presentation/controllers/logout_controller.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_providers.dart';
import 'package:teletech_drivers/features/trip/presentation/providers/trip_providers.dart';

/// Confirms sign-out, warns a driver whose trip is still in progress, then
/// signs out.
Future<void> confirmAndSignOut(WidgetRef ref, BuildContext context) async {
  final l10n = AppLocalizations.of(context);
  final user = ref.read(currentUserProvider).asData?.value;
  final activeTrip = user != null &&
      user.role == UserRole.driver &&
      _driverHasActiveTrip(ref, user.id);

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(l10n.logoutConfirmTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.logoutConfirmMessage),
            if (activeTrip) ...[
              const SizedBox(height: 12),
              Text(l10n.logoutActiveTripWarning),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(l10n.logoutConfirmAction),
          ),
        ],
      );
    },
  );
  if (confirmed != true || !context.mounted) return;
  await ref.read(logoutControllerProvider.notifier).signOut();
}

bool _driverHasActiveTrip(WidgetRef ref, String driverId) {
  final trips = ref.read(driverTripsProvider(driverId)).asData?.value;
  if (trips == null) return false;
  return trips.any((trip) => trip.status.isInProgress);
}
