import 'package:flutter/material.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/places_tab.dart';

/// Admin places management (reuses company-admin PlacesTab + map picker).
class AdminPlacesScreen extends StatelessWidget {
  const AdminPlacesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AppScaffold(
      title: l10n.adminPlacesSection,
      body: const PlacesTab(),
    );
  }
}
