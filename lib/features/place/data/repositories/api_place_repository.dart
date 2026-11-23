import 'package:teletech_drivers/core/constants/api_json_keys.dart';
import 'package:teletech_drivers/core/constants/polling_intervals.dart';
import 'package:teletech_drivers/core/errors/failures.dart';
import 'package:teletech_drivers/core/network/api_failure_mapper.dart';
import 'package:teletech_drivers/core/polling/polling_stream.dart';
import 'package:teletech_drivers/features/place/data/datasources/place_remote_data_source.dart';
import 'package:teletech_drivers/features/place/data/default_places.dart';
import 'package:teletech_drivers/features/place/data/mappers/place_dto_mapper.dart';
import 'package:teletech_drivers/features/place/data/models/place_dto.dart';
import 'package:teletech_drivers/features/place/domain/entities/place.dart';
import 'package:teletech_drivers/features/place/domain/repositories/place_repository.dart';

/// Repository: Laravel places API with polling streams.
class ApiPlaceRepository implements PlaceRepository {
  ApiPlaceRepository({
    required this.dataSource,
    this.failureMapper = const ApiFailureMapper(),
  });

  final PlaceRemoteDataSource dataSource;
  final ApiFailureMapper failureMapper;

  final _polling = <PollingStream<List<Place>>>[];

  @override
  Stream<List<Place>> watchActivePlaces() {
    return _watch(() => _loadPlaces(isActive: true));
  }

  @override
  Stream<List<Place>> watchAllPlaces() {
    return _watch(_loadPlaces);
  }

  @override
  Future<void> addPlace({
    required String nameEn,
    required String nameAr,
    required String address,
    double? latitude,
    double? longitude,
    bool isHeadquarters = false,
  }) {
    return _guard(() async {
      _ensureCoordinatePair(latitude: latitude, longitude: longitude);
      await _ensureUniqueNames(nameEn: nameEn, nameAr: nameAr);
      await dataSource.createPlace(
        PlaceDto(
          id: '',
          nameEn: nameEn,
          nameAr: nameAr,
          isActive: true,
          latitude: latitude,
          longitude: longitude,
          address: address,
          isHeadquarters: isHeadquarters,
        ).toCreateBody(),
      );
    });
  }

  @override
  Future<void> editPlace({
    required String placeId,
    required String nameEn,
    required String nameAr,
    required String address,
    double? latitude,
    double? longitude,
    bool isHeadquarters = false,
  }) {
    return _guard(() async {
      _ensureCoordinatePair(latitude: latitude, longitude: longitude);
      final existing = await dataSource.getPlace(placeId);
      await _ensureUniqueNames(
        nameEn: nameEn,
        nameAr: nameAr,
        excludingPlaceId: placeId,
      );
      await dataSource.updatePlace(
        placeId: placeId,
        body: PlaceDto(
          id: placeId,
          nameEn: nameEn,
          nameAr: nameAr,
          isActive: existing.isActive,
          latitude: latitude,
          longitude: longitude,
          address: address,
          isHeadquarters: isHeadquarters,
        ).toUpdateBody(),
      );
    });
  }

  @override
  Future<Place?> findHeadquarters() {
    return _guardValue(() async {
      final places = await dataSource.listPlaces(isActive: true);
      for (final dto in places) {
        if (dto.isHeadquarters) return PlaceDtoMapper.toEntity(dto);
      }
      return null;
    });
  }

  @override
  Future<void> setPlaceActive({
    required String placeId,
    required bool isActive,
  }) {
    return _guard(() async {
      final existing = await dataSource.getPlace(placeId);
      await dataSource.updatePlace(
        placeId: placeId,
        body: {
          ...existing.toUpdateBody(),
          ApiJsonKeys.isActive: isActive,
        },
      );
    });
  }

  @override
  Future<void> deletePlace(String placeId) {
    return _guard(() => dataSource.deletePlace(placeId));
  }

  @override
  Future<void> seedDefaultPlaces() {
    return _guard(() async {
      final existing = await dataSource.listPlaces();
      if (existing.isNotEmpty) {
        throw const InvalidStateFailure();
      }
      for (final place in defaultPlaces) {
        await dataSource.createPlace(
          PlaceDto(
            id: '',
            nameEn: place.nameEn,
            nameAr: place.nameAr,
            address: place.nameAr,
            isActive: true,
          ).toCreateBody(),
        );
      }
    });
  }

  @override
  Future<int> syncMissingDefaultPlaces() {
    return _guardValue(() async {
      final existing = await dataSource.listPlaces();
      final existingEn = {
        for (final place in existing) place.nameEn.toLowerCase(),
      };
      final existingAr = {
        for (final place in existing) place.nameAr.toLowerCase(),
      };

      var created = 0;
      for (final place in defaultPlaces) {
        if (existingEn.contains(place.nameEn.toLowerCase()) ||
            existingAr.contains(place.nameAr.toLowerCase())) {
          continue;
        }
        await dataSource.createPlace(
          PlaceDto(
            id: '',
            nameEn: place.nameEn,
            nameAr: place.nameAr,
            address: place.nameAr,
            isActive: true,
          ).toCreateBody(),
        );
        created += 1;
      }
      return created;
    });
  }

  void dispose() {
    for (final stream in _polling) {
      stream.dispose();
    }
    _polling.clear();
  }

  Stream<List<Place>> _watch(Future<List<Place>> Function() fetch) {
    final polling = PollingStream<List<Place>>(
      fetch: fetch,
      interval: PollingIntervals.places,
    );
    _polling.add(polling);
    return polling.stream.handleError((Object error, StackTrace stackTrace) {
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    });
  }

  Future<List<Place>> _loadPlaces({bool? isActive}) async {
    final dtos = await dataSource.listPlaces(isActive: isActive);
    final places = [
      for (final dto in dtos) PlaceDtoMapper.toEntity(dto),
    ]..sort((a, b) => a.nameEn.toLowerCase().compareTo(b.nameEn.toLowerCase()));
    return places;
  }

  void _ensureCoordinatePair({
    double? latitude,
    double? longitude,
  }) {
    if (latitude == null && longitude == null) return;
    if (latitude == null ||
        longitude == null ||
        !latitude.isFinite ||
        !longitude.isFinite ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const InvalidStateFailure();
    }
  }

  Future<void> _ensureUniqueNames({
    required String nameEn,
    required String nameAr,
    String? excludingPlaceId,
  }) async {
    final places = await dataSource.listPlaces();
    final enKey = nameEn.toLowerCase();
    final arKey = nameAr.toLowerCase();
    for (final place in places) {
      if (excludingPlaceId != null && place.id == excludingPlaceId) continue;
      if (place.nameEn.toLowerCase() == enKey ||
          place.nameAr.toLowerCase() == arKey) {
        throw const ConflictFailure();
      }
    }
  }

  Future<void> _guard(Future<void> Function() action) async {
    try {
      await action();
    } catch (error, stackTrace) {
      if (error is Failure) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    }
  }

  Future<T> _guardValue<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      if (error is Failure) {
        Error.throwWithStackTrace(error, stackTrace);
      }
      Error.throwWithStackTrace(failureMapper.map(error), stackTrace);
    }
  }
}
