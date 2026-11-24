import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/localization/generated/app_localizations.dart';
import 'package:teletech_drivers/core/presentation/glass_bar_inset.dart';
import 'package:teletech_drivers/core/widgets/app_scaffold.dart';
import 'package:teletech_drivers/core/presentation/app_loading_indicator.dart';
import 'package:teletech_drivers/core/utils/failure_messages.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/presentation/controllers/place_activation_controller.dart';
import 'package:teletech_drivers/features/place/presentation/controllers/place_deletion_controller.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_form_dialog.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/place_list_tile.dart';
import 'package:teletech_drivers/features/place/presentation/widgets/places_empty_state.dart';

/// Company admin tab: manage approved places (add, edit, activate, delete).
class PlacesTab extends ConsumerWidget {
  const PlacesTab({super.key});

  Future<void> _openForm(
    BuildContext context, {
    required List<Place> existingPlaces,
    Place? place,
  }) async {
    final l10n = AppLocalizations.of(context);
    final succeeded = await PlaceFormDialog.show(
      context,
      existingPlaces: existingPlaces,
      place: place,
    );
    if (!context.mounted || succeeded != true) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(place == null ? l10n.placeCreated : l10n.placeUpdated),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref, {
    required Place place,
  }) async {
    final l10n = AppLocalizations.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(l10n.deletePlaceConfirmTitle),
          content: Text(
            l10n.deletePlaceConfirmMessage(place.displayName(languageCode)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(l10n.deletePlace),
            ),
          ],
        );
      },
    );
    if (confirmed != true || !context.mounted) return;

    final succeeded = await ref
        .read(placeDeletionControllerProvider.notifier)
        .delete(place.id);
    if (!context.mounted || !succeeded) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.placeDeleted)));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final places = ref.watch(allPlacesProvider);
    final activationState = ref.watch(placeActivationControllerProvider);
    final deletionState = ref.watch(placeDeletionControllerProvider);

    ref.listen(placeActivationControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || identical(previous?.failure, failure)) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(failure.message(l10n))));
    });

    ref.listen(placeDeletionControllerProvider, (previous, next) {
      final failure = next.failure;
      if (failure == null || identical(previous?.failure, failure)) return;
      final text = failure is ValidationFailure &&
              (failure.message ?? '').toLowerCase().contains('headquarters')
          ? l10n.cannotDeleteHeadquartersPlace
          : failure.message(l10n);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
    });

    return places.when(
      loading: () => Center(child: AppLoadingIndicator(label: l10n.loading)),
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
      data: (items) {
        if (items.isEmpty) {
          return PlacesEmptyState(
            onAddPlace: () => _openForm(context, existingPlaces: items),
          );
        }

        return AppScaffold(
          showAppBar: false,
          floatingActionButton: FloatingActionButton(
            heroTag: 'places-tab-add-place',
            tooltip: l10n.addPlace,
            onPressed: deletionState.isLoading
                ? null
                : () => _openForm(context, existingPlaces: items),
            child: const Icon(Icons.add),
          ),
          body: ListView.separated(
            padding: GlassBarInset.listPadding(
              context,
              const EdgeInsetsDirectional.fromSTEB(16, 8, 16, 88),
            ),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final place = items[index];
              final isToggling =
                  activationState.isLoading &&
                  activationState.activePlaceId == place.id;
              final isDeleting =
                  deletionState.isLoading &&
                  deletionState.activePlaceId == place.id;

              return PlaceListTile(
                place: place,
                isToggling: isToggling,
                isDeleting: isDeleting,
                onActiveChanged: (isActive) {
                  ref
                      .read(placeActivationControllerProvider.notifier)
                      .setActive(placeId: place.id, isActive: isActive);
                },
                onEdit: () =>
                    _openForm(context, existingPlaces: items, place: place),
                onDelete: () => _confirmDelete(context, ref, place: place),
              );
            },
          ),
        );
      },
    );
  }
}
