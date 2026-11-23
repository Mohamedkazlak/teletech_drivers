import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/core/widgets/animated_error_banner.dart';
import 'package:teletech_drivers/core/widgets/app_button.dart';
import 'package:teletech_drivers/core/widgets/empty_state.dart';
import 'package:teletech_drivers/features/place/presentation/controllers/seed_places_controller.dart';

/// Empty state with optional one-time seed action for company admin.
class PlacesEmptyState extends ConsumerWidget {
  const PlacesEmptyState({required this.onAddPlace, super.key});

  final VoidCallback onAddPlace;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final seedState = ref.watch(seedPlacesControllerProvider);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsetsDirectional.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedErrorBanner(
              message: seedState.failure?.message(l10n),
            ),
            if (seedState.failure != null) const SizedBox(height: 16),
            EmptyState(
              icon: Icons.place_outlined,
              title: l10n.placesEmptyTitle,
              message: l10n.placesEmptyMessage,
            ),
            const SizedBox(height: 24),
            AppButton(
              label: l10n.addPlace,
              isLoading: seedState.isLoading,
              loadingLabel: l10n.loading,
              onPressed: seedState.isLoading ? null : onAddPlace,
            ),
            const SizedBox(height: 12),
            AppButton(
              label: l10n.seedDefaultPlaces,
              variant: AppButtonVariant.outlined,
              isLoading: seedState.isLoading,
              loadingLabel: l10n.loading,
              onPressed: seedState.isLoading
                  ? null
                  : () async {
                      final succeeded = await ref
                          .read(seedPlacesControllerProvider.notifier)
                          .seed();
                      if (!context.mounted || !succeeded) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(l10n.placesSeeded)),
                      );
                    },
            ),
          ],
        ),
      ),
    );
  }
}
