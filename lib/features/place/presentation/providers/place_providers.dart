import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:teletech_drivers/features/auth/presentation/providers/auth_bound_stream.dart';
import 'package:teletech_drivers/features/place/data/providers/place_repository_provider.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/domain/use_cases/add_place.dart';
import 'package:teletech_drivers/features/place/domain/use_cases/delete_place.dart';
import 'package:teletech_drivers/features/place/domain/use_cases/edit_place.dart';
import 'package:teletech_drivers/features/place/domain/use_cases/seed_default_places.dart';
import 'package:teletech_drivers/features/place/domain/use_cases/set_place_active.dart';
import 'package:teletech_drivers/features/place/domain/use_cases/sync_missing_default_places.dart';
import 'package:teletech_drivers/features/place/domain/use_cases/watch_active_places.dart';
import 'package:teletech_drivers/features/place/domain/use_cases/watch_all_places.dart';
import 'package:teletech_drivers/features/place/presentation/utils/localized_place_name.dart';

final watchActivePlacesUseCaseProvider = Provider<WatchActivePlacesUseCase>((
  ref,
) {
  return WatchActivePlacesUseCase(ref.watch(placeRepositoryProvider));
});

final watchAllPlacesUseCaseProvider = Provider<WatchAllPlacesUseCase>((ref) {
  return WatchAllPlacesUseCase(ref.watch(placeRepositoryProvider));
});

final addPlaceUseCaseProvider = Provider<AddPlaceUseCase>((ref) {
  return AddPlaceUseCase(ref.watch(placeRepositoryProvider));
});

final editPlaceUseCaseProvider = Provider<EditPlaceUseCase>((ref) {
  return EditPlaceUseCase(ref.watch(placeRepositoryProvider));
});

final setPlaceActiveUseCaseProvider = Provider<SetPlaceActiveUseCase>((ref) {
  return SetPlaceActiveUseCase(ref.watch(placeRepositoryProvider));
});

final deletePlaceUseCaseProvider = Provider<DeletePlaceUseCase>((ref) {
  return DeletePlaceUseCase(ref.watch(placeRepositoryProvider));
});

final seedDefaultPlacesUseCaseProvider = Provider<SeedDefaultPlacesUseCase>((
  ref,
) {
  return SeedDefaultPlacesUseCase(ref.watch(placeRepositoryProvider));
});

final syncMissingDefaultPlacesUseCaseProvider =
    Provider<SyncMissingDefaultPlacesUseCase>((ref) {
      return SyncMissingDefaultPlacesUseCase(
        ref.watch(placeRepositoryProvider),
      );
    });

/// Observer: active places for employee pickers, sorted by name.
/// Dependency Injection: Riverpod.
final activePlacesProvider = StreamProvider.autoDispose<List<Place>>((ref) {
  return authBoundStream(
    ref,
    whenSignedOut: const <Place>[],
    create: (_) => ref.watch(watchActivePlacesUseCaseProvider)(),
  );
}, retry: (_, _) => null);

/// Observer: all places for company admin, sorted by name.
/// Dependency Injection: Riverpod.
final allPlacesProvider = StreamProvider.autoDispose<List<Place>>((ref) {
  return authBoundStream(
    ref,
    whenSignedOut: const <Place>[],
    create: (_) => ref.watch(watchAllPlacesUseCaseProvider)(),
  );
}, retry: (_, _) => null);

/// Resolves stored place labels to the bilingual names saved on places.
/// Dependency Injection: Riverpod.
final placeNameResolverProvider = Provider.autoDispose<PlaceNameResolver>((
  ref,
) {
  final places = ref.watch(allPlacesProvider).asData?.value ?? const <Place>[];
  return PlaceNameResolver(places);
});
