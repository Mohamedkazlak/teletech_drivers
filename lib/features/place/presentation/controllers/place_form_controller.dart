import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/features/place/presentation/providers/place_providers.dart';
import 'package:teletech_drivers/features/place/presentation/state/place_form_state.dart';

/// Dependency Injection: Riverpod.
final placeFormControllerProvider =
    NotifierProvider.autoDispose<PlaceFormController, PlaceFormState>(
      PlaceFormController.new,
    );

class PlaceFormController extends Notifier<PlaceFormState> {
  @override
  PlaceFormState build() => const PlaceFormState();

  void clearFailure() {
    if (state.failure == null || state.isLoading) return;
    state = const PlaceFormState();
  }

  /// Returns true when the place was created successfully.
  Future<bool> add({
    required String nameEn,
    required String nameAr,
    required String address,
    double? latitude,
    double? longitude,
    bool isHeadquarters = false,
  }) async {
    if (state.isLoading) return false;

    state = const PlaceFormState(isLoading: true);
    try {
      await ref.read(addPlaceUseCaseProvider)(
        nameEn: nameEn,
        nameAr: nameAr,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isHeadquarters: isHeadquarters,
      );
      if (!ref.mounted) return false;
      state = const PlaceFormState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = PlaceFormState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const PlaceFormState(failure: UnknownFailure());
      return false;
    }
  }

  /// Returns true when the place was updated successfully.
  Future<bool> edit({
    required String placeId,
    required String nameEn,
    required String nameAr,
    required String address,
    double? latitude,
    double? longitude,
    bool isHeadquarters = false,
  }) async {
    if (state.isLoading) return false;

    state = const PlaceFormState(isLoading: true);
    try {
      await ref.read(editPlaceUseCaseProvider)(
        placeId: placeId,
        nameEn: nameEn,
        nameAr: nameAr,
        address: address,
        latitude: latitude,
        longitude: longitude,
        isHeadquarters: isHeadquarters,
      );
      if (!ref.mounted) return false;
      state = const PlaceFormState();
      return true;
    } on Failure catch (failure) {
      if (!ref.mounted) return false;
      state = PlaceFormState(failure: failure);
      return false;
    } on Object {
      if (!ref.mounted) return false;
      state = const PlaceFormState(failure: UnknownFailure());
      return false;
    }
  }
}
