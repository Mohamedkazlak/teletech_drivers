import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/state/place_action_state.dart';

/// Dependency Injection: Riverpod.
final seedPlacesControllerProvider =
    NotifierProvider.autoDispose<SeedPlacesController, PlaceActionState>(
      SeedPlacesController.new,
    );

class SeedPlacesController extends Notifier<PlaceActionState> {
  @override
  PlaceActionState build() => const PlaceActionState();

  /// Returns true when the default places were seeded successfully.
  Future<bool> seed() async {
    if (state.isLoading) return false;

    state = const PlaceActionState(isLoading: true);
    try {
      await ref.read(seedDefaultPlacesUseCaseProvider)();
      if (!ref.mounted) return false;
      state = const PlaceActionState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = PlaceActionState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const PlaceActionState(failure: UnknownFailure());
      return false;
    }
  }
}
