import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/state/place_action_state.dart';

/// Dependency Injection: Riverpod.
final placeActivationControllerProvider =
    NotifierProvider.autoDispose<PlaceActivationController, PlaceActionState>(
      PlaceActivationController.new,
    );

class PlaceActivationController extends Notifier<PlaceActionState> {
  @override
  PlaceActionState build() => const PlaceActionState();

  /// Returns true when the active flag was updated successfully.
  Future<bool> setActive({
    required String placeId,
    required bool isActive,
  }) async {
    if (state.isLoading) return false;

    state = PlaceActionState(isLoading: true, activePlaceId: placeId);
    try {
      await ref.read(setPlaceActiveUseCaseProvider)(
        placeId: placeId,
        isActive: isActive,
      );
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
