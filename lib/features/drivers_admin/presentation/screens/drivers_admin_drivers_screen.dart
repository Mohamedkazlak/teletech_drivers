import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/localization/language_toggle_button.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/auth/presentation/widgets/sign_out_button.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/add_driver_dialog.dart';
import 'package:teletech_drivers/features/drivers_admin/presentation/widgets/drivers_tab.dart';

/// Drivers admin driver directory.
class DriversAdminDriversScreen extends ConsumerWidget {
  const DriversAdminDriversScreen({super.key});

  Future<void> _openAddDriver(BuildContext context) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await AddDriverDialog.show(context);
    if (!context.mounted || succeeded != true) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(l10n.driverCreated)),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.driversTab,
      actions: const [
        LanguageToggleButton(),
        SignOutButton(style: SignOutButtonStyle.icon),
      ],
      floatingActionButton: FloatingActionButton(
        heroTag: 'drivers-admin-add-driver',
        tooltip: l10n.addDriver,
        onPressed: () => _openAddDriver(context),
        child: const Icon(Icons.person_add_outlined),
      ),
      body: const DriversTab(),
    );
  }
}
